## Hud
##
## Screen-space interface: statistics, the ecology meter, a legend of the
## stations, the selected-station upgrade panel and the start / game-over
## overlay. Everything is built in code so the project needs no UI scenes.
class_name Hud
extends CanvasLayer

const DESIGN_W := 1152.0
const DESIGN_H := 648.0

var game: Node

var _root: Control

var title_label: Label
var score_label: Label
var points_label: Label
var loops_label: Label
var status_label: Label

var eco_label: Label
var eco_bg: ColorRect
var eco_fill: ColorRect
var eco_width := 260.0
var eco_flash: float = 0.0

var legend_labels: Array[Label] = []

var panel: ColorRect
var panel_title: Label
var panel_info: Label
var speed_btn: Button
var cap_btn: Button
var panel_station: Station = null

var overlay: Control
var overlay_title: Label
var overlay_text: Label
var overlay_btn: Button

func setup(g: Node) -> void:
	game = g
	_build()

# --- Construction ----------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	title_label = _label(Vector2(20, 8), 28, Color(0.85, 0.92, 1.0))
	title_label.text = "Žiedinė ekonomika"
	score_label = _label(Vector2(50, 46), 20)
	points_label = _label(Vector2(50, 76), 17, Color(0.75, 0.95, 0.8))
	loops_label = _label(Vector2(50, 102), 17, Color(0.8, 0.9, 1.0))
	_icon(0, Vector2(20, 49), 24)   # coin  -> score
	_icon(1, Vector2(21, 78), 22)   # leaf  -> eco points
	_icon(2, Vector2(21, 104), 22)  # cycle -> loops
	status_label = _label(Vector2(20, 126), 15, Color(0.95, 0.8, 0.4))

	_build_eco_bar()
	_build_legend()
	_build_panel()
	_build_overlay()

func _build_eco_bar() -> void:
	var x := DESIGN_W - 20.0 - eco_width
	eco_label = _label(Vector2(x, 8), 17, Color(0.8, 0.95, 0.85))
	eco_label.text = "Ekologija"
	eco_bg = ColorRect.new()
	eco_bg.color = Color(0.16, 0.19, 0.24, 1.0)
	eco_bg.position = Vector2(x, 32)
	eco_bg.size = Vector2(eco_width, 20)
	eco_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(eco_bg)
	eco_fill = ColorRect.new()
	eco_fill.color = Color(0.35, 0.8, 0.5, 1.0)
	eco_fill.position = Vector2(x + 2, 34)
	eco_fill.size = Vector2(eco_width - 4, 16)
	eco_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(eco_fill)

func _build_legend() -> void:
	var head := _label(Vector2(20, 452), 16, Color(0.7, 0.8, 0.95))
	head.text = "Ciklas (1–6):"
	for i in Pipeline.count():
		var l := _label(Vector2(20, 480 + i * 24), 15)
		l.add_theme_color_override("font_color", Pipeline.color_of(i))
		legend_labels.append(l)

func _label(pos: Vector2, size: int, color: Color = Color(0.92, 0.95, 1.0)) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l

## Small icon from art/ikonos.png (3 square icons: coin, leaf, cycle).
func _icon(idx: int, pos: Vector2, size: float) -> void:
	if not ResourceLoader.exists("res://art/ikonos.png"):
		return
	var sheet: Texture2D = load("res://art/ikonos.png")
	var fw := float(sheet.get_width()) / 3.0
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(fw * idx, 0.0, fw, float(sheet.get_height()))
	var tr := TextureRect.new()
	tr.texture = at
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = pos
	tr.size = Vector2(size, size)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tr)

func _build_panel() -> void:
	panel = ColorRect.new()
	panel.color = Color(0.10, 0.12, 0.17, 0.96)
	panel.position = Vector2(DESIGN_W - 272, 120)
	panel.size = Vector2(252, 224)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	_root.add_child(panel)

	panel_title = Label.new()
	panel_title.position = Vector2(14, 10)
	panel_title.add_theme_font_size_override("font_size", 20)
	panel.add_child(panel_title)

	panel_info = Label.new()
	panel_info.position = Vector2(14, 42)
	panel_info.add_theme_font_size_override("font_size", 14)
	panel_info.add_theme_color_override("font_color", Color(0.8, 0.87, 0.95))
	panel.add_child(panel_info)

	speed_btn = Button.new()
	speed_btn.position = Vector2(14, 108)
	speed_btn.size = Vector2(224, 42)
	speed_btn.pressed.connect(_on_speed_pressed)
	panel.add_child(speed_btn)

	cap_btn = Button.new()
	cap_btn.position = Vector2(14, 158)
	cap_btn.size = Vector2(224, 42)
	cap_btn.pressed.connect(_on_capacity_pressed)
	panel.add_child(cap_btn)

	var hint := Label.new()
	hint.position = Vector2(14, 202)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.68, 0.78))
	hint.text = "Lygį kelia uždirbti eco-taškai"
	panel.add_child(hint)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(vb)

	overlay_title = Label.new()
	overlay_title.add_theme_font_size_override("font_size", 42)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_color_override("font_color", Color(0.85, 0.93, 1.0))
	vb.add_child(overlay_title)

	overlay_text = Label.new()
	overlay_text.add_theme_font_size_override("font_size", 18)
	overlay_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_text.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	overlay_text.custom_minimum_size = Vector2(780, 0)
	overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(overlay_text)

	var center_btn := CenterContainer.new()
	vb.add_child(center_btn)
	overlay_btn = Button.new()
	overlay_btn.custom_minimum_size = Vector2(240, 52)
	overlay_btn.add_theme_font_size_override("font_size", 20)
	overlay_btn.pressed.connect(_on_overlay_pressed)
	center_btn.add_child(overlay_btn)

