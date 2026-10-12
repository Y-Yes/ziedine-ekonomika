## FloatText
##
## Short pop-up text ("+€9", "-€3 bauda") that rises and fades out.
class_name FloatText
extends Node2D

var text: String = ""
var color: Color = Color.WHITE
var size: int = 18
var life: float = 1.3

var _t: float = 0.0

static func spawn(parent: Node, pos: Vector2, txt: String, col: Color, font_size: int = 18) -> void:
	var f := FloatText.new()
	f.text = txt
	f.color = col
	f.size = font_size
	f.position = pos
	f.z_index = 10
	parent.add_child(f)

func _process(delta: float) -> void:
	_t += delta
	position.y -= (46.0 - _t * 20.0) * delta
	if _t >= life:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var a := clampf((life - _t) / 0.4, 0.0, 1.0)
	var k := 1.0 + 0.25 * maxf(0.0, 1.0 - _t * 6.0)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size * k)).x
	var p := Vector2(-w * 0.5, 0.0)
	draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size * k), 5,
		Color(0.03, 0.04, 0.07, 0.85 * a))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(size * k), Color(color, a))
