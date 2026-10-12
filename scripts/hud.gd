## Hud
##
## Screen-space interface: money & statistics, pollution meter, year progress,
## market event / disaster banners, station legend, the selected-station
## upgrade shop, action buttons (raw material, clean-up), the yearly report
## with investment cards and the start / final overlay. Everything is built in
## code so the project needs no UI scenes.
class_name Hud
extends CanvasLayer

const DESIGN_W := 1152.0
const DESIGN_H := 648.0
const KINDS := ["speed", "cap", "value"]
const BAR_W := 260.0

var game: Node

var _root: Control
var _icons: Texture2D

var title_label: Label
var money_label: Label
var income_label: Label
var circ_label: Label
var loops_label: Label
var status_label: Label

var pol_label: Label
var pol_fill: ColorRect
var pol_flash: float = 0.0
var year_label: Label
var year_fill: ColorRect

var legend_labels: Array[Label] = []

var event_panel: PanelContainer
var event_title: Label
var event_desc: Label
var event_bar: ColorRect

var alert_panel: PanelContainer
var alert_title: Label
var alert_desc: Label
var alert_time: float = 0.0

var panel: PanelContainer
var panel_title: Label
var panel_fact: Label
var row_name: Array[Label] = []
var row_desc: Array[Label] = []
var row_btn: Array[Button] = []
var panel_station: Station = null

var raw_btn: Button
var clean_btn: Button

var report: ColorRect
var report_title: Label
var report_text: Label
var report_goal: Label
var card_btns: Array[Button] = []

var overlay: Control
var overlay_title: Label
var overlay_text: Label
var overlay_btn: Button

func setup(g: Node) -> void:
	game = g
	if ResourceLoader.exists("res://art/ikonos.png"):
		_icons = load("res://art/ikonos.png")
	_build()

# --- Construction ----------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	title_label = _label(_root, Vector2(20, 8), 26, Color(0.85, 0.92, 1.0))
	title_label.text = "Žiedinė ekonomika"
	money_label = _label(_root, Vector2(54, 42), 26, Color(1.0, 0.88, 0.45))
	income_label = _label(_root, Vector2(56, 74), 14, Color(0.75, 0.85, 0.7))
	circ_label = _label(_root, Vector2(50, 98), 17, Color(0.75, 0.95, 0.8))
	loops_label = _label(_root, Vector2(50, 124), 17, Color(0.8, 0.9, 1.0))
	status_label = _label(_root, Vector2(20, 152), 15, Color(0.95, 0.8, 0.4))
	_icon(0, Vector2(18, 45), 30)
	_icon(1, Vector2(21, 100), 22)
	_icon(2, Vector2(21, 126), 22)

	_build_bars()
	_build_legend()
	_build_event_banner()
	_build_alert()
	_build_panel()
	_build_buttons()
	_build_report()
	_build_overlay()

func _style(bg: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _button_styles(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", _style(accent.darkened(0.55), accent.darkened(0.2), 8))
	b.add_theme_stylebox_override("hover", _style(accent.darkened(0.4), accent.lightened(0.1), 8))
	b.add_theme_stylebox_override("pressed", _style(accent.darkened(0.25), Color.WHITE, 8))
	b.add_theme_stylebox_override("disabled", _style(Color(0.13, 0.15, 0.2), Color(0.22, 0.25, 0.32), 8))
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))
	b.focus_mode = Control.FOCUS_NONE

