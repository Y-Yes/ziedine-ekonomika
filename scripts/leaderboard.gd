## Leaderboard
##
## Thin client for the online `leaderboard` table (see NetConfig).
##
## Every call returns a Dictionary and never throws, so a missing or slow
## network can only make the leaderboard quieter – it can never block the game:
##   {"ok": bool, "code": int, "msg": String, "kind": String, "rows": Array}
##
## `kind` is "" on success, otherwise:
##   "offline" – the request could not be made at all (no network / timeout)
##   "name"    – the database rejected the nickname (400 + CHECK violation)
##   "error"   – anything else
##
## The nickname rules are NOT implemented here on purpose: Postgres is the only
## authority on what a valid name is, so the list of forbidden words never has
## to appear in the source code that ships to players.
class_name Leaderboard
extends RefCounted

const MAX_ROWS := 10
const COLUMNS := "name,score,circularity,pollution,difficulty,years"

## Sends one finished game.
static func submit(row: Dictionary) -> Dictionary:
	if not NetConfig.ENABLED:
		return _fail("offline", Loc.t("Lentelė išjungta."))
	var res: Dictionary = await _request(HTTPClient.METHOD_POST, "", JSON.stringify(row), "return=minimal")
	if bool(res["ok"]):
		res["msg"] = Loc.t("Rezultatas išsiųstas.")
		return res
	# A violated CHECK constraint comes back as 400 plus
	# {"code":"23514","message":"…violates check constraint…"}. That is the
	# database refusing the nickname – tell the player to pick another one.
	if int(res["code"]) == 400 and str(res["msg"]).contains("23514"):
		return _fail("name", Loc.t("Toks vardas netinka – įrašyk kitą."), 400)
	if str(res["kind"]) == "offline":
		return _fail("offline", Loc.t("Nepavyko išsiųsti rezultato."))
	return _fail("error", Loc.t("Nepavyko išsiųsti rezultato."), int(res["code"]))

## Best scores first. Teaching-mode games are filtered out by the query itself,
## so a class demonstration never ends up on the public board.
static func top(limit: int = MAX_ROWS) -> Dictionary:
	if not NetConfig.ENABLED:
		return _fail("offline", Loc.t("Lentelė išjungta."))
	var query := "?select=%s&learning=eq.false&order=score.desc,created_at.asc&limit=%d" % [COLUMNS, limit]
	var res: Dictionary = await _request(HTTPClient.METHOD_GET, query, "")
	if not bool(res["ok"]):
		return _fail("error", Loc.t("Lentelės įkelti nepavyko."))
	res["rows"] = _parse_rows(str(res["msg"]))
	res["msg"] = ""
	return res

# --- Internals -----------------------------------------------------------------

static func _fail(kind: String, msg: String, code: int = 0) -> Dictionary:
	return {"ok": false, "code": code, "msg": msg, "kind": kind, "rows": []}

## Opens the TLS connection while the player is still on the start screen, so
## the final screen does not have to pay for it. The answer is thrown away.
static var _warmed := false
## Cached web-only transport (scripts/leaderboard_web.gd), loaded on first use.
static var _web_transport = null

static func warm_up() -> void:
	if _warmed or not NetConfig.ENABLED:
		return
	_warmed = true
	await _request(HTTPClient.METHOD_GET, "?select=name&limit=1", "")

static func _parse_rows(raw: String) -> Array:
	var data: Variant = JSON.parse_string(raw)
	return data if data is Array else []

## One HTTP round trip, retried once when the connection itself failed. The
## first request a browser makes to the server pays DNS + TCP + TLS + a CORS
## preflight, and that is exactly the one that used to time out; by the time the
## second attempt runs, all of it is cached, so the retry usually succeeds.
static func _request(method: int, query: String, body: String, prefer: String = "") -> Dictionary:
	var res: Dictionary = await _request_once(method, query, body, prefer)
	if str(res["kind"]) == "offline":
		res = await _request_once(method, query, body, prefer)
	return res

## A single round trip. The HTTPRequest node is created on demand and freed
## again, so nothing has to be wired into the scene tree by hand.
static func _request_once(method: int, query: String, body: String, prefer: String = "") -> Dictionary:
	if OS.has_feature("web"):
		# The browser decompresses the body for us but Godot decompresses it a
		# second time and fails, so the web talks to the server through `fetch()`.
		if _web_transport == null:
			_web_transport = load("res://scripts/leaderboard_web.gd")
		return await _web_transport.request(method, query, body, prefer)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return _fail("offline", "")
	var req := HTTPRequest.new()
	req.timeout = NetConfig.TIMEOUT
	req.use_threads = false          # threads are not available in web exports
	# A call made from `_ready()` arrives while the scene tree is still being
	# built, and then a plain add_child() is refused ("parent node is busy
	# setting up children") – defer it and give it a frame instead.
	tree.root.add_child.call_deferred(req)
	await tree.process_frame
	if not req.is_inside_tree():
		await tree.process_frame
	if not req.is_inside_tree():
		req.queue_free()
		return _fail("offline", "")
	var headers := PackedStringArray([
		"apikey: " + NetConfig.KEY,
		"Content-Type: application/json",
	])
	if prefer != "":
		headers.append("Prefer: " + prefer)
	var err := req.request(NetConfig.endpoint() + query, headers, method, body)
	if err != OK:
		req.queue_free()
		return _fail("offline", "")
	var answer: Array = await req.request_completed
	req.queue_free()
	# answer = [result, response_code, headers, body]
	if int(answer[0]) != HTTPRequest.RESULT_SUCCESS:
		return _fail("offline", "")
	var code := int(answer[1])
	var raw := (answer[3] as PackedByteArray).get_string_from_utf8()
	return {"ok": code >= 200 and code < 300, "code": code, "msg": raw, "kind": "", "rows": []}
