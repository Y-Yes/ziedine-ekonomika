## Game
##
## Root controller of "Žiedinė ekonomika". It builds the ring, the six
## life-cycle stations and the HUD, spawns consumption, moves tokens around the
## loop and handles scoring, pollution and upgrades.
extends Node2D

const RING_RADIUS := 200.0
const LAP_TIME := 9.0        # seconds for one full lap at base speed
const TOKEN_RADIUS := 9.0

const ECO_START := 100.0
const OVERFLOW_PENALTY := 8.0
const LOOP_REWARD := 0.5
const SPACE_REWARD := 1

const SPAWN_START_INTERVAL := 2.6
const SPAWN_MIN_INTERVAL := 0.7
const RAMP_TIME := 150.0     # seconds to reach the minimum interval

var ring: Ring
var stations: Array[Station] = []
var tokens: Array[Token] = []
var hud: Hud

var center: Vector2 = Vector2.ZERO
var angular_speed: float = 0.0

var score: int = 0
var loops: int = 0
var eco: float = ECO_START
var eco_points: int = 0
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var running: bool = false
var paused: bool = false
var game_over: bool = false
var selected_index: int = -1

func _ready() -> void:
	randomize()
	var vp := get_viewport_rect().size
	center = Vector2(vp.x * 0.5, vp.y * 0.5 + 14.0)

	ring = Ring.new()
	ring.center = center
	ring.radius = RING_RADIUS
	add_child(ring)

	for i in Pipeline.count():
		var st := Station.new()
		st.index = i
		st.position = ring.station_position(i)
		st.processed.connect(_on_station_processed)
		add_child(st)
		stations.append(st)

	angular_speed = TAU / LAP_TIME

	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	hud.refresh()
	hud.show_start_overlay()

# --- Game flow -------------------------------------------------------------

func start_game() -> void:
	for t in tokens:
		if is_instance_valid(t):
			t.queue_free()
	tokens.clear()

	for st in stations:
		st.clear_buffer()
		st.speed_level = 1
		st.cap_level = 1
		st.recompute()
		st.selected = false
		st.flash = 0.0

	score = 0
	loops = 0
	eco = ECO_START
	eco_points = 0
	elapsed = 0.0
	spawn_timer = 0.0
	selected_index = -1
	game_over = false
	paused = false
	running = true

	hud.hide_overlay()
	hud.hide_panel()
	hud.refresh()

func _check_game_over() -> void:
	if eco <= 0.0:
		eco = 0.0
		running = false
		game_over = true
		hud.show_game_over()

# --- Main loop -------------------------------------------------------------

func _process(delta: float) -> void:
	if not running or paused or game_over:
		return
	elapsed += delta
	_update_spawning(delta)
	_move_tokens(delta)
	hud.refresh()

func _spawn_interval() -> float:
	var t := clampf(elapsed / RAMP_TIME, 0.0, 1.0)
	return lerpf(SPAWN_START_INTERVAL, SPAWN_MIN_INTERVAL, t)

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
	# Overflow: the material escapes the loop and becomes pollution.
	_remove_token(t)
	st.flash = 1.0
	st.queue_redraw()
	eco -= OVERFLOW_PENALTY
	hud.flash_overflow()
	_check_game_over()

func _on_station_processed(station: Station, token: Token) -> void:
	token.form = station.index
	eco_points += SPACE_REWARD
	token.refresh()

	if station.index == 0:
		# A product has gone all the way around and reached the user again.
		loops += 1
		score += 10
		eco = minf(ECO_START, eco + LOOP_REWARD)
		_remove_token(token)
	else:
		token.next_station = Pipeline.norm(station.index + 1)
		token.active = true
		token.visible = true
		token.target_angle = token.angle + ring.step
		token.position = ring.position_for_angle(token.angle)

func _remove_token(t: Token) -> void:
	tokens.erase(t)
	if is_instance_valid(t):
		t.queue_free()

# --- Upgrades --------------------------------------------------------------

func upgrade_selected(kind: String) -> void:
	if selected_index < 0 or selected_index >= stations.size():
		return
	var st := stations[selected_index]
	var cost := st.speed_cost() if kind == "speed" else st.capacity_cost()
	if eco_points < cost:
		return
	eco_points -= cost
	if kind == "speed":
		st.speed_level += 1
	else:
		st.cap_level += 1
	st.recompute()
	hud.refresh()

func select_station(idx: int) -> void:
	selected_index = idx
	for i in stations.size():
		stations[i].selected = (i == idx)
		stations[i].queue_redraw()
	if idx >= 0:
		hud.show_panel(stations[idx])
	else:
		hud.hide_panel()

# --- Input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if running and not game_over:
					paused = not paused
					hud.set_paused(paused)
			KEY_R:
				start_game()
			KEY_1:
				select_station(0)
			KEY_2:
				select_station(1)
			KEY_3:
				select_station(2)
			KEY_4:
				select_station(3)
			KEY_5:
				select_station(4)
			KEY_6:
				select_station(5)
		return

	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and running and not game_over:
		select_station(_station_at(event.position))

func _station_at(pos: Vector2) -> int:
	for i in stations.size():
		if pos.distance_to(stations[i].position) <= stations[i].base_radius + 10.0:
			return i
	return -1