func _bar(pos: Vector2, h: float, bg: Color) -> ColorRect:
	var back := ColorRect.new()
	back.color = bg
	back.position = pos
	back.size = Vector2(BAR_W, h)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(back)
	var fill := ColorRect.new()
	fill.position = Vector2(2, 2)
	fill.size = Vector2(0, h - 4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	return fill

func _build_bars() -> void:
	var x := DESIGN_W - 20.0 - BAR_W
	pol_label = _label(_root, Vector2(x, 6), 16, Color(0.9, 0.9, 0.85))
	pol_fill = _bar(Vector2(x, 30), 18, Color(0.16, 0.19, 0.24))
	year_label = _label(_root, Vector2(x, 52), 14, Color(0.75, 0.85, 1.0))
	year_fill = _bar(Vector2(x, 72), 8, Color(0.16, 0.19, 0.24))
	year_fill.color = Color(0.45, 0.65, 1.0)

func _build_legend() -> void:
	var head := _label(_root, Vector2(20, 430), 15, Color(0.7, 0.8, 0.95))
	head.text = "Ciklas  (G – greitis, S – sandėlis, V – vertė)"
	for i in Pipeline.count():
		var l := _label(_root, Vector2(20, 456 + i * 22), 14)
		l.add_theme_color_override("font_color", Pipeline.color_of(i))
		legend_labels.append(l)
	var hint := _label(_root, Vector2(20, 590), 12, Color(0.55, 0.62, 0.72))
	hint.text = "Spausk stotį – rankinis darbas + patobulinimai.\nGaudyk € monetas!  Tarpas – žaliava,  V – valymas."

func _build_event_banner() -> void:
	event_panel = PanelContainer.new()
	event_panel.add_theme_stylebox_override("panel", _style(Color(0.16, 0.13, 0.06, 0.95), Color(1.0, 0.8, 0.3)))
	event_panel.position = Vector2(DESIGN_W * 0.5 - 210, 6)
	event_panel.custom_minimum_size = Vector2(420, 0)
	event_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_panel.visible = false
	_root.add_child(event_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	event_panel.add_child(vb)
	event_title = _center_label(vb, 18, Color(1.0, 0.85, 0.4))
	event_desc = _center_label(vb, 14, Color(0.95, 0.92, 0.85))
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.3, 0.25, 0.1)
	bar_bg.custom_minimum_size = Vector2(396, 4)
	vb.add_child(bar_bg)
	event_bar = ColorRect.new()
	event_bar.color = Color(1.0, 0.8, 0.3)
	event_bar.size = Vector2(396, 4)
	bar_bg.add_child(event_bar)

func _build_alert() -> void:
	alert_panel = PanelContainer.new()
	alert_panel.add_theme_stylebox_override("panel", _style(Color(0.25, 0.06, 0.04, 0.95), Color(1.0, 0.4, 0.25)))
	alert_panel.position = Vector2(DESIGN_W * 0.5 - 170, 290)
	alert_panel.custom_minimum_size = Vector2(340, 0)
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.visible = false
	_root.add_child(alert_panel)
	var vb := VBoxContainer.new()
	alert_panel.add_child(vb)
	alert_title = _center_label(vb, 18, Color(1.0, 0.6, 0.4))
	alert_desc = _center_label(vb, 13, Color(1.0, 0.9, 0.85))

func _center_label(parent: Control, size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(DESIGN_W - 330, 92)
	panel.custom_minimum_size = Vector2(310, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	_root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 21)
	vb.add_child(panel_title)

	panel_fact = Label.new()
	panel_fact.add_theme_font_size_override("font_size", 12)
	panel_fact.add_theme_color_override("font_color", Color(0.65, 0.73, 0.84))
	panel_fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_fact.custom_minimum_size = Vector2(286, 0)
	vb.add_child(panel_fact)

	for i in KINDS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 0)
		row.add_child(texts)
		var n := Label.new()
		n.add_theme_font_size_override("font_size", 15)
		texts.add_child(n)
		var d := Label.new()
		d.add_theme_font_size_override("font_size", 12)
		d.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9))
		texts.add_child(d)
		var b := Button.new()
		b.custom_minimum_size = Vector2(78, 40)
		b.add_theme_font_size_override("font_size", 16)
		var kind: String = KINDS[i]
		b.pressed.connect(func(): game.upgrade_selected(kind))
		row.add_child(b)
		row_name.append(n)
		row_desc.append(d)
		row_btn.append(b)

