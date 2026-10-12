## Token
##
## A material token that circulates the ring. Its `form` is the index of the
## station it most recently passed, which also determines its color. While it
## sits inside a station buffer it is `active = false` and hidden (the station
## draws it as a buffer dot instead).
class_name Token
extends Node2D

var form: int = 0
var next_station: int = 1
var angle: float = 0.0
var target_angle: float = 0.0
var active: bool = true
var radius: float = 9.0

func _ready() -> void:
	z_index = 0

func _draw() -> void:
	var c := Pipeline.color_of(form)
	draw_circle(Vector2.ZERO, radius, c)
	draw_arc(Vector2.ZERO, radius - 1.5, 0.0, TAU, 20, c.darkened(0.35), 2.0, true)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.28, Color(1, 1, 1, 0.55))

## Update the visual color (call after changing `form`).
func refresh() -> void:
	queue_redraw()
