## Ring
##
## Draws the circular conveyor and provides the angle <-> position math shared by
## the game controller, the stations and the tokens.
class_name Ring
extends Node2D

var center: Vector2 = Vector2.ZERO
var radius: float = 200.0
var step: float = TAU / float(Pipeline.count())

func _ready() -> void:
	z_index = -1

## Base angle (radians) of station `i`. Station 0 sits at the top and the ring
## runs clockwise across the screen (screen-space Y points down).
func base_angle(i: int) -> float:
	return -PI * 0.5 + float(i) * step

## Screen position for an arbitrary (continuous) angle.
func position_for_angle(a: float) -> Vector2:
	return center + Vector2(cos(a), sin(a)) * radius

## Screen position of station `i`.
func station_position(i: int) -> Vector2:
	return position_for_angle(base_angle(i))

func _draw() -> void:
	# Outer rail
	draw_arc(center, radius, 0.0, TAU, 160, Color(0.16, 0.19, 0.25, 1.0), 12.0, true)
	# Inner highlight
	draw_arc(center, radius, 0.0, TAU, 160, Color(0.30, 0.36, 0.46, 1.0), 4.0, true)
	# Dashed direction ticks to hint the flow direction
	var n := 72
	for k in n:
		var a := TAU * float(k) / float(n)
		var p0 := center + Vector2(cos(a), sin(a)) * (radius - 9.0)
		var p1 := center + Vector2(cos(a), sin(a)) * (radius - 3.0)
		draw_line(p0, p1, Color(0.45, 0.55, 0.7, 0.55), 2.0, true)
