## Game
##
## Root controller of "Žiedinė ekonomika" – a small tycoon about a circular
## economy. The player runs the whole value chain for 10 "years". Nothing is a
## hard game over: whatever falls out of the loop goes to the landfill and
## raises pollution – a negative externality that hurts prices, causes
## disasters and makes the planet go grey and finally burn. Each year ends with
## a report, an EU circularity target and a choice of one investment card.
## Extras: difficulty levels, a first-time tutorial, a sorting mini-game,
## sounds and juicy feedback.
extends Node2D

const RING_RADIUS := 200.0
const LAP_TIME := 9.0        # seconds for one full lap at base speed
const TOKEN_RADIUS := 9.0

# Years
const YEAR_LEN := 60.0       # seconds per in-game year
const YEARS := 10

# Pollution (0..100)
const POL_OVERFLOW := 4.0       # item falls out of the loop -> landfill
const POL_RAW := 1.5            # extracting new primary raw material
const POL_DECAY := 0.2          # nature recovers per second
const POL_LOOP_CLEAN := 0.3     # each completed loop reduces pollution
const POL_PRICE_HIT := 0.4      # at 100 % pollution prices drop by 40 %
const CLEANUP_AMOUNT := 12.0

# Money (€)
const LANDFILL_FEE := 3.0       # landfill tax per item (Pigou tax)
const RAW_COST := 6.0           # price of new (primary) raw material
const CLEANUP_COST := 25.0
const FACTORY := 4
const SHOP := 5
const SORTER := 2

# Consumption ramp (over the whole game)
const SPAWN_START_INTERVAL := 2.1
const SPAWN_MIN_INTERVAL := 0.6
const RAMP_TIME := 360.0

# Investor bonus coins
const BONUS_MIN_DELAY := 8.0
const BONUS_MAX_DELAY := 15.0

# Sorting mini-game
const SORT_MIN_DELAY := 35.0
const SORT_MAX_DELAY := 55.0
const SORT_WAIT := 12.0          # seconds the mixed waste waits before it is dumped
const SORT_SLOWMO := 0.25

const DIFFICULTIES := [
	{"title": "Lengvas", "desc": "Mažiau atliekų, daugiau pinigų,\nnelaimės retesnės",
		"spawn": 1.3, "money": 45.0, "pol": 0.7, "disaster": 65.0, "target": -10, "fee": 0.7, "score": 0.8},
	{"title": "Normalus", "desc": "Subalansuotas iššūkis\n(rekomenduojama)",
		"spawn": 1.0, "money": 25.0, "pol": 1.0, "disaster": 55.0, "target": 0, "fee": 1.0, "score": 1.0},
	{"title": "Sunkus", "desc": "Daugiau atliekų, griežtesni ES\ntikslai, brangus sąvartynas",
		"spawn": 0.82, "money": 15.0, "pol": 1.3, "disaster": 45.0, "target": 5, "fee": 1.5, "score": 1.3},
]

# Market events
const EVENT_MIN_DELAY := 25.0
const EVENT_MAX_DELAY := 40.0
const EVENTS := [
	{"id": "black_friday", "title": "Juodasis penktadienis",
		"desc": "Paklausa ×2, kainos +30 %", "time": 18.0},
	{"id": "recession", "title": "Recesija",
		"desc": "Pirkėjų mažiau, kainos -20 %", "time": 20.0},
	{"id": "oil", "title": "Naftos kainų šuolis",
		"desc": "Nauja žaliava ×2 brangesnė, perdirbtų prekių kaina +20 %", "time": 22.0},
	{"id": "eu", "title": "Nauja ES direktyva",
		"desc": "Sąvartyno mokestis ×2", "time": 20.0},
	{"id": "deposit", "title": "Taros užstato akcija",
		"desc": "Surinkimas dirba 60 % greičiau", "time": 20.0},
	{"id": "grant", "title": "ES žaliųjų investicijų fondas",
		"desc": "Gauta subsidija!", "time": 4.0},
]

