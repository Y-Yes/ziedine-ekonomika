## Landfill
##
## Visible pile of everything that fell out of the loop (overflows, floods).
## Each item adds a greyed-out icon to the mound; a big pile attracts flies.
class_name Landfill
extends Node2D

const ICONS := "res://art/zetonai.png"
const MAX_SHOWN := 70

var count: int = 0
var _items: Array = []   # [Vector2 offset, form, rotation]
var _icons: Texture2D
var _t: float = 0.0
var _bump: float = 0.0

func _ready() -> void:
	z_index = 0
	if ResourceLoader.exists(ICONS):
		_icons = load(ICONS)

func add(form: int) -> void:
	count += 1
	_bump = 1.0
	if _items.size() >= MAX_SHOWN:
		return
	# Fill the mound row by row from the bottom: wider rows at the bottom.
	var n := _items.size()
	var row := 0
	var start := 0
	var width := 9
	while n >= start + width:
		start += width
		row += 1
		width = maxi(2, 9 - row * 2 + (row % 2))
	var col := n - start
	var x := (float(col) - float(width - 1) * 0.5) * 12.0 + randf_range(-3.0, 3.0)
	var y := -float(row) * 9.0 + randf_range(-2.0, 2.0)
	_items.append([Vector2(x, y), form, randf_range(-0.6, 0.6)])

func reset() -> void:
	count = 0
	_items.clear()

func _process(delta: float) -> void:
	_t += delta
	_bump = maxf(0.0, _bump - delta * 3.0)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Ground
	draw_colored_polygon(PackedVector2Array([
		Vector2(-70, 6), Vector2(-60, -2), Vector2(60, -2), Vector2(70, 6)]), Color(0.2, 0.17, 0.14, 0.9))
	if count > 0:
		var h := 10.0 + minf(float(count), float(MAX_SHOWN)) * 0.9
		draw_colored_polygon(PackedVector2Array([
			Vector2(-62, 2), Vector2(-20, -h * 0.85), Vector2(0, -h), Vector2(20, -h * 0.85), Vector2(62, 2)]),
			Color(0.27, 0.23, 0.19, 1.0))
	if _icons != null:
		var fw := float(_icons.get_width()) / 6.0
		for it in _items:
			var off: Vector2 = it[0]
			var form: int = it[1]
			var rot: float = it[2]
			draw_set_transform(off + Vector2(0, -4), rot, Vector2.ONE)
			draw_texture_rect_region(_icons, Rect2(-8, -8, 16, 16),
				Rect2(fw * form, 0, fw, float(_icons.get_height())), Color(0.62, 0.58, 0.55, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Flies when the pile is big
	if count >= 8:
		var flies := mini(8, count / 6)
		var top := -minf(float(count), float(MAX_SHOWN)) * 0.9 - 18.0
		for k in flies:
			var a := _t * (3.0 + k * 0.4) + float(k) * 1.3
			var p := Vector2(cos(a) * (14.0 + k * 3.0), top + sin(a * 1.7) * 8.0)
			draw_circle(p, 1.6, Color(0.05, 0.05, 0.05, 0.9))
	var txt := "Sąvartynas: %d" % count
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	var k2 := 1.0 + 0.15 * _bump
	draw_string(font, Vector2(-w * 0.5 * k2, 22.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(13 * k2),
		Color(0.85, 0.7, 0.55) if count > 0 else Color(0.55, 0.6, 0.68))
