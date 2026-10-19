## Bonus
##
## An "investor" coin that pops up near the ring for a few seconds. Clicking it
## gives money. Missed coins simply disappear.
class_name Bonus
extends Node2D

const ICONS := "res://art/ikonos.png"   # coin is the first of 3 icons
const LIFE := 5.0

var life: float = LIFE

static var _icons: Texture2D

var amount: int = 10
var _t: float = 0.0

func _ready() -> void:
	z_index = 5
	if _icons == null and ResourceLoader.exists(ICONS):
		_icons = load(ICONS)

func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
	queue_redraw()

func hit(p: Vector2) -> bool:
	return p.distance_to(global_position) <= 26.0

func _draw() -> void:
	var appear := clampf(_t * 5.0, 0.0, 1.0)
	var fade := clampf((life - _t) / 0.8, 0.0, 1.0)
	var a := appear * fade
	# Blink faster when about to vanish
	if _t > life - 1.5 and int(_t * 8.0) % 2 == 0:
		a *= 0.5
	var bob := sin(_t * 4.0) * 3.0
	var k := appear * (1.0 + 0.08 * sin(_t * 9.0))
	draw_circle(Vector2(0, bob), 26.0 * k, Color(1.0, 0.85, 0.3, 0.18 * a))
	draw_circle(Vector2(0, bob), 20.0 * k, Color(1.0, 0.85, 0.3, 0.22 * a))
	if _icons != null:
		var fw := float(_icons.get_width()) / 3.0
		var sz := 34.0 * k
		draw_texture_rect_region(_icons, Rect2(Vector2(-sz * 0.5, bob - sz * 0.5), Vector2(sz, sz)),
			Rect2(0, 0, fw, float(_icons.get_height())), Color(1, 1, 1, a))
	else:
		draw_circle(Vector2(0, bob), 15.0 * k, Color(1.0, 0.8, 0.2, a))
	var font := ThemeDB.fallback_font
	var txt := "+€%d" % amount
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	draw_string_outline(font, Vector2(-w * 0.5, bob + 34.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, 4,
		Color(0, 0, 0, 0.7 * a))
	draw_string(font, Vector2(-w * 0.5, bob + 34.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13,
		Color(1.0, 0.9, 0.5, a))
