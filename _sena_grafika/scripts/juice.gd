## Juice
##
## Small visual effects that make actions feel good:
##  * Juice.coins()    – coins fly from a point into the money counter
##  * Juice.confetti() – a burst of confetti
class_name Juice
extends Node2D

const ICONS := "res://art/ikonos.png"
const COLORS := [Color("ffd84a"), Color("5ac26e"), Color("4a90e0"), Color("e0575a"), Color("9a6ae0"), Color("e0913a")]

static var _icons: Texture2D
static var _active_coins: int = 0

enum Kind { COIN, CONFETTI }

var kind: int = Kind.COIN
var on_arrive: Callable

# coin
var _from: Vector2
var _to: Vector2
var _ctrl: Vector2
var _t: float = 0.0
var _dur: float = 0.6
var _delay: float = 0.0

# confetti
var _parts: Array = []

## Coins flying from `from` to `to` (both in screen coordinates).
static func coins(parent: Node, from: Vector2, to: Vector2, count: int, arrive: Callable) -> void:
	for i in count:
		if _active_coins > 30:
			return
		var j := Juice.new()
		j.kind = Kind.COIN
		j._from = from + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		j._to = to
		j._ctrl = (j._from + to) * 0.5 + Vector2(randf_range(-120, 120), randf_range(-160, -40))
		j._delay = i * 0.07
		j._dur = randf_range(0.55, 0.75)
		j.on_arrive = arrive
		j.z_index = 50
		parent.add_child(j)
		_active_coins += 1

static func confetti(parent: Node, at: Vector2, amount: int = 28, spread: float = 1.0) -> void:
	var j := Juice.new()
	j.kind = Kind.CONFETTI
	j.position = at
	j.z_index = 40
	for i in amount:
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		var sp := randf_range(160.0, 360.0) * spread
		j._parts.append({
			"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a)) * sp,
			"r": randf() * TAU, "w": randf_range(-10.0, 10.0),
			"c": COLORS[randi() % COLORS.size()], "s": randf_range(4.0, 8.0),
		})
	parent.add_child(j)

func _ready() -> void:
	if _icons == null and ResourceLoader.exists(ICONS):
		_icons = load(ICONS)

func _process(delta: float) -> void:
	if kind == Kind.COIN:
		if _delay > 0.0:
			_delay -= delta
			visible = false
			return
		visible = true
		_t += delta / _dur
		if _t >= 1.0:
			_active_coins -= 1
			if on_arrive.is_valid():
				on_arrive.call()
			queue_free()
			return
		var u := _t * _t
		position = _from.lerp(_ctrl, u).lerp(_ctrl.lerp(_to, u), u)
	else:
		_t += delta
		for p in _parts:
			p["v"] = p["v"] * (1.0 - 1.8 * delta) + Vector2(0, 520.0) * delta
			p["p"] = p["p"] + p["v"] * delta
			p["r"] = p["r"] + p["w"] * delta
		if _t > 1.5:
			queue_free()
	queue_redraw()

func _draw() -> void:
	if kind == Kind.COIN:
		var k := 1.0 - 0.35 * _t
		if _icons != null:
			var fw := float(_icons.get_width()) / 3.0
			var sz := 22.0 * k
			draw_texture_rect_region(_icons, Rect2(Vector2(-sz, -sz) * 0.5, Vector2(sz, sz)),
				Rect2(0, 0, fw, float(_icons.get_height())))
		else:
			draw_circle(Vector2.ZERO, 8.0 * k, Color("ffd84a"))
	else:
		var a := clampf((1.5 - _t) / 0.5, 0.0, 1.0)
		for p in _parts:
			var s: float = p["s"]
			draw_set_transform(p["p"], p["r"], Vector2(1.0, 0.5 + 0.5 * absf(sin(p["r"] * 2.0))))
			draw_rect(Rect2(-s * 0.5, -s * 0.5, s, s * 0.6), Color(p["c"], a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