# --- Overlay / panel state -------------------------------------------------

func show_start_overlay() -> void:
	overlay.visible = true
	overlay_title.text = "Žiedinė ekonomika"
	overlay_text.text = (
		"Tvarkyk medžiagų apytakos ratą!\n\n"
		+ "Prekė keliauja per 6 etapus: naudotojas → surinkimas → rūšiavimas →\n"
		+ "perdirbimas → gamykla → parduotuvė → ir vėl pas naudotoją.\n\n"
		+ "Spausk bokštelį (arba klavišus 1–6), kad pagerintum jo greitį ir buferį,\n"
		+ "ir neleistum medžiagoms išsilieti į sąvartyną.\n\n"
		+ "Kai bokštelis persipildo – krenta ekologija. Nukritus iki 0 žaidimas baigiasi.\n"
		+ "Esc – pauzė, R – iš naujo."
	)
	overlay_btn.text = "Pradėti"

func show_game_over() -> void:
	overlay.visible = true
	overlay_title.text = "Ciklas nutrūko"
	overlay_text.text = (
		"Taškai: %d\nUžbaigtų ciklų: %d\nIšgyventa: %.1f s\n\n"
		+ "Mažiau atliekų – daugiau vertės, likusios apykaitoje."
	) % [game.score, game.loops, game.elapsed]
	overlay_btn.text = "Bandyti dar kartą"

func hide_overlay() -> void:
	overlay.visible = false

func set_paused(p: bool) -> void:
	status_label.text = "Pauzė – spausk Esc" if p else ""

func show_panel(station: Station) -> void:
	panel_station = station
	panel.visible = true
	refresh()

func hide_panel() -> void:
	panel.visible = false
	panel_station = null

# --- Callbacks -------------------------------------------------------------

func _on_overlay_pressed() -> void:
	game.start_game()

func _on_speed_pressed() -> void:
	game.upgrade_selected("speed")

func _on_capacity_pressed() -> void:
	game.upgrade_selected("capacity")

func flash_overflow() -> void:
	eco_flash = 1.0

# --- Per-frame refresh -----------------------------------------------------

func _process(delta: float) -> void:
	if eco_flash > 0.0:
		eco_flash = maxf(0.0, eco_flash - delta * 2.5)
		_update_eco_fill()

func refresh() -> void:
	if game == null:
		return

	score_label.text = "Taškai: %d" % game.score
	points_label.text = "Eco-taškai: %d" % game.eco_points
	loops_label.text = "Užbaigti ciklai: %d" % game.loops

	_update_eco_fill()

	for i in legend_labels.size():
		var st: Station = game.stations[i]
		legend_labels[i].text = "%d. %s  ·  L%d  ·  %.2f/s" % [
			i + 1, Pipeline.name_of(i), st.speed_level, st.process_rate,
		]

	_refresh_panel()

func _update_eco_fill() -> void:
	var frac := clampf(game.eco / game.ECO_START, 0.0, 1.0)
	eco_fill.size.x = maxf(0.0, (eco_width - 4.0) * frac)
	if frac > 0.5:
		eco_fill.color = Color(0.35, 0.8, 0.5, 1.0)
	elif frac > 0.25:
		eco_fill.color = Color(0.9, 0.75, 0.3, 1.0)
	else:
		eco_fill.color = Color(0.9, 0.35, 0.3, 1.0)
	if eco_flash > 0.0:
		eco_fill.color = eco_fill.color.lerp(Color(1.0, 0.3, 0.3), eco_flash)

func _refresh_panel() -> void:
	if not panel.visible or panel_station == null:
		return
	panel_title.text = Pipeline.name_of(panel_station.index)
	panel_title.add_theme_color_override("font_color", Pipeline.color_of(panel_station.index))
	panel_info.text = "Greitis: L%d  (%.2f/s)\nBuferis: L%d  (%d vietos)\nUžimta: %d" % [
		panel_station.speed_level, panel_station.process_rate,
		panel_station.cap_level, panel_station.capacity,
		panel_station.buffer.size(),
	]
	var sc := panel_station.speed_cost()
	var cc := panel_station.capacity_cost()
	speed_btn.text = "+ Greitis L%d  (%d)" % [panel_station.speed_level + 1, sc]
	speed_btn.disabled = game.eco_points < sc
	cap_btn.text = "+ Buferis L%d  (%d)" % [panel_station.cap_level + 1, cc]
	cap_btn.disabled = game.eco_points < cc
