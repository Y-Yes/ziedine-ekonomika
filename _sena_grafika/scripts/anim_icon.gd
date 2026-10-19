## AnimIcon
##
## Small looping sprite-sheet animation for UI (investment cards).
class_name AnimIcon
extends Control

var sheet: Texture2D
var frames: int = 16
var fps: float = 10.0
var _t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_sheet(path: String) -> void:
	sheet = load(path) if ResourceLoader.exists(path) else null
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()

func _draw() -> void:
	if sheet == null:
		return
	var fw := float(sheet.get_width()) / float(frames)
	var f := int(_t * fps) % frames
	draw_texture_rect_region(sheet, Rect2(Vector2.ZERO, size), Rect2(fw * f, 0, fw, float(sheet.get_height())))
