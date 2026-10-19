## PlanetView
##
## Draws the real-time Earth (art/zeme/planeta.gdshader) on a square quad.
class_name PlanetView
extends Node2D

var size: float = 240.0
var _quad: ImageTexture

func _ready() -> void:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_quad = ImageTexture.create_from_image(img)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_texture_rect(_quad, Rect2(-Vector2(size, size) * 0.5, Vector2(size, size)), false)