# Investment cards offered at the end of each year (pick one).
const PERKS := [
	{"id": "solar", "cat": "eco", "title": "Saulės elektrinės", "desc": "Tarša mažėja\n2× greičiau"},
	{"id": "repair", "cat": "fin", "title": "Remonto tinklas", "desc": "+€3 už kiekvieną\nužbaigtą ciklą"},
	{"id": "deposit", "cat": "prod", "title": "Taromatų tinklas", "desc": "Surinkimas\n+40 % greitesnis"},
	{"id": "education", "cat": "prod", "title": "Švietimo kampanija", "desc": "Žmonės rūšiuoja geriau:\nRūšiavimas +40 %"},
	{"id": "bond", "cat": "fin", "title": "Žaliosios obligacijos", "desc": "+€150 iškart"},
	{"id": "automation", "cat": "prod", "title": "Automatizacija", "desc": "Visos stotys\n+15 % greitesnės"},
	{"id": "ecolabel", "cat": "fin", "title": "Eko ženklas", "desc": "Pardavimo kainos\n+15 %"},
	{"id": "logistics", "cat": "prod", "title": "Logistikos centras", "desc": "Visų stočių sandėlis\n+1 vieta"},
	{"id": "cleantech", "cat": "eco", "title": "Valymo technologijos", "desc": "Aplinkos valymas\n40 % pigesnis"},
	{"id": "tax", "cat": "fin", "title": "Mokesčių lengvata", "desc": "Patobulinimai\n20 % pigesni"},
	{"id": "venture", "cat": "fin", "title": "Rizikos kapitalas", "desc": "Investuotojų monetos\ndažnesnės ir ×1.5 vertės"},
	{"id": "firebrigade", "cat": "eco", "title": "Gaisrinė", "desc": "Gaisrai užgęsta\n2× greičiau"},
]

var ring: Ring
var landfill: Landfill
var stations: Array[Station] = []
var tokens: Array[Token] = []
var bonuses: Array[Bonus] = []
var hud: Hud
var sfx: Sfx

var center: Vector2 = Vector2.ZERO
var angular_speed: float = 0.0

var difficulty: int = 1
var diff: Dictionary = DIFFICULTIES[1]

var money: float = 25.0
var total_earned: float = 0.0
var loops: int = 0
var pollution: float = 0.0
var made_recycled: int = 0   # products made from secondary raw material
var made_raw: int = 0        # products made from bought primary raw material
var landfilled: int = 0
var cleanups: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var bonus_timer: float = 0.0
var disaster_timer: float = 0.0
var sort_timer: float = 0.0
var running: bool = false
var paused: bool = false
var in_report: bool = false
var finished: bool = false
var tutorial_active: bool = false
var sorting_active: bool = false
var selected_index: int = -1

# Year state
var year: int = 1
var year_time: float = 0.0
var y_earned: float = 0.0
var y_recycled: int = 0
var y_raw: int = 0
var y_landfill: int = 0
var report_cards: Array = []

# Permanent effects of investment cards
var perks_taken: Array[String] = []
var perk_price: float = 1.0
var perk_decay: float = 1.0
var perk_loop_bonus: float = 0.0
var perk_cleanup: float = 1.0
var perk_bonus: float = 1.0
var perk_fire: float = 1.0

# Event state
var event_timer: float = 0.0
var event: Dictionary = {}
var event_left: float = 0.0
var demand_mult: float = 1.0
var price_mult: float = 1.0
var raw_cost_mult: float = 1.0
var fine_mult: float = 1.0

var _income_log: Array = []
var _shake: float = 0.0
var _tut_bonus: Bonus = null

