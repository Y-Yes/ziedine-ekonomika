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
const COL_X := [122.0, 180.0, 238.0]
const COL_W := 50.0
const KINDS := ["speed", "cap", "value"]
const HEADS := ["Greitis", "Sandėlis", "Vertė"]

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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for p in Station.ART:
		_sheets.append(load(p) if ResourceLoader.exists(p) else null)
	size = Vector2(PAD * 2.0 + 300.0, PAD * 2.0 + HEAD_H + ROW_H * 6.0)
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

func _pill(r: Rect2, c: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(minf(r.size.x, r.size.y) * 0.5))
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	sb.anti_aliasing = true
	draw_style_box(sb, r)

func _draw() -> void:
	if game == null:
		return
	var f := font if font != null else ThemeDB.fallback_font
	var fb := bold if bold != null else f
	# Panel – same glass style as the other panels
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.045, 0.065, 0.105, 0.86)
	sb.border_color = Color(0.55, 0.7, 0.9, 0.34)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))

	# Header (one muted colour)
	var head_col := Color(0.62, 0.7, 0.82)
	draw_string(fb, Vector2(PAD + 4.0, PAD + 16.0), Loc.t("Stotis"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, head_col)
	for c in 3:
		draw_string(fb, Vector2(PAD + COL_X[c], PAD + 16.0), Loc.t(HEADS[c]), HORIZONTAL_ALIGNMENT_LEFT, COL_W + 8.0, 12, head_col)
	draw_line(Vector2(PAD, PAD + HEAD_H - 3.0), Vector2(size.x - PAD, PAD + HEAD_H - 3.0), Color(1, 1, 1, 0.08), 1.0)

	var glow_a := 0.5 + 0.5 * sin(_t * 6.0)
	var tip: Array = game.table_tip() if game.running else [-1, ""]
	for i in 6:
		var st: Station = game.stations[i]
		var y0 := PAD + HEAD_H + float(i) * ROW_H
		var row := Rect2(PAD * 0.5, y0, size.x - PAD, ROW_H - 2.0)
		if game.selected_index == i:
			var s2 := StyleBoxFlat.new()
			s2.bg_color = Color(1, 1, 1, 0.1)
			s2.border_color = Color(1, 1, 1, 0.35)
			s2.set_border_width_all(1)
			s2.set_corner_radius_all(7)
			draw_style_box(s2, row)
		elif _hover == i:
			var s3 := StyleBoxFlat.new()
			s3.bg_color = Color(1, 1, 1, 0.05)
			s3.set_corner_radius_all(7)
			draw_style_box(s3, row)

		# mini picture of the island (no frame around it)
		var cy := y0 + ROW_H * 0.5 - 1.0
		var sh := _sheets[i]
		var ir := Rect2(PAD + 1.0, cy - ICON * 0.5 - 1.0, ICON + 4.0, ICON + 4.0)
		if sh != null:
			StationMotion.draw(self, i, sh, ir, 4.0, false)
		if st.fire > 0.0:
			draw_circle(ir.get_center(), ICON * 0.45, Color(1.0, 0.4, 0.1, 0.45 + 0.3 * sin(_t * 12.0)))

		# name – plain light text
		draw_string(f, Vector2(PAD + NAME_X - 4.0, cy + 5.0), Pipeline.name_of(i), HORIZONTAL_ALIGNMENT_LEFT, 82, 13,
			Color(0.9, 0.93, 0.97))

		# level bars – smooth pills; the cheapest affordable upgrade glows green
		var glow_kind: String = tip[1] if int(tip[0]) == i else ""
		for c in 3:
			var lvl := st.level_of(KINDS[c])
			var x0 := PAD + float(COL_X[c])
			var bw := 36.0
			var glowing: bool = KINDS[c] == glow_kind
			var tr := Rect2(x0, cy - 3.0, bw, 6.0)
			_pill(tr, Color(1, 1, 1, 0.1))
			var ratio := float(lvl) / float(Station.MAX_LEVEL)
			if glowing:
				var nxt := Rect2(tr.position, Vector2(bw * float(lvl + 1) / float(Station.MAX_LEVEL), 6.0))
				_pill(nxt, Color(0.4, 1.0, 0.55, 0.25 + 0.35 * glow_a))
			if lvl > 0:
				_pill(Rect2(tr.position, Vector2(maxf(6.0, bw * ratio), 6.0)), Color(0.62, 0.8, 1.0))
			if glowing:
				_pill(tr.grow(2.5), Color(0, 0, 0, 0), Color(0.45, 1.0, 0.55, 0.4 + 0.5 * glow_a), 1)
			draw_string(fb, Vector2(x0 + bw + 8.0, cy + 4.0), str(lvl), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color(0.55, 1.0, 0.6) if glowing else Color(0.85, 0.9, 1.0, 0.8))