func _build_buttons() -> void:
	clean_btn = Button.new()
	clean_btn.position = Vector2(DESIGN_W - 330, DESIGN_H - 136)
	clean_btn.size = Vector2(310, 54)
	clean_btn.add_theme_font_size_override("font_size", 14)
	_button_styles(clean_btn, Color(0.3, 0.7, 0.9))
	clean_btn.pressed.connect(func(): game.clean_up())
	_root.add_child(clean_btn)

	raw_btn = Button.new()
	raw_btn.position = Vector2(DESIGN_W - 330, DESIGN_H - 74)
	raw_btn.size = Vector2(310, 54)
	raw_btn.add_theme_font_size_override("font_size", 14)
	_button_styles(raw_btn, Color(0.85, 0.55, 0.25))
	raw_btn.pressed.connect(func(): game.buy_raw())
	_root.add_child(raw_btn)

func _build_report() -> void:
	report = ColorRect.new()
	report.color = Color(0.02, 0.03, 0.05, 0.8)
	report.set_anchors_preset(Control.PRESET_FULL_RECT)
	report.mouse_filter = Control.MOUSE_FILTER_STOP
	report.visible = false
	_root.add_child(report)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	report.add_child(cc)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.15, 0.98), Color(0.45, 0.65, 1.0), 14))
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	report_title = _center_label(vb, 30, Color(0.85, 0.92, 1.0))
	report_text = _center_label(vb, 16, Color(0.85, 0.9, 0.96))
	report_goal = _center_label(vb, 17, Color(1, 1, 1))
	var pick := _center_label(vb, 16, Color(1.0, 0.85, 0.45))
	pick.text = "Pasirink vieną investiciją ateinantiems metams:"
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	var accents := [Color(0.35, 0.8, 0.5), Color(0.45, 0.65, 1.0), Color(0.85, 0.6, 1.0)]
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 110)
		b.add_theme_font_size_override("font_size", 15)
		_button_styles(b, accents[i])
		var idx := i
		b.pressed.connect(func(): game.choose_card(idx))
		hb.add_child(b)
		card_btns.append(b)

func _label(parent: Control, pos: Vector2, size: int, color: Color = Color(0.92, 0.95, 1.0)) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

## Small icon from art/ikonos.png (3 square icons: coin, leaf, cycle).
func _icon(idx: int, pos: Vector2, size: float) -> void:
	if _icons == null:
		return
	var fw := float(_icons.get_width()) / 3.0
	var at := AtlasTexture.new()
	at.atlas = _icons
	at.region = Rect2(fw * idx, 0.0, fw, float(_icons.get_height()))
	var tr := TextureRect.new()
	tr.texture = at
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = pos
	tr.size = Vector2(size, size)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(vb)

	overlay_title = _center_label(vb, 40, Color(0.85, 0.93, 1.0))

	overlay_text = Label.new()
	overlay_text.add_theme_font_size_override("font_size", 16)
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	overlay_text.custom_minimum_size = Vector2(820, 0)
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(overlay_text)

	var center_btn := CenterContainer.new()
	vb.add_child(center_btn)
	overlay_btn = Button.new()
	overlay_btn.custom_minimum_size = Vector2(240, 52)
	overlay_btn.add_theme_font_size_override("font_size", 20)
	_button_styles(overlay_btn, Color(0.35, 0.8, 0.5))
	overlay_btn.pressed.connect(_on_overlay_pressed)
	center_btn.add_child(overlay_btn)

# --- Overlays / panels -------------------------------------------------------

