## Explosion
##
## Planet explosion played when the game is lost: white flash, fireball,
## shock wave, the planet breaking into textured shards, sparks and smoke.
class_name Explosion
extends Node2D

const DURATION := 3.2

var planet_tex: Texture2D       # sheet the shards are cut from
var planet_src: Rect2           # current frame in that sheet (pixels)
var planet_size: float = 260.0  # on-screen size of the frame rect
var disk_frac: float = 0.4      # planet radius / frame size
var equirect: bool = false      # planet_tex is a 2:1 world map (real-time Earth)
var earth_rot: float = 0.0
var earth_tilt: float = 0.0

var _t: float = 0.0
var _shards: Array = []   # {pts, uvs, pos, vel, rot, spin}
var _sparks: Array = []   # {pos, vel, life, col}
var _smoke: Array = []    # {pos, vel, r, life}

func _ready() -> void:
	z_index = 50
	randomize()
	_build_shards()
	for i in 140:
		var a := randf() * TAU
		var sp := randf_range(150.0, 720.0)
		_sparks.append({"pos": Vector2.ZERO, "vel": Vector2(cos(a), sin(a)) * sp,
			"life": randf_range(0.6, 1.8), "col": [Color(1.0, 0.95, 0.6), Color(1.0, 0.6, 0.2), Color(1.0, 0.35, 0.1)][i % 3]})
	for i in 40:
		var a2 := randf() * TAU
		_smoke.append({"pos": Vector2(cos(a2), sin(a2)) * randf_range(20.0, 70.0),
			"vel": Vector2(cos(a2), sin(a2)) * randf_range(25.0, 110.0),
			"r": randf_range(10.0, 24.0), "life": randf_range(1.8, 3.2)})

func _build_shards() -> void:
	var R := planet_size * disk_frac
	var rings := [0.0, 0.42, 0.75, 1.0]
	var counts := [5, 9, 13]
	for ri in 3:
		var n: int = counts[ri]
		var off := randf() * TAU
		for k in n:
			var a0 := off + TAU * float(k) / float(n)
			var a1 := off + TAU * float(k + 1) / float(n)
			var r0: float = rings[ri] * R
			var r1: float = rings[ri + 1] * R
			var pts := PackedVector2Array()
			var steps := 4
			for s in steps + 1:
				var a := lerpf(a0, a1, float(s) / float(steps))
				var rr := r1 * (1.0 if ri == 2 else randf_range(0.92, 1.06))
				pts.append(Vector2(cos(a), sin(a)) * rr)
			for s in range(steps, -1, -1):
				var a := lerpf(a0, a1, float(s) / float(steps))
				var rr := r0 * randf_range(0.9, 1.08)
				if r0 < 1.0:
					pts.append(Vector2.ZERO)
					break
				pts.append(Vector2(cos(a), sin(a)) * rr)
			var c := Vector2.ZERO
			for p in pts:
				c += p
			c /= float(pts.size())
			var local := PackedVector2Array()
			var uvs := PackedVector2Array()
			for p in pts:
				local.append(p - c)
				uvs.append(_uv(p))
			var dir := c.normalized() if c.length() > 0.1 else Vector2.RIGHT.rotated(randf() * TAU)
			_shards.append({"pts": local, "uvs": uvs, "pos": c,
				"vel": dir * randf_range(110.0, 300.0) * (0.6 + 0.35 * float(ri)),
				"rot": 0.0, "spin": randf_range(-2.5, 2.5)})

## Shard UVs: map screen-space point (relative to planet centre) into the frame.
func _uv(p: Vector2) -> Vector2:
	if planet_tex == null:
		return Vector2.ZERO
	if equirect:
		var q := p / (planet_size * disk_frac)
		if q.length() > 0.999:
			q = q.normalized() * 0.999
		var n := Vector3(q.x, -q.y, sqrt(1.0 - q.length_squared()))
		var c := cos(earth_tilt)
		var s := sin(earth_tilt)
		var nt := Vector3(n.x, c * n.y - s * n.z, s * n.y + c * n.z)
		var lon := atan2(nt.x, nt.z) + earth_rot
		return Vector2(fposmod(lon / TAU + 0.5, 1.0), 0.5 - asin(clampf(nt.y, -1.0, 1.0)) / PI)
	var f := (p / planet_size) + Vector2(0.5, 0.5)
	var px := planet_src.position + f * planet_src.size
	return px / Vector2(planet_tex.get_size())

func _process(delta: float) -> void:
	_t += delta
	for s in _shards:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 1.0 - 0.35 * delta
		s["rot"] += s["spin"] * delta
	for p in _sparks:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 1.0 - 1.4 * delta
		p["life"] -= delta
	for m in _smoke:
		m["pos"] += m["vel"] * delta
		m["r"] += 22.0 * delta
		m["life"] -= delta
	queue_redraw()
	if _t >= DURATION + 1.0:
		queue_free()

func _draw() -> void:
	var t := _t
	var R := planet_size * disk_frac
	# Core swell + fireball
	if t < 1.6:
		var k := t / 1.6
		var fr := R * (0.7 + 0.9 * ease(k, 0.4))
		for j in 6:
			var q := float(j) / 5.0
			draw_circle(Vector2.ZERO, fr * (1.3 - q * 0.9),
				Color(1.0, 0.3 + 0.6 * q, 0.08 + 0.5 * q, (0.1 + 0.18 * q) * (1.0 - k)))
	# Smoke (behind shards)
	for m in _smoke:
		if m["life"] > 0.0 and t > 0.2:
			var a := clampf(m["life"] / 3.0, 0.0, 1.0) * 0.3
			draw_circle(m["pos"], m["r"], Color(0.2, 0.17, 0.16, a))
			draw_circle(m["pos"] + Vector2(-0.3, -0.3) * m["r"], m["r"] * 0.55, Color(0.32, 0.28, 0.26, a * 0.6))
	# Shards of the planet, glowing at the edges
	for s in _shards:
		var fade := clampf(1.0 - (t - 1.9) / 1.2, 0.0, 1.0)
		if fade <= 0.0:
			continue
		draw_set_transform(s["pos"], s["rot"], Vector2.ONE)
		var heat := clampf(1.0 - t / 1.2, 0.0, 1.0)
		var tint := Color(1.0, 1.0 - 0.45 * heat, 1.0 - 0.8 * heat, fade)
		if planet_tex != null:
			draw_polygon(s["pts"], PackedColorArray([tint]), s["uvs"], planet_tex)
		else:
			draw_colored_polygon(s["pts"], Color(0.3, 0.4, 0.6, fade))
		var outline: PackedVector2Array = (s["pts"] as PackedVector2Array).duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color(1.0, 0.55, 0.15, 0.9 * fade), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Sparks
	for p in _sparks:
		if p["life"] > 0.0:
			var c: Color = p["col"]
			c.a = clampf(p["life"], 0.0, 1.0)
			var v: Vector2 = p["vel"]
			draw_line(p["pos"], p["pos"] - v * 0.03, c, 2.0, true)
	# Shock waves
	for w in 2:
		var tw := t - 0.08 - float(w) * 0.25
		if tw > 0.0 and tw < 1.6:
			var k2 := tw / 1.6
			var rr := R + 1100.0 * ease(k2, 0.35)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 128, Color(1.0, 0.85, 0.6, 0.7 * (1.0 - k2)), 14.0 * (1.0 - k2) + 2.0, true)
	# White flash over everything
	if t < 0.5:
		draw_rect(Rect2(-3000, -3000, 6000, 6000), Color(1.0, 0.97, 0.9, 0.85 * (1.0 - t / 0.5)))
