## HudBar
##
## Rounded progress bar for the top-right card.
## mode "gradient": the fill shows a green → yellow → red gradient (pollution).
## mode "segments": `segments` rounded pieces, `ratio` fills them in order (years).
class_name HudBar
extends Control

var ratio: float = 0.0:
	set(v):
		ratio = clampf(v, 0.0, 1.0)
		queue_redraw()
var flash: float = 0.0:
	set(v):
		flash = v
		queue_redraw()
var mode := "gradient"
var segments := 10
var color := Color(0.45, 0.65, 1.0)

const GRAD := [
	[0.0, Color(0.30, 0.82, 0.52)],
	[0.35, Color(0.86, 0.82, 0.38)],
	[0.65, Color(0.95, 0.55, 0.25)],
	[1.0, Color(0.95, 0.27, 0.22)],
]

static func grad_at(t: float) -> Color:
	for i in GRAD.size() - 1:
		var a: Array = GRAD[i]
		var b: Array = GRAD[i + 1]
		if t <= float(b[0]):
			return (a[1] as Color).lerp(b[1], (t - float(a[0])) / (float(b[0]) - float(a[0])))
	return GRAD[GRAD.size() - 1][1]

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _pill(r: Rect2, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(minf(r.size.y, r.size.x) * 0.5))
	sb.anti_aliasing = true
	draw_style_box(sb, r)

func _draw() -> void:
	var h := size.y
	var track := Color(1, 1, 1, 0.08)
	if mode == "segments":
		var gap := 4.0
		var w := (size.x - gap * float(segments - 1)) / float(segments)
		var filled := ratio * float(segments)
		for i in segments:
			var r := Rect2(float(i) * (w + gap), 0.0, w, h)
			_pill(r, track)
			var part := clampf(filled - float(i), 0.0, 1.0)
			if part > 0.0:
				var fw := maxf(h, w * part) if part < 1.0 else w
				_pill(Rect2(r.position, Vector2(fw, h)), color if part >= 1.0 else Color(color, 0.85))
		return
	# gradient bar
	_pill(Rect2(Vector2.ZERO, size), track)
	if ratio > 0.0:
		var fw := maxf(h, size.x * ratio)
		# Clip the gradient with many thin slices, then round the ends with pills.
		var steps := int(fw / 3.0) + 1
		var rad := h * 0.5
		for s in steps:
			var x0 := float(s) * 3.0
			var x1 := minf(fw, x0 + 3.0)
			if x1 <= x0:
				break
			var xm := (x0 + x1) * 0.5
			var c := grad_at(xm / size.x)
			if flash > 0.0:
				c = c.lerp(Color(1.0, 0.25, 0.25), flash)
			# height shrinks at the rounded ends
			var dy := 0.0
			if xm < rad:
				dy = rad - sqrt(maxf(0.0, rad * rad - (rad - xm) * (rad - xm)))
			elif xm > fw - rad:
				var d := xm - (fw - rad)
				dy = rad - sqrt(maxf(0.0, rad * rad - d * d))
			draw_rect(Rect2(x0, dy, x1 - x0 + 0.5, h - dy * 2.0), c)
		# soft highlight on the top half
		_pill(Rect2(Vector2(rad * 0.6, 2.0), Vector2(maxf(0.0, fw - rad * 1.2), h * 0.3)), Color(1, 1, 1, 0.18))
	# threshold ticks (where the planet changes stage)
	for t in [0.2, 0.45, 0.7]:
		draw_line(Vector2(size.x * t, 2.0), Vector2(size.x * t, h - 2.0), Color(0, 0, 0, 0.35), 1.0)
