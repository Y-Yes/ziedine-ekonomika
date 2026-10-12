## Station
##
## One processing stage on the ring. Tokens that arrive are queued in `buffer`
## and consumed at `process_rate` (tokens per second). When a token finishes
## processing the `processed` signal is emitted so the game controller can push
## the token to the next stage (or complete the loop). If a token arrives while
## the buffer is full the game treats it as an overflow (pollution).
class_name Station
extends Node2D

signal processed(station, token)

const BASE_RATE := 0.55   # tokens / second at level 1
const BASE_CAP := 3       # buffer slots at level 1
const CAP_STEP := 2       # extra slots per capacity level

var index: int = 0
var speed_level: int = 1
var cap_level: int = 1
var process_rate: float = BASE_RATE
var capacity: int = BASE_CAP
var base_radius: float = 40.0

var buffer: Array[Token] = []
var selected: bool = false
var flash: float = 0.0

var _timer: float = 0.0

func _ready() -> void:
	z_index = 1
	recompute()
	set_process(true)

## Recalculate derived stats from the current upgrade levels.
func recompute() -> void:
	process_rate = BASE_RATE * float(speed_level)
	capacity = BASE_CAP + (cap_level - 1) * CAP_STEP
	queue_redraw()

func speed_cost() -> int:
	return 3 + (speed_level - 1) * 3

func capacity_cost() -> int:
	return 2 + (cap_level - 1) * 2

## Try to absorb an arriving token. Returns false when the buffer is full.
func receive(token: Token) -> bool:
	if buffer.size() >= capacity:
		return false
	buffer.append(token)
	token.active = false
	token.visible = false
	queue_redraw()
	return true

func clear_buffer() -> void:
	for t in buffer:
		if is_instance_valid(t):
			t.queue_free()
	buffer.clear()
	_timer = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.0)
		queue_redraw()

	if buffer.is_empty():
		_timer = 0.0
		return

	var interval := 1.0 / maxf(process_rate, 0.001)
	_timer += delta
	while _timer >= interval and not buffer.is_empty():
		_timer -= interval
		_release_one()

func _release_one() -> void:
	var token: Token = buffer.pop_front()
	queue_redraw()
	processed.emit(self, token)

func _draw() -> void:
	var accent := Pipeline.color_of(index)

	# Body
	draw_circle(Vector2.ZERO, base_radius, Color(0.11, 0.13, 0.18, 1.0))
	draw_arc(Vector2.ZERO, base_radius, 0.0, TAU, 48, accent, 4.0, true)

	# Selection highlight
	if selected:
		draw_arc(Vector2.ZERO, base_radius + 7.0, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 3.0, true)

	# Overflow flash
	if flash > 0.0:
		draw_arc(Vector2.ZERO, base_radius + 3.0, 0.0, TAU, 48, Color(1.0, 0.25, 0.25, flash), 7.0, true)

	# Buffer dots, distributed around a small inner circle.
	var n := buffer.size()
	for i in n:
		var a := -PI * 0.5 + TAU * (float(i) / float(maxi(1, capacity)))
		var p := Vector2(cos(a), sin(a)) * (base_radius * 0.5)
		draw_circle(p, 5.0, Pipeline.color_of(buffer[i].form))

	var font := ThemeDB.fallback_font

	# Buffer count above the station
	var slot_text := "%d/%d" % [n, capacity]
	draw_string(font, Vector2(-base_radius, -base_radius - 8.0), slot_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.85, 0.9, 0.96, 0.9))

	# Name below the station
	draw_string(font, Vector2(-base_radius, base_radius + 20.0), Pipeline.name_of(index),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, accent.lightened(0.15))