func show_start_overlay() -> void:
	overlay.visible = true
	overlay_title.text = "Žiedinė ekonomika"
	overlay_text.text = (
		"Tau patikėta 10 metų valdyti žiedinės ekonomikos įmonių grandinę!\n\n"
		+ "Daiktas keliauja: naudotojas → surinkimas → rūšiavimas → perdirbimas → gamykla → parduotuvė → ir vėl pas naudotoją. "
		+ "Kiekviena stotis prideda produktui vertės, o parduotuvėje jis parduodamas.\n\n"
		+ "• Spausk stotį (arba 1–6) – ji iškart apdoroja vieną daiktą. Už € pirk patobulinimus.\n"
		+ "• Ko nespėji apdoroti – keliauja į sąvartyną: auga tarša, mokestis, krenta kainos, kyla gaisrai ir potvyniai.\n"
		+ "• Gaudyk investuotojų € monetas. Naujos žaliavos pirkimas (Tarpas) – greitas, bet teršia. Valymas (V) – brangus.\n"
		+ "• Metų pabaigoje – ataskaita, ES žiedinumo tikslas ir investicijos pasirinkimas.\n\n"
		+ "Gali tapti turtingu ant degančios planetos – arba rasti pusiausvyrą. Esc – pauzė, R – iš naujo."
	)
	overlay_btn.text = "Pradėti"

func show_report(s: Dictionary, cards: Array) -> void:
	hide_panel()
	report.visible = true
	report_title.text = "%d-ųjų metų ataskaita" % int(s["year"])
	report_text.text = "Pajamos: €%d     Į sąvartyną: %d vnt.     Tarša: %d %%\nŽiedinumo rodiklis: %d %%" % [
		int(s["earned"]), int(s["landfill"]), int(s["pollution"]), int(s["circ"])]
	if bool(s["met"]):
		report_goal.text = "ES tikslas (%d %%) pasiektas!  Premija +€%d" % [int(s["target"]), int(s["reward"])]
		report_goal.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6))
	else:
		report_goal.text = "ES tikslas (%d %%) nepasiektas.  Bauda -€%d" % [int(s["target"]), int(-float(s["reward"]))]
		report_goal.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
	for i in card_btns.size():
		if i < cards.size():
			card_btns[i].visible = true
			card_btns[i].text = "%s\n\n%s" % [cards[i]["title"], cards[i]["desc"]]
		else:
			card_btns[i].visible = false

func hide_report() -> void:
	if report != null:
		report.visible = false

func show_final(s: Dictionary) -> void:
	hide_panel()
	hide_event()
	overlay.visible = true
	overlay_title.text = game.final_title()
	var goal := "pasiektas" if bool(s["met"]) else "nepasiektas"
	overlay_text.text = (
		"10 metų baigėsi!  Paskutinių metų ES tikslas %s.\n\n"
		+ "Iš viso uždirbta: €%d\nUžbaigtų ciklų: %d\nŽiedinumo rodiklis: %d %%\n"
		+ "Sąvartyne: %d vnt.     Tarša: %d %%\n\n"
		+ "GALUTINIAI TAŠKAI: %d\n\n"
		+ "Taškai = pinigai + planetos būklė + žiedinumas. Turtas ant užterštos planetos vertas mažiau."
	) % [goal, int(game.total_earned), game.loops, int(game.circularity()), game.landfilled,
		int(game.pollution), game.final_score()]
	overlay_btn.text = "Žaisti dar kartą"

func hide_overlay() -> void:
	overlay.visible = false

func set_paused(p: bool) -> void:
	status_label.text = "Pauzė – spausk Esc" if p else ""

func show_panel(station: Station) -> void:
	panel_station = station
	panel.visible = true
	var accent := Pipeline.color_of(station.index)
	panel.add_theme_stylebox_override("panel", _style(Color(0.09, 0.11, 0.16, 0.96), accent.darkened(0.1), 12))
	for b in row_btn:
		_button_styles(b, accent)
	refresh()

func hide_panel() -> void:
	panel.visible = false
	panel_station = null

func show_event(e: Dictionary, frac: float) -> void:
	event_panel.visible = true
	event_title.text = str(e["title"])
	event_desc.text = str(e["desc"])
	event_bar.size.x = 396.0 * frac

func hide_event() -> void:
	if event_panel != null:
		event_panel.visible = false

