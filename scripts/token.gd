## Token
##
## A material token that circulates the ring. Its `form` is the index of the
## station it most recently passed, which also determines its color and icon
## (used bottle -> trash bag -> sorted bale -> pellets -> new product -> price
## tag). While it sits inside a station buffer it is `active = false` and hidden
## (the station draws it as a buffer dot instead).
class_name Token
extends Node2D

const ICONS_PATH := "res://art/zetonai.png"   # 6 square icons side by side
const ICON_COUNT := 6

static var _icons: Texture2D

var form: int = 0
var next_station: int = 1
var angle: float = 0.0
var target_angle: float = 0.0
var active: bool = true
var radius: float = 9.0
var value: float = 0.0     # € of value accumulated along the value chain
var raw: bool = false      # made from newly bought (primary) raw material

var _pop: float = 1.0   # 1 = just changed form, eases back to 0

func _ready() -> void:
	z_index = 0
	if _icons == null and ResourceLoader.exists(ICONS_PATH):
		_icons = load(ICONS_PATH)

func _process(delta: float) -> void:
	if _pop > 0.0:
		_pop = maxf(0.0, _pop - delta * 4.0)
		queue_redraw()

func _draw() -> void:
	var c := Pipeline.color_of(form)
	# Little "pop" when the token changes form.
	var k := 1.0 + 0.35 * _pop
	if _icons != null:
		var fw := float(_icons.get_width()) / float(ICON_COUNT)
		var sz := radius * 3.2 * k
		draw_circle(Vector2(0, radius * 0.5), radius * 1.1 * k, Color(0, 0, 0, 0.18))
		draw_texture_rect_region(_icons,
			Rect2(Vector2(-sz * 0.5, -sz * 0.5), Vector2(sz, sz)),
			Rect2(fw * Pipeline.norm(form), 0.0, fw, float(_icons.get_height())))
	else:
		draw_circle(Vector2.ZERO, radius * k, c)
		draw_arc(Vector2.ZERO, radius - 1.5, 0.0, TAU, 20, c.darkened(0.35), 2.0, true)
		draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.28, Color(1, 1, 1, 0.55))

## Update the visual (call after changing `form`).
func refresh() -> void:
	_pop = 1.0
	queue_redraw()
