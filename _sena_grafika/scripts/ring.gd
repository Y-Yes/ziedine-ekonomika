## Ring
##
## Draws the circular conveyor belt (with chevrons moving in the direction of
## flow, tinted by the stage they lead to), the planet in the middle (it turns
## grey as ecology drops) and provides the angle <-> position math shared by the
## game controller, the stations and the tokens.
class_name Ring
extends Node2D

const PLANET_OK := "res://art/planeta.png"
const PLANET_BAD := "res://art/planeta_tarsa.png"
const PLANET_FIRE := "res://art/planeta_dega.png"
const PLANET_FRAMES := 24
const PLANET_FPS := 6.0

var center: Vector2 = Vector2.ZERO
var radius: float = 200.0
var step: float = TAU / float(Pipeline.count())

## Belt speed in radians / second (set by the game to match token speed).
var belt_speed: float = TAU / 9.0
## Pollution 0 = clean planet, 0.5 = grey & smoggy, 1 = burning (set by the game).
var pollution: float = 0.0
## Belt moves only while the game is running.
var moving: bool = false

var _belt_offset: float = 0.0
var _planet_anim: float = 0.0
var _planet_ok: Texture2D
var _planet_bad: Texture2D
var _planet_fire: Texture2D
var _time: float = 0.0

func _ready() -> void:
	z_index = -1
	if ResourceLoader.exists(PLANET_OK):
		_planet_ok = load(PLANET_OK)
	if ResourceLoader.exists(PLANET_BAD):
		_planet_bad = load(PLANET_BAD)
	if ResourceLoader.exists(PLANET_FIRE):
		_planet_fire = load(PLANET_FIRE)

func _process(delta: float) -> void:
	if moving:
		_belt_offset = fmod(_belt_offset + belt_speed * delta * Station.sim_speed, TAU)
	_time += delta
	_planet_anim = fmod(_planet_anim + delta * PLANET_FPS, float(PLANET_FRAMES))
	queue_redraw()

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
	_draw_planet()
	_draw_belt()

func _draw_planet() -> void:
	if _planet_ok == null:
		return
	var sz := radius * 1.3
	var rect := Rect2(center - Vector2(sz, sz) * 0.5, Vector2(sz, sz))
	var frame := int(_planet_anim) % PLANET_FRAMES
	var fw := float(_planet_ok.get_width()) / float(PLANET_FRAMES)
	var src := Rect2(fw * frame, 0.0, fw, float(_planet_ok.get_height()))
	draw_texture_rect_region(_planet_ok, rect, src)
	if _planet_bad != null and pollution > 0.0:
		draw_texture_rect_region(_planet_bad, rect, src, Color(1, 1, 1, clampf(pollution / 0.5, 0.0, 1.0)))
	if _planet_fire != null and pollution > 0.5:
		draw_texture_rect_region(_planet_fire, rect, src, Color(1, 1, 1, clampf((pollution - 0.5) / 0.4, 0.0, 1.0)))
	# Smog clouds drifting up from the planet when polluted
	if pollution > 0.3:
		var a := clampf((pollution - 0.3) / 0.5, 0.0, 1.0)
		var pr := sz * 0.38
		for k in 10:
			var ph := fmod(_time * 0.12 + float(k) * 0.1, 1.0)
			var ang := -PI * 0.5 + (float(k) - 4.5) * 0.28 + sin(_time * 0.5 + k) * 0.05
			var p := center + Vector2(cos(ang), sin(ang)) * (pr * 0.7 + ph * pr * 0.7)
			var cr := 10.0 + ph * 22.0
			var col := Color(0.35, 0.32, 0.3, a * 0.45 * (1.0 - ph))
			if pollution > 0.75:
				col = col.lerp(Color(0.25, 0.18, 0.15, col.a), 0.6)
			draw_circle(p, cr, col)

func _draw_belt() -> void:
	# Belt body with two rails
	draw_arc(center, radius, 0.0, TAU, 180, Color(0.12, 0.14, 0.19, 1.0), 22.0, true)
	draw_arc(center, radius - 11.0, 0.0, TAU, 180, Color(0.32, 0.38, 0.5, 1.0), 2.5, true)
	draw_arc(center, radius + 11.0, 0.0, TAU, 180, Color(0.32, 0.38, 0.5, 1.0), 2.5, true)

	# Chevrons moving clockwise, tinted toward the next station's color.
	var n := 60
	for k in n:
		var a := TAU * float(k) / float(n) + _belt_offset
		var rel := fposmod(a - base_angle(0), TAU) / step
		var i := int(rel)
		var f := rel - float(i)
		var col := Pipeline.color_of(i).lerp(Pipeline.color_of(i + 1), f)
		col.a = 0.55
		var dir := Vector2(-sin(a), cos(a))      # tangent (clockwise)
		var nrm := Vector2(cos(a), sin(a))       # outward normal
		var p := center + nrm * radius
		var tip := p + dir * 3.5
		draw_polyline(PackedVector2Array([
			p - dir * 3.0 + nrm * 6.0, tip, p - dir * 3.0 - nrm * 6.0,
		]), col, 2.5, true)
