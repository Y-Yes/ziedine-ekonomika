## StationTable
##
## Bottom-left overview of all six stations: mini picture, name and three
## level bars (speed, storage, value) with 10 pips each. A green arrow marks a
## station with an affordable upgrade. Clicking a row opens that station's shop.
class_name StationTable
extends Control

const ROW_H := 30.0
const HEAD_H := 26.0
const PAD := 10.0
const ICON := 24.0
const NAME_X := 42.0
const COL_X := [122.0, 186.0, 250.0]
const COL_W := 50.0
const KINDS := ["speed", "cap", "value"]
const HEADS := ["Greitis", "Sandėlis", "Vertė"]
const HEAD_COLORS := [Color(0.55, 0.8, 1.0), Color(1.0, 0.8, 0.45), Color(0.6, 1.0, 0.65)]

var game: Node
var font: Font
var bold: Font
var _hover: int = -1
var _sheets: Array[Texture2D] = []
var _t: float = 0.0

func setup(g: Node, f: Font, fb: Font) -> void:
	game = g
	font = f
	bold = fb
	for p in Station.ART:
		_sheets.append(load(p) if ResourceLoader.exists(p) else null)
	size = Vector2(PAD * 2.0 + 316.0, PAD * 2.0 + HEAD_H + ROW_H * 6.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _row_at(p: Vector2) -> int:
	var y := p.y - PAD - HEAD_H
	if y < 0.0 or p.x < 0.0 or p.x > size.x:
		return -1
	var r := int(y / ROW_H)
	return r if r >= 0 and r < 6 else -1

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		_hover = _row_at(ev.position)
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var r := _row_at(ev.position)
		if r >= 0 and game != null and game.running:
			Sfx.play("click")
			game.select_station(r)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = -1

func _affordable(st: Station) -> bool:
	for k in KINDS:
		if not st.is_maxed(k) and game.money >= st.cost_of(k):
			return true
	return false

func _draw() -> void:
	if game == null:
		return
	var f := font if font != null else ThemeDB.fallback_font
	var fb := bold if bold != null else f
	# Panel
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.13, 0.88)
	sb.border_color = Color(0.25, 0.3, 0.4, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))

	# Header
	draw_string(fb, Vector2(PAD + 4.0, PAD + 16.0), "Stotis", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.78, 0.9))
	for c in 3:
		draw_string(fb, Vector2(PAD + COL_X[c], PAD + 16.0), HEADS[c], HORIZONTAL_ALIGNMENT_LEFT, COL_W + 8.0, 12, HEAD_COLORS[c])

	for i in 6:
		var st: Station = game.stations[i]
		var accent := Pipeline.color_of(i)
		var y0 := PAD + HEAD_H + float(i) * ROW_H
		var row := Rect2(PAD * 0.5, y0, size.x - PAD, ROW_H - 2.0)
		if game.selected_index == i:
			var s2 := StyleBoxFlat.new()
			s2.bg_color = Color(accent, 0.18)
			s2.border_color = Color(accent, 0.8)
			s2.set_border_width_all(1)
			s2.set_corner_radius_all(7)
			draw_style_box(s2, row)
		elif _hover == i:
			var s3 := StyleBoxFlat.new()
			s3.bg_color = Color(1, 1, 1, 0.06)
			s3.set_corner_radius_all(7)
			draw_style_box(s3, row)

		# mini picture (first frame of the station animation)
		var cy := y0 + ROW_H * 0.5 - 1.0
		draw_circle(Vector2(PAD + 4.0 + ICON * 0.5, cy), ICON * 0.5 + 1.0, Color(0.11, 0.13, 0.18))
		draw_arc(Vector2(PAD + 4.0 + ICON * 0.5, cy), ICON * 0.5 + 1.0, 0, TAU, 24, accent, 1.5, true)
		var sh := _sheets[i]
		if sh != null:
			var fw := float(sh.get_width()) / float(Station.ANIM_FRAMES)
			draw_texture_rect_region(sh, Rect2(PAD + 4.0 + 2.0, cy - ICON * 0.5 + 1.0, ICON - 4.0, ICON - 4.0),
				Rect2(0, 0, fw, float(sh.get_height())))
		if st.fire > 0.0:
			draw_circle(Vector2(PAD + 4.0 + ICON * 0.5, cy), ICON * 0.5, Color(1.0, 0.4, 0.1, 0.5 + 0.3 * sin(_t * 12.0)))

		# name
		draw_string(f, Vector2(PAD + NAME_X - 6.0, cy + 5.0), Pipeline.name_of(i), HORIZONTAL_ALIGNMENT_LEFT, 84, 13,
			accent.lightened(0.2))

		# level bars
		for c in 3:
			var lvl := st.level_of(KINDS[c])
			var x0 := PAD + float(COL_X[c])
			var pip_w := 3.4
			var gap := 1.0
			for k in Station.MAX_LEVEL:
				var r := Rect2(x0 + k * (pip_w + gap), cy - 6.0, pip_w, 12.0)
				var col: Color = HEAD_COLORS[c] if k < lvl else Color(0.2, 0.23, 0.3)
				draw_rect(r, col)
			draw_string(fb, Vector2(x0 + 10 * (pip_w + gap) + 3.0, cy + 4.0), str(lvl), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color(0.85, 0.9, 1.0, 0.85))

		# affordable upgrade marker (bouncing green arrow)
		if game.running and _affordable(st):
			var bx := size.x - PAD - 2.0
			var by := cy + sin(_t * 6.0 + i) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(bx - 6, by + 3), Vector2(bx, by - 5), Vector2(bx + 6, by + 3)]), Color(0.45, 1.0, 0.55))
