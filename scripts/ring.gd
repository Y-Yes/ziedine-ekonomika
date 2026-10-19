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
const PLANET_FRAMES := 48
const PLANET_COLS := 12   # frames are packed in a grid (12 per row)
const PLANET_FPS := 6.0
# Real-time Earth (used when the shader is present; sprite sheets are the fallback)
const EARTH_DIR := "res://art/zeme/"
const EARTH_SPIN := 0.22        # radians per second
const EARTH_TILT := 0.32

var center: Vector2 = Vector2.ZERO
var radius: float = 200.0
var step: float = TAU / float(Pipeline.count())

## Belt speed in radians / second (set by the game to match token speed).
var belt_speed: float = TAU / 9.0
## Pollution 0 = clean planet, 0.5 = grey & smoggy, 1 = burning (set by the game).
var pollution: float = 0.0
## Belt moves only while the game is running.
var moving: bool = false
## Set when the planet has exploded (lost game).
var planet_hidden: bool = false

var _belt_offset: float = 0.0
var _planet_anim: float = 0.0
var _planet_ok: Texture2D
var _planet_bad: Texture2D
var _planet_fire: Texture2D
var _time: float = 0.0
var _pview: PlanetView
var _pmat: ShaderMaterial
var earth_rot: float = 0.0
var _cloud_rot: float = 0.0
var _earth_tex := {}

func _ready() -> void:
	z_index = -1
	if ResourceLoader.exists(PLANET_OK):
		_planet_ok = load(PLANET_OK)
	if ResourceLoader.exists(PLANET_BAD):
		_planet_bad = load(PLANET_BAD)
	if ResourceLoader.exists(PLANET_FIRE):
		_planet_fire = load(PLANET_FIRE)
	_setup_earth()

func _setup_earth() -> void:
	if not ResourceLoader.exists(EARTH_DIR + "planeta.gdshader"):
		return
	_pmat = ShaderMaterial.new()
	_pmat.shader = load(EARTH_DIR + "planeta.gdshader")
	var maps := {"tex_ok": "zeme.jpg", "tex_bad": "zeme_tarsa.jpg", "tex_fire": "zeme_dega.jpg",
		"tex_lava": "zeme_lava.jpg", "tex_water": "zeme_vanduo.jpg", "tex_clouds": "debesys.jpg",
		"tex_night": "zeme_naktis.jpg"}
	for k in maps:
		var path: String = EARTH_DIR + maps[k]
		if ResourceLoader.exists(path):
			var t: Texture2D = load(path)
			_earth_tex[k] = t
			_pmat.set_shader_parameter(k, t)
	_pmat.set_shader_parameter("tilt", EARTH_TILT)
	_pview = PlanetView.new()
	_pview.material = _pmat
	add_child(_pview)

func _process(delta: float) -> void:
	if moving:
		_belt_offset = fmod(_belt_offset + belt_speed * delta * Station.sim_speed, TAU)
	_time += delta
	_planet_anim = fmod(_planet_anim + delta * PLANET_FPS, float(PLANET_FRAMES))
	if _pview != null:
		earth_rot = fmod(earth_rot + delta * EARTH_SPIN, TAU)
		_cloud_rot = fmod(_cloud_rot + delta * 0.03, TAU)
		_pview.position = center
		_pview.size = radius * PLANET_SIZE_K
		_pview.visible = not planet_hidden
		_pmat.set_shader_parameter("rot", earth_rot)
		_pmat.set_shader_parameter("cloud_rot", _cloud_rot)
		_pmat.set_shader_parameter("pollution", pollution)
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

const PLANET_SIZE_K := 1.22