func show_alert(title: String, desc: String) -> void:
	alert_title.text = title
	alert_desc.text = desc
	alert_panel.visible = true
	alert_time = 3.5

# --- Callbacks -------------------------------------------------------------

func _on_overlay_pressed() -> void:
	game.start_game()

func flash_overflow() -> void:
	pol_flash = 1.0

# --- Per-frame refresh -----------------------------------------------------

func _process(delta: float) -> void:
	if pol_flash > 0.0:
		pol_flash = maxf(0.0, pol_flash - delta * 2.5)
		_update_bars()
	if alert_time > 0.0:
		alert_time -= delta
		if alert_time <= 0.0:
			alert_panel.visible = false

func refresh() -> void:
	if game == null:
		return

	money_label.text = "€ %d" % int(floor(game.money))
	money_label.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.45) if game.money >= 0.0 else Color(1.0, 0.45, 0.4))
	income_label.text = "Pajamos: €%d / min" % int(game.income_per_min())
	circ_label.text = "Žiedinumas: %d %%" % int(game.circularity())
	loops_label.text = "Užbaigti ciklai: %d" % game.loops

	_update_bars()

	for i in legend_labels.size():
		var st: Station = game.stations[i]
		legend_labels[i].text = "%d. %s   G%d  S%d  V%d" % [
			i + 1, Pipeline.name_of(i), st.speed_level, st.cap_level, st.value_level,
		]

	var rp: float = game.raw_price()
	raw_btn.text = "Pirkti naują žaliavą – €%d   [Tarpas]\n(greita, bet +tarša, mažina žiedinumą)" % int(round(rp))
	raw_btn.disabled = game.money < rp or not game.running
	var cp: float = game.cleanup_price()
	clean_btn.text = "Valyti aplinką – €%d   [V]\n(-%d taršos, kaskart brangiau)" % [int(cp), int(game.CLEANUP_AMOUNT)]
	clean_btn.disabled = game.money < cp or not game.running or game.pollution < 1.0

	_refresh_panel()

func _update_bars() -> void:
	var p: float = clampf(game.pollution / 100.0, 0.0, 1.0)
	pol_label.text = "Tarša: %d %%  –  %s" % [int(game.pollution), game.pollution_stage()]
	pol_fill.size.x = maxf(0.0, (BAR_W - 4.0) * p)
	var c: Color
	if p < 0.2:
		c = Color(0.35, 0.8, 0.5)
	elif p < 0.45:
		c = Color(0.75, 0.75, 0.5)
	elif p < 0.7:
		c = Color(0.85, 0.6, 0.3)
	else:
		c = Color(0.95, 0.3, 0.2)
	if pol_flash > 0.0:
		c = c.lerp(Color(1.0, 0.25, 0.25), pol_flash)
	pol_fill.color = c
	year_label.text = "Metai %d / %d" % [game.year, game.YEARS]
	year_fill.size.x = (BAR_W - 4.0) * clampf(game.year_time / game.YEAR_LEN, 0.0, 1.0)

func _refresh_panel() -> void:
	if not panel.visible or panel_station == null:
		return
	var st := panel_station
	var accent := Pipeline.color_of(st.index)
	panel_title.text = "%d. %s" % [st.index + 1, Pipeline.name_of(st.index)]
	panel_title.add_theme_color_override("font_color", accent.lightened(0.15))
	panel_fact.text = Pipeline.fact_of(st.index)
	for i in KINDS.size():
		var kind: String = KINDS[i]
		var lvl := st.level_of(kind)
		row_name[i].text = "%s  (L%d)" % [Pipeline.upgrade_name(st.index, kind), lvl]
		row_name[i].add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		if st.is_maxed(kind):
			row_desc[i].text = "Maksimalus lygis"
			row_btn[i].text = "MAX"
			row_btn[i].disabled = true
		else:
			var cost := st.cost_of(kind)
			row_desc[i].text = st.preview(kind)
			row_btn[i].text = "€%d" % cost
			row_btn[i].disabled = game.money < cost
