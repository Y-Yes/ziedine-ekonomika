## Web-only transport for Leaderboard.
##
## Godot's HTTPRequest gets its body from the browser already decompressed, but
## the response still carries `Content-Encoding: gzip` (the server exposes that
## header through CORS), so Godot gunzips it a second time and fails with
## RESULT_BODY_DECOMPRESS_FAILED – the request itself was a 200 with a perfectly
## good body. Small answers (no gzip) worked, the real board did not.
##
## Doing the request in JavaScript with `fetch()` sidesteps the whole thing: the
## browser hands us plain text, no decompression anywhere in Godot.
##
## This file is only loaded when OS.has_feature("web") is true, so native builds
## never parse it and never need the JavaScriptBridge singleton.
extends RefCounted

## `window.__lbResult<N>` is "" while request N is still running, then a JSON
## string {"code": <http status, 0 = transport error>, "body": <response text>}.
const JS_PREFIX := "window.__lbResult"

## Requests may overlap (a score being sent while the board is opened), so every
## round trip gets its own global slot.
static var _seq := 0

static func request(method: int, query: String, body: String, prefer: String) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return _fail()
	_seq += 1
	var slot := JS_PREFIX + str(_seq)
	_eval(slot + " = '';")
	_eval(_script(method, query, body, prefer, slot))
	var deadline := Time.get_ticks_msec() + int(NetConfig.TIMEOUT * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
		var raw := str(_eval(slot + " || ''"))
		if raw != "":
			_eval("delete " + slot + ";")
			var answer: Variant = JSON.parse_string(raw)
			if answer is Dictionary:
				var code := int(answer.get("code", 0))
				return {
					"ok": code >= 200 and code < 300,
					"code": code,
					"msg": str(answer.get("body", "")),
					"kind": "" if code > 0 else "offline",
					"rows": [],
				}
			return _fail()
	return _fail()

## Looks the bridge up at run time on purpose: naming JavaScriptBridge directly
## would stop this file from parsing at all in a non-web editor build.
static var _bridge: Object = null

static func _eval(code: String) -> Variant:
	if _bridge == null:
		_bridge = Engine.get_singleton("JavaScriptBridge")
	if _bridge == null:
		return null
	return _bridge.call("eval", code, true)

static func _fail() -> Dictionary:
	return {"ok": false, "code": 0, "msg": "", "kind": "offline", "rows": []}

## Builds the browser-side request. Every value goes in through JSON.stringify,
## which produces a valid JavaScript literal, so the nickname in `body` cannot
## break out of the string.
static func _script(method: int, query: String, body: String, prefer: String, slot: String) -> String:
	var verb := "GET" if method == HTTPClient.METHOD_GET else "POST"
	var headers := "{\"apikey\": %s, \"Content-Type\": \"application/json\"" % JSON.stringify(NetConfig.KEY)
	if prefer != "":
		headers += ", \"Prefer\": %s" % JSON.stringify(prefer)
	headers += "}"
	var js := "(function(){var opt={method:%s,headers:%s};" % [JSON.stringify(verb), headers]
	if body != "":
		js += "opt.body=%s;" % JSON.stringify(body)
	js += "fetch(%s,opt).then(function(r){return r.text().then(function(t){" % JSON.stringify(NetConfig.endpoint() + query)
	js += slot + "=JSON.stringify({code:r.status,body:t});});})"
	js += ".catch(function(e){" + slot + "=JSON.stringify({code:0,body:String(e)});});})();"
	return js