## [texture, source rect, on-screen size] of the planet as it looks right now.
func planet_frame_info() -> Array:
	if _pview != null:
		var key := "tex_ok"
		if pollution > 0.6:
			key = "tex_fire"
		elif pollution > 0.25:
			key = "tex_bad"
		return [_earth_tex.get(key), Rect2(), radius * PLANET_SIZE_K, true, earth_rot, EARTH_TILT]
	var tex := _planet_ok
	if pollution > 0.6 and _planet_fire != null:
		tex = _planet_fire
	elif pollution > 0.25 and _planet_bad != null:
		tex = _planet_bad
	if tex == null:
		return [null, Rect2(), radius * PLANET_SIZE_K]
	var frame := int(_planet_anim) % PLANET_FRAMES
	var rows := int(ceil(float(PLANET_FRAMES) / float(PLANET_COLS)))
	var fw := float(tex.get_width()) / float(PLANET_COLS)
	var fh := float(tex.get_height()) / float(rows)
	return [tex, Rect2(fw * float(frame % PLANET_COLS), fh * float(frame / PLANET_COLS), fw, fh), radius * PLANET_SIZE_K, false, 0.0, 0.0]

func _draw_planet() -> void:
	if planet_hidden or (_planet_ok == null and _pview == null):
		return
	var sz := radius * PLANET_SIZE_K
	if _pview != null:
		_draw_smog(sz)
		return
	var rect := Rect2(center - Vector2(sz, sz) * 0.5, Vector2(sz, sz))
	var frame := int(_planet_anim) % PLANET_FRAMES
	var rows := int(ceil(float(PLANET_FRAMES) / float(PLANET_COLS)))
	var fw := float(_planet_ok.get_width()) / float(PLANET_COLS)
	var fh := float(_planet_ok.get_height()) / float(rows)
	var src := Rect2(fw * float(frame % PLANET_COLS), fh * float(frame / PLANET_COLS), fw, fh)
	draw_texture_rect_region(_planet_ok, rect, src)
	if _planet_bad != null and pollution > 0.0:
		draw_texture_rect_region(_planet_bad, rect, src, Color(1, 1, 1, clampf(pollution / 0.5, 0.0, 1.0)))
	if _planet_fire != null and pollution > 0.5:
		draw_texture_rect_region(_planet_fire, rect, src, Color(1, 1, 1, clampf((pollution - 0.5) / 0.4, 0.0, 1.0)))
	_draw_smog(sz)

func _draw_smog(sz: float) -> void:
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
	# Glowing energy ring (soft halo + bright core line)
	var glow := Color(0.35, 0.8, 1.0)
	draw_arc(center, radius, 0.0, TAU, 200, Color(glow, 0.06), 30.0, true)
	draw_arc(center, radius, 0.0, TAU, 200, Color(glow, 0.12), 14.0, true)
	draw_arc(center, radius, 0.0, TAU, 200, Color(glow, 0.35), 5.0, true)
	draw_arc(center, radius, 0.0, TAU, 200, Color(0.85, 0.97, 1.0, 0.85), 1.6, true)
	# faint dotted inner orbit, slowly turning the other way
	var dots := 90
	var r2 := radius * 0.8
	for k in dots:
		var a := TAU * float(k) / float(dots) - _belt_offset * 0.35
		draw_circle(center + Vector2(cos(a), sin(a)) * r2, 1.1, Color(glow, 0.3))
	# Flowing chevrons along the ring (clockwise)
	var n := 48
	for k in n:
		var a := TAU * float(k) / float(n) + _belt_offset
		var dir := Vector2(-sin(a), cos(a))
		var nrm := Vector2(cos(a), sin(a))
		var p := center + nrm * radius
		var pulse := 0.35 + 0.35 * (0.5 + 0.5 * sin(a * 3.0 - _time * 2.0))
		draw_polyline(PackedVector2Array([p - dir * 3.0 + nrm * 5.0, p + dir * 2.5, p - dir * 3.0 - nrm * 5.0]),
			Color(0.75, 0.93, 1.0, pulse), 1.8, true)
	# Big arrow heads half way between stations
	for i in Pipeline.count():
		var a := base_angle(i) + step * 0.5
		var dir := Vector2(-sin(a), cos(a))
		var nrm := Vector2(cos(a), sin(a))
		var p := center + nrm * radius
		var col := Pipeline.color_of(i + 1).lerp(Color.WHITE, 0.35)
		draw_colored_polygon(PackedVector2Array([p + dir * 9.0, p - dir * 5.0 + nrm * 8.0, p - dir * 2.0, p - dir * 5.0 - nrm * 8.0]),
			Color(col, 0.9))