func _ready() -> void:
	randomize()
	var vp := get_viewport_rect().size
	center = Vector2(vp.x * 0.5, vp.y * 0.5 + 14.0)

	sfx = Sfx.new()
	add_child(sfx)

	_add_background()

	ring = Ring.new()
	ring.center = center
	ring.radius = RING_RADIUS
	add_child(ring)

	landfill = Landfill.new()
	landfill.position = Vector2(center.x + 165.0, vp.y - 34.0)
	add_child(landfill)

	for i in Pipeline.count():
		var st := Station.new()
		st.index = i
		st.position = ring.station_position(i)
		st.processed.connect(_on_station_processed)
		add_child(st)
		stations.append(st)

	angular_speed = TAU / LAP_TIME
	ring.belt_speed = angular_speed

	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	hud.refresh()
	hud.show_start_overlay()
	sfx.start_music()

	get_viewport().size_changed.connect(_relayout)
	if bool(Settings.get_value("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_relayout()
	hud.refresh_fullscreen()

## Keep the ring centred and the HUD glued to the screen edges for any
## window size / aspect ratio.
func _relayout() -> void:
	var vp := get_viewport_rect().size
	center = Vector2(vp.x * 0.5, vp.y * 0.5 + 14.0)
	ring.center = center
	ring.queue_redraw()
	for i in stations.size():
		stations[i].position = ring.station_position(i)
	for t in tokens:
		if is_instance_valid(t) and t.active:
			t.position = ring.position_for_angle(t.angle)
	landfill.position = Vector2(center.x + 165.0, vp.y - 34.0)
	hud.relayout(vp)

func toggle_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	Settings.set_value("fullscreen", not fs)
	Sfx.play("click")
	hud.refresh_fullscreen()

## Full-screen background picture behind everything (art/fonas.png).
func _add_background() -> void:
	if not ResourceLoader.exists("res://art/fonas.png"):
		return
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var bg := TextureRect.new()
	bg.texture = load("res://art/fonas.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

# --- Game flow -------------------------------------------------------------

func start_game(diff_index: int = -1, with_tutorial: bool = false) -> void:
	if diff_index >= 0:
		difficulty = clampi(diff_index, 0, DIFFICULTIES.size() - 1)
	diff = DIFFICULTIES[difficulty]

	for t in tokens:
		if is_instance_valid(t):
			t.queue_free()
	tokens.clear()
	for b in bonuses:
		if is_instance_valid(b):
			b.queue_free()
	bonuses.clear()
	if hud.sorting != null and is_instance_valid(hud.sorting):
		hud.sorting.queue_free()
	if hud.tutorial != null and is_instance_valid(hud.tutorial):
		hud.tutorial.queue_free()

	for st in stations:
		st.clear_buffer()
		st.reset_levels()
		st.selected = false
		st.flash = 0.0
	landfill.reset()

	money = float(diff["money"])
	total_earned = 0.0
	loops = 0
	pollution = 0.0
	made_recycled = 0
	made_raw = 0
	landfilled = 0
	cleanups = 0
	elapsed = 0.0
	spawn_timer = 0.0
	bonus_timer = randf_range(BONUS_MIN_DELAY, BONUS_MAX_DELAY) * 0.5
	disaster_timer = 12.0
	sort_timer = randf_range(25.0, 35.0)
	event_timer = randf_range(EVENT_MIN_DELAY, EVENT_MAX_DELAY)
	year = 1
	_reset_year_stats()
	perks_taken.clear()
	perk_price = 1.0
	perk_decay = 1.0
	perk_loop_bonus = 0.0
	perk_cleanup = 1.0
	perk_bonus = 1.0
	perk_fire = 1.0
	_end_event()
	_income_log.clear()
	selected_index = -1
	finished = false
	in_report = false
	paused = false
	sorting_active = false
	Station.sim_speed = 1.0
	running = true

	hud.hide_overlay()
	hud.hide_report()
	hud.hide_panel()
	hud.refresh()
	sfx.start_music()

	tutorial_active = with_tutorial
	if with_tutorial:
		hud.start_tutorial()

func _reset_year_stats() -> void:
	year_time = 0.0
	y_earned = 0.0
	y_recycled = 0
	y_raw = 0
	y_landfill = 0

## EU circularity target for the current year (%).
func year_target() -> int:
	return clampi(40 + (year - 1) * 5 + int(diff["target"]), 20, 85)

func year_circularity() -> float:
	var total := y_recycled + y_raw + y_landfill
	if total == 0:
		return 100.0
	return 100.0 * float(y_recycled) / float(total)

func _end_year() -> void:
	in_report = true
	paused = true
	var circ := year_circularity()
	var target := year_target()
	var met := circ >= float(target)
	var reward := 40.0 * year if met else -20.0 * year
	money += reward
	if reward > 0.0:
		total_earned += reward
	var summary := {
		"year": year, "earned": y_earned, "circ": circ, "target": target, "met": met,
		"reward": reward, "landfill": y_landfill, "pollution": pollution,
	}
	Sfx.play("year", 0.0)
	if met:
		Juice.confetti(hud, Vector2(center.x, 200.0), 60, 1.4)
	if year >= YEARS:
		_finish_game(summary)
		return
	report_cards = _draw_cards(3)
	hud.show_report(summary, report_cards)

func choose_card(i: int) -> void:
	if not in_report or i < 0 or i >= report_cards.size():
		return
	_apply_perk(report_cards[i])
	year += 1
	_reset_year_stats()
	in_report = false
	paused = false
	hud.hide_report()
	hud.refresh()

func _draw_cards(n: int) -> Array:
	var pool := PERKS.duplicate()
	pool.shuffle()
	return pool.slice(0, n)

func _apply_perk(p: Dictionary) -> void:
	var id := str(p["id"])
	perks_taken.append(str(p["title"]))
	match id:
		"solar":
			perk_decay *= 2.0
		"repair":
			perk_loop_bonus += 3.0
		"deposit":
			stations[1].perk_speed *= 1.4
		"education":
			stations[2].perk_speed *= 1.4
		"bond":
			earn(150.0, center, "obligacijos")
		"automation":
			for st in stations:
				st.perk_speed *= 1.15
		"ecolabel":
			perk_price *= 1.15
		"logistics":
			for st in stations:
				st.cap_bonus += 1
		"cleantech":
			perk_cleanup *= 0.6
		"tax":
			for st in stations:
				st.cost_mult *= 0.8
		"venture":
			perk_bonus *= 1.5
		"firebrigade":
			perk_fire *= 2.0
	for st in stations:
		st.recompute()

func _finish_game(summary: Dictionary) -> void:
	finished = true
	running = false
	in_report = false
	for b in bonuses:
		if is_instance_valid(b):
			b.queue_free()
	bonuses.clear()
	stations[SORTER].sort_alert = 0.0
	hud.hide_report()
	hud.show_final(summary)

## Final score combines money, planet health and circularity (× difficulty).
func final_score() -> int:
	var base := total_earned + (100.0 - pollution) * 15.0 + circularity() * 10.0
	return int(base * float(diff["score"]))

func final_title() -> String:
	var circ := circularity()
	if pollution < 25.0 and circ >= 70.0:
		return "Žiedinės ekonomikos lyderis"
	if pollution < 40.0:
		return "Žalioji įmonė"
	if pollution >= 75.0 and total_earned >= 2000.0:
		return "Godus milijonierius ant degančios planetos"
	if pollution >= 75.0:
		return "Planetos degintojas"
	return "Pusiaukelėje į žiedinę ekonomiką"

# --- Tutorial hooks ---------------------------------------------------------------

func tutorial_finished() -> void:
	tutorial_active = false

func tutorial_spawn_bonus() -> void:
	if _tut_bonus != null and is_instance_valid(_tut_bonus):
		return
	var b := Bonus.new()
	b.amount = 10
	b.life = 999.0
	b.position = center + Vector2(-330.0, -150.0)
	add_child(b)
	bonuses.append(b)
	_tut_bonus = b
	Sfx.play("bonus_spawn")

func tutorial_bonus_pos() -> Vector2:
	if _tut_bonus != null and is_instance_valid(_tut_bonus):
		return _tut_bonus.global_position
	return center + Vector2(-330.0, -150.0)

# --- Money helpers -------------------------------------------------------------

func earn(amount: float, at: Vector2, label: String = "") -> void:
	if amount <= 0.0:
		return
	money += amount
	total_earned += amount
	y_earned += amount
	_income_log.append([elapsed, amount])
	var txt := "+€%s" % _fmt(amount)
	if label != "":
		txt += " " + label
	FloatText.spawn(self, at, txt, Color(0.55, 1.0, 0.6))
	var n := clampi(int(amount / 4.0) + 1, 1, 5)
	Juice.coins(hud, at + position, hud.money_target(), n, hud.bump_money)

func spend(amount: float) -> bool:
	if money < amount:
		Sfx.play("error", 0.0)
		return false
	money -= amount
	return true

func income_per_min() -> float:
	var sum := 0.0
	var keep: Array = []
	for e in _income_log:
		if elapsed - float(e[0]) <= 30.0:
			sum += float(e[1])
			keep.append(e)
	_income_log = keep
	return sum * 2.0

## Overall share (%) of material kept in the loop.
func circularity() -> float:
	var total := made_recycled + made_raw + landfilled
	if total == 0:
		return 100.0
	return 100.0 * float(made_recycled) / float(total)

## Combined price multiplier: market events, cards and pollution.
func effective_price_mult() -> float:
	return price_mult * perk_price * (1.0 - POL_PRICE_HIT * pollution / 100.0)

func raw_price() -> float:
	return RAW_COST * raw_cost_mult

func cleanup_price() -> float:
	return round(CLEANUP_COST * pow(1.25, float(cleanups)) * perk_cleanup)

func pollution_stage() -> String:
	if pollution < 20.0:
		return "Švari planeta"
	if pollution < 45.0:
		return "Planeta pilkėja"
	if pollution < 70.0:
		return "Smogas"
	return "Planeta dega!"

func add_pollution(amount: float) -> void:
	if amount > 0.0:
		amount *= float(diff["pol"])
	pollution = clampf(pollution + amount, 0.0, 100.0)

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

static func _fmt(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return "%.1f" % v

# --- Main loop -------------------------------------------------------------

func _process(real_delta: float) -> void:
	# screen shake
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - real_delta * 3.0)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 9.0
	elif position != Vector2.ZERO:
		position = Vector2.ZERO

	ring.pollution = clampf(pollution / 100.0, 0.0, 1.0)
	var active := running and not paused and not finished
	ring.moving = active
	for st in stations:
		st.set_process(active or not running)
	if not active:
		return
	var delta := real_delta * Station.sim_speed
	elapsed += delta
	if not tutorial_active:
		year_time += delta
	add_pollution(-POL_DECAY * perk_decay * delta)
	_update_spawning(delta)
	if not tutorial_active:
		_update_bonus(delta)
		_update_events(delta)
		_update_disasters(delta)
		_update_sorting(delta)
	_update_fires(delta)
	_move_tokens(delta)
	hud.refresh()
	if year_time >= YEAR_LEN and not sorting_active:
		_end_year()

func _spawn_interval() -> float:
	var t := clampf(elapsed / RAMP_TIME, 0.0, 1.0)
	var iv := lerpf(SPAWN_START_INTERVAL, SPAWN_MIN_INTERVAL, t) * float(diff["spawn"]) / demand_mult
	if tutorial_active:
		iv *= 1.6
	return iv

func _update_spawning(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= _spawn_interval():
		spawn_timer -= _spawn_interval()
		_spawn_token()

func _spawn_token() -> void:
	var t := Token.new()
	t.radius = TOKEN_RADIUS
	t.form = 0
	t.angle = ring.base_angle(0)
	t.target_angle = t.angle + ring.step
	t.next_station = Pipeline.norm(1)
	t.position = ring.position_for_angle(t.angle)
	add_child(t)
	tokens.append(t)

func _move_tokens(delta: float) -> void:
	var arrived: Array[Token] = []
	for t in tokens:
		if not t.active:
			continue
		t.angle += angular_speed * delta
		if t.angle >= t.target_angle:
			t.angle = t.target_angle
			arrived.append(t)

	for t in arrived:
		_handle_arrival(t)

	for t in tokens:
		if t.active:
			t.position = ring.position_for_angle(t.angle)

func _handle_arrival(t: Token) -> void:
	var st := stations[t.next_station]
	if st.receive(t):
		return
	# Overflow: the material falls out of the loop.
	st.flash = 1.0
	st.queue_redraw()
	_to_landfill(t, st.position)
	hud.flash_overflow()

## Item leaves the loop: landfill, pollution and the landfill tax.
func _to_landfill(t: Token, at: Vector2) -> void:
	landfill.add(t.form)
	landfilled += 1
	y_landfill += 1
	add_pollution(POL_OVERFLOW)
	var fee := LANDFILL_FEE * fine_mult * float(diff["fee"])
	money -= fee
	FloatText.spawn(self, at + Vector2(0, -60), "-€%s sąvartynas" % _fmt(fee), Color(1.0, 0.45, 0.4))
	Sfx.play("landfill")
	shake(0.25)
	_remove_token(t)

func _on_station_processed(station: Station, token: Token) -> void:
	token.form = station.index
	token.refresh()

	if station.index == 0:
		# A product has gone all the way around and reached the user again.
		loops += 1
		add_pollution(-POL_LOOP_CLEAN)
		earn(station.value_add() + perk_loop_bonus, station.position + Vector2(0, -60), "užstatas")
		_remove_token(token)
		return

	token.value += station.value_add()
	if station.index == FACTORY:
		if token.raw:
			made_raw += 1
			y_raw += 1
		else:
			made_recycled += 1
			y_recycled += 1
	elif station.index == SHOP:
		var price := token.value * effective_price_mult()
		if not token.raw and event.get("id", "") == "oil":
			price *= 1.2
		earn(price, station.position + Vector2(0, -60))
		Sfx.play("sale")
		token.value = 0.0
		token.raw = false

	token.next_station = Pipeline.norm(station.index + 1)
	token.active = true
	token.visible = true
	token.target_angle = token.angle + ring.step
	token.position = ring.position_for_angle(token.angle)

func _remove_token(t: Token) -> void:
	tokens.erase(t)
	if is_instance_valid(t):
		t.queue_free()

# --- Player actions ----------------------------------------------------------

func _can_act() -> bool:
	return running and not paused and not finished and not sorting_active

## Buy new primary raw material straight into the factory (linear economy).
func buy_raw() -> void:
	if not _can_act():
		return
	var fac := stations[FACTORY]
	var at := fac.position + Vector2(0, -60)
	if fac.buffer.size() >= fac.capacity:
		FloatText.spawn(self, at, "Sandėlis pilnas", Color(1.0, 0.8, 0.4), 15)
		Sfx.play("error", 0.0)
		return
	var price := raw_price()
	if not spend(price):
		FloatText.spawn(self, at, "Trūksta pinigų", Color(1.0, 0.5, 0.4), 15)
		return
	var t := Token.new()
	t.radius = TOKEN_RADIUS
	t.form = 3
	t.raw = true
	t.value = Pipeline.base_value(1) + Pipeline.base_value(2) + Pipeline.base_value(3)
	t.angle = ring.base_angle(FACTORY)
	t.next_station = FACTORY
	t.position = fac.position
	add_child(t)
	tokens.append(t)
	fac.receive(t)
	fac.punch = 1.0
	add_pollution(POL_RAW)
	Sfx.play("work", 0.05, 0.8)
	FloatText.spawn(self, at, "-€%s žaliava" % _fmt(price), Color(1.0, 0.75, 0.45), 15)

## Pay to clean the environment (always more expensive than prevention).
func clean_up() -> void:
	if not _can_act() or pollution <= 0.5:
		return
	var price := cleanup_price()
	if not spend(price):
		FloatText.spawn(self, center, "Trūksta pinigų", Color(1.0, 0.5, 0.4), 15)
		return
	cleanups += 1
	add_pollution(-CLEANUP_AMOUNT)
	Sfx.play("extinguish", 0.0)
	Juice.confetti(self, center, 24, 0.8)
	FloatText.spawn(self, center + Vector2(0, -20), "Aplinka išvalyta! -%d taršos" % int(CLEANUP_AMOUNT),
		Color(0.6, 0.95, 1.0), 17)

func upgrade_selected(kind: String) -> void:
	if selected_index < 0 or selected_index >= stations.size() or finished or sorting_active:
		return
	var st := stations[selected_index]
	if st.is_maxed(kind):
		return
	var cost := float(st.cost_of(kind))
	if not spend(cost):
		return
	st.upgrade(kind)
	Sfx.play("upgrade", 0.0)
	Sfx.play("confetti", 0.0)
	Juice.confetti(self, st.position, 30)
	FloatText.spawn(self, st.position + Vector2(0, -62), Pipeline.upgrade_name(st.index, kind) + "!",
		Pipeline.color_of(st.index).lightened(0.3), 16)
	hud.refresh()
	hud.tutorial_notify("upgrade")

func select_station(idx: int) -> void:
	selected_index = idx
	for i in stations.size():
		stations[i].selected = (i == idx)
		stations[i].queue_redraw()
	if idx >= 0:
		hud.show_panel(stations[idx])
	else:
		hud.hide_panel()

# --- Investor bonus coins ------------------------------------------------------

func _update_bonus(delta: float) -> void:
	bonuses = bonuses.filter(func(b): return is_instance_valid(b))
	bonus_timer -= delta * (1.4 if perk_bonus > 1.0 else 1.0)
	if bonus_timer > 0.0:
		return
	bonus_timer = randf_range(BONUS_MIN_DELAY, BONUS_MAX_DELAY)
	var b := Bonus.new()
	b.amount = int(round((8.0 + elapsed * 0.08) * perk_bonus))
	var a := randf() * TAU
	var r := randf_range(RING_RADIUS + 70.0, RING_RADIUS + 140.0)
	var p := center + Vector2(cos(a), sin(a)) * r
	var vp := get_viewport_rect().size
	p.x = clampf(p.x, 380.0, vp.x - 360.0)
	p.y = clampf(p.y, 90.0, vp.y - 90.0)
	b.position = p
	add_child(b)
	bonuses.append(b)
	Sfx.play("bonus_spawn")

func _try_collect_bonus(pos: Vector2) -> bool:
	for b in bonuses:
		if is_instance_valid(b) and b.hit(pos):
			earn(float(b.amount), b.position + Vector2(0, -30), "investicija")
			Sfx.play("bonus_get", 0.0)
			Juice.confetti(self, b.position, 14, 0.6)
			bonuses.erase(b)
			b.queue_free()
			hud.tutorial_notify("bonus")
			return true
	return false

# --- Disasters (pollution externality) ----------------------------------------

func _update_disasters(delta: float) -> void:
	if pollution < float(diff["disaster"]):
		disaster_timer = maxf(disaster_timer, 8.0)
		return
	disaster_timer -= delta * (0.5 + pollution / 100.0)
	if disaster_timer > 0.0:
		return
	disaster_timer = randf_range(14.0, 24.0)
	var st := stations[randi() % stations.size()]
	if randf() < 0.6:
		st.fire = 9.0
		hud.show_alert("GAISRAS: %s!" % Pipeline.name_of(st.index), "Spaudyk stotį, kad užgesintum")
		Sfx.play("fire", 0.0)
		shake(0.8)
	else:
		var lost := st.buffer.size()
		for t in st.buffer.duplicate():
			st.buffer.erase(t)
			_to_landfill(t, st.position)
		st.flash = 1.0
		hud.show_alert("POTVYNIS: %s" % Pipeline.name_of(st.index), "Išplauta daiktų: %d" % lost)
		Sfx.play("flood", 0.0)
		shake(0.9)

func _update_fires(delta: float) -> void:
	if perk_fire <= 1.0:
		return
	for st in stations:
		if st.fire > 0.0:
			st.fire = maxf(0.0, st.fire - delta * (perk_fire - 1.0))

# --- Sorting mini-game ------------------------------------------------------------

func _update_sorting(delta: float) -> void:
	var sorter := stations[SORTER]
	if sorter.sort_alert > 0.0:
		sorter.sort_alert -= delta
		if sorter.sort_alert <= 0.0:
			# Nobody sorted the mixed batch – it is dumped.
			sorter.sort_alert = 0.0
			for i in 3:
				sorting_mistake(2)
			FloatText.spawn(self, sorter.position + Vector2(0, -60), "Mišrios atliekos išmestos!", Color(1.0, 0.5, 0.4), 15)
			Sfx.play("sort_bad", 0.0)
		return
	sort_timer -= delta
	if sort_timer <= 0.0:
		sort_timer = randf_range(SORT_MIN_DELAY, SORT_MAX_DELAY)
		sorter.sort_alert = SORT_WAIT
		hud.show_alert("MIŠRIOS ATLIEKOS!", "Spausk Rūšiavimo stotį ir išrūšiuok jas")
		Sfx.play("event", 0.0)

func _open_sorting() -> void:
	stations[SORTER].sort_alert = 0.0
	sorting_active = true
	Station.sim_speed = SORT_SLOWMO
	var count := clampi(5 + year / 2, 5, 9)
	var s := hud.open_sorting(count)
	s.finished.connect(_on_sorting_done)

func _on_sorting_done(correct: int, total: int, reward: float) -> void:
	sorting_active = false
	Station.sim_speed = 1.0
	add_pollution(-0.6 * float(correct))
	if reward > 0.0:
		earn(reward, stations[SORTER].position + Vector2(0, -60), "rūšiavimas")

## A sorting mistake (or an unsorted item): it goes to the landfill.
func sorting_mistake(_item: int) -> void:
	landfill.add(2)
	landfilled += 1
	y_landfill += 1
	add_pollution(POL_OVERFLOW * 0.5)
	Sfx.play("landfill")

# --- Market events ------------------------------------------------------------

func _update_events(delta: float) -> void:
	if not event.is_empty():
		event_left -= delta
		hud.show_event(event, clampf(event_left / float(event["time"]), 0.0, 1.0))
		if event_left <= 0.0:
			_end_event()
		return
	event_timer -= delta
	if event_timer <= 0.0:
		_start_event(EVENTS[randi() % EVENTS.size()])

func _start_event(e: Dictionary) -> void:
	event = e
	event_left = float(e["time"])
	match str(e["id"]):
		"black_friday":
			demand_mult = 2.0
			price_mult = 1.3
		"recession":
			demand_mult = 0.6
			price_mult = 0.8
		"oil":
			raw_cost_mult = 2.0
		"eu":
			fine_mult = 2.0
		"deposit":
			stations[1].speed_mult = 1.6
			stations[1].recompute()
		"grant":
			earn(30.0 + elapsed * 0.1, center + Vector2(0, -20), "subsidija")
	hud.show_event(event, 1.0)
	Sfx.play("event", 0.0)

func _end_event() -> void:
	event = {}
	demand_mult = 1.0
	price_mult = 1.0
	raw_cost_mult = 1.0
	fine_mult = 1.0
	for st in stations:
		if st.speed_mult != 1.0:
			st.speed_mult = 1.0
			st.recompute()
	event_timer = randf_range(EVENT_MIN_DELAY, EVENT_MAX_DELAY)
	if hud != null:
		hud.hide_event()

# --- Input -----------------------------------------------------------------

func _unhandled_input(event_in: InputEvent) -> void:
	if sorting_active:
		return
	if event_in is InputEventKey and event_in.pressed and not event_in.echo:
		match event_in.keycode:
			KEY_ESCAPE:
				if running and not finished and not in_report:
					paused = not paused
					hud.set_paused(paused)
			KEY_R:
				if running:
					start_game()
			KEY_SPACE:
				buy_raw()
			KEY_V:
				clean_up()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				if _can_act():
					var idx: int = event_in.keycode - KEY_1
					select_station(idx)
					_work(idx)
		return

	if event_in is InputEventMouseButton and event_in.pressed \
			and event_in.button_index == MOUSE_BUTTON_LEFT and _can_act():
		var pos: Vector2 = event_in.position
		if _try_collect_bonus(pos):
			return
		var idx := _station_at(pos - position)
		select_station(idx)
		if idx >= 0:
			_work(idx)

## Manual work on a station (click / number key).
func _work(idx: int) -> void:
	if not _can_act():
		return
	var st := stations[idx]
	if idx == SORTER and st.sort_alert > 0.0:
		_open_sorting()
		return
	var burning := st.fire > 0.0
	if not st.manual_process():
		FloatText.spawn(self, st.position + Vector2(0, -58), "tuščia", Color(0.7, 0.75, 0.85), 13)
		Sfx.play("click", 0.05, 0.8)
	elif burning:
		if st.fire <= 0.0:
			FloatText.spawn(self, st.position + Vector2(0, -60), "Užgesinta!", Color(0.6, 0.9, 1.0), 16)
			Sfx.play("extinguish", 0.0)
		else:
			Sfx.play("work", 0.1, 1.4)
	else:
		Sfx.play("work", 0.1)
	hud.tutorial_notify("work")

func _station_at(pos: Vector2) -> int:
	for i in stations.size():
		if pos.distance_to(stations[i].position) <= stations[i].base_radius + 10.0:
			return i
	return -1
