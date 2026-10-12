## Hud
##
## Screen-space interface: money & statistics, pollution meter, year progress,
## market event / disaster banners, station table, the selected-station
## upgrade shop, action buttons, the yearly report with investment cards, the
## start screen (difficulty, tutorial) and the final screen. Hosts the
## tutorial and the sorting mini-game. Everything is built in code.
class_name Hud
extends CanvasLayer

const DESIGN_W := 1152.0
const DESIGN_H := 648.0
const KINDS := ["speed", "cap", "value"]
const BAR_W := 260.0
const FONT_PATH := "res://art/fonts/Nunito-Bold.ttf"
const FONT_BOLD_PATH := "res://art/fonts/Nunito-ExtraBold.ttf"

# Investment card categories -> colour + label
const CATEGORY := {
	"eco": {"label": "EKOLOGIJA", "color": Color(0.35, 0.8, 0.5)},
	"prod": {"label": "GAMYBA", "color": Color(0.45, 0.65, 1.0)},
	"fin": {"label": "FINANSAI", "color": Color(1.0, 0.78, 0.3)},
}

var game: Node

var font: Font
var bold: Font
var _root: Control
var _icons: Texture2D

var title_label: Label
var money_label: Label
var income_label: Label
var circ_label: Label
var loops_label: Label
var status_label: Label
var mute_btn: Button
var fs_btn: Button
var sound_panel: PanelContainer
var music_slider: HSlider
var sfx_slider: HSlider
var mute_check: CheckBox

var pol_label: Label
var pol_fill: ColorRect
var pol_flash: float = 0.0
var year_label: Label
var year_fill: ColorRect

var table: StationTable

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
var _recommended: String = ""
var _styled_for: Station = null
var _rec_badge: Label
var _blink_t: float = 0.0

var raw_btn: Button
var clean_btn: Button

var report: ColorRect
var report_title: Label
var report_tiles: Array[Label] = []
var report_goal: PanelContainer
var report_goal_label: Label
var card_btns: Array[Button] = []
var card_chip: Array[Label] = []
var card_title: Array[Label] = []
var card_desc: Array[Label] = []
var card_icons: Array[AnimIcon] = []

var overlay: ColorRect
var start_box: VBoxContainer
var final_box: VBoxContainer
var final_title: Label
var final_text: Label
var final_tiles: Array[Label] = []
var final_score_label: Label
var final_sub: Label
var diff_btns: Array[Button] = []
var tut_check: CheckBox
var best_label: Label
var selected_diff: int = 1

var tutorial: Tutorial
var sorting: Sorting

var _money_bump: float = 0.0

func setup(g: Node) -> void:
	game = g
	if ResourceLoader.exists("res://art/ikonos.png"):
		_icons = load("res://art/ikonos.png")
	_load_fonts()
	_build()

func _load_fonts() -> void:
	var old := ThemeDB.fallback_font
	if ResourceLoader.exists(FONT_PATH):
		var f: FontFile = load(FONT_PATH)
		f.fallbacks = [old]
		font = f
		ThemeDB.fallback_font = f
	else:
		font = old
	if ResourceLoader.exists(FONT_BOLD_PATH):
		var fb: FontFile = load(FONT_BOLD_PATH)
		fb.fallbacks = [old]
		bold = fb
	else:
		bold = font

# --- Construction ----------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font = font
	_root.theme = th
	add_child(_root)

	title_label = _label(_root, Vector2(20, 6), 26, Color(0.85, 0.92, 1.0))
	title_label.add_theme_font_override("font", bold)
	title_label.text = "Žiedinė ekonomika"
	money_label = _label(_root, Vector2(54, 40), 28, Color(1.0, 0.88, 0.45))
	money_label.add_theme_font_override("font", bold)
	income_label = _label(_root, Vector2(56, 76), 14, Color(0.75, 0.85, 0.7))
	circ_label = _label(_root, Vector2(50, 98), 17, Color(0.75, 0.95, 0.8))
	loops_label = _label(_root, Vector2(50, 124), 17, Color(0.8, 0.9, 1.0))
	status_label = _label(_root, Vector2(20, 152), 15, Color(0.95, 0.8, 0.4))
	_icon(0, Vector2(18, 45), 30)
	_icon(1, Vector2(21, 100), 22)
	_icon(2, Vector2(21, 126), 22)

	_build_bars()
	table = StationTable.new()
	table.setup(game, font, bold)
	table.position = Vector2(14, DESIGN_H - table.size.y - 12)
	_root.add_child(table)
	_build_event_banner()
	_build_alert()
	_build_panel()
	_build_buttons()
	_build_rec_badge()
	_build_report()
	_build_overlay()

func _style(bg: Color, border: Color, radius: int = 10, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
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
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))
	b.focus_mode = Control.FOCUS_NONE
	if not b.mouse_entered.is_connected(_hover_sound):
		b.mouse_entered.connect(_hover_sound)

func _hover_sound() -> void:
	Sfx.play("click", 0.1, 1.4)

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
	mute_btn = Button.new()
	mute_btn.position = Vector2(DESIGN_W - 20.0 - 150.0, 84)
	mute_btn.size = Vector2(150, 26)
	mute_btn.add_theme_font_size_override("font_size", 12)
	_button_styles(mute_btn, Color(0.5, 0.55, 0.7))
	mute_btn.pressed.connect(_toggle_sound_panel)
	_root.add_child(mute_btn)
	fs_btn = Button.new()
	fs_btn.size = Vector2(150, 26)
	fs_btn.add_theme_font_size_override("font_size", 12)
	_button_styles(fs_btn, Color(0.5, 0.55, 0.7))
	fs_btn.pressed.connect(func(): game.toggle_fullscreen())
	_root.add_child(fs_btn)
	refresh_fullscreen()
	_build_sound_panel()

func _toggle_mute() -> void:
	if Sfx.inst != null:
		Sfx.inst.set_muted(not Sfx.inst.muted)
	_refresh_mute()

func _build_sound_panel() -> void:
	sound_panel = PanelContainer.new()
	sound_panel.add_theme_stylebox_override("panel", _style(Color(0.08, 0.1, 0.15, 0.98), Color(0.5, 0.55, 0.7), 10))
	sound_panel.custom_minimum_size = Vector2(250, 0)
	sound_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	sound_panel.visible = false
	_root.add_child(sound_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	sound_panel.add_child(vb)
	var t := Label.new()
	t.text = "Garso nustatymai"
	t.add_theme_font_override("font", bold)
	t.add_theme_font_size_override("font_size", 15)
	vb.add_child(t)
	music_slider = _slider_row(vb, "Muzika")
	sfx_slider = _slider_row(vb, "Efektai")
	mute_check = CheckBox.new()
	mute_check.text = "Išjungti visą garsą (M)"
	mute_check.focus_mode = Control.FOCUS_NONE
	mute_check.add_theme_font_size_override("font_size", 13)
	mute_check.toggled.connect(func(on: bool):
		if Sfx.inst != null and Sfx.inst.muted != on:
			Sfx.inst.set_muted(on)
		_refresh_mute())
	vb.add_child(mute_check)
	if Sfx.inst != null:
		music_slider.set_value_no_signal(Sfx.inst.music_vol * 100.0)
		sfx_slider.set_value_no_signal(Sfx.inst.sfx_vol * 100.0)
	music_slider.value_changed.connect(func(v: float):
		if Sfx.inst != null:
			Sfx.inst.set_music_volume(v / 100.0)
		_refresh_mute())
	sfx_slider.value_changed.connect(func(v: float):
		if Sfx.inst != null:
			Sfx.inst.set_sfx_volume(v / 100.0)
			Sfx.play("coin", 0.0)
		_refresh_mute())

func _slider_row(parent: Control, title: String) -> HSlider:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	parent.add_child(hb)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(62, 0)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.78, 0.85, 0.95))
	hb.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 1
	sl.custom_minimum_size = Vector2(130, 24)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.2, 0.23, 0.3)
	track.set_corner_radius_all(4)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.8, 0.55)
	fill.set_corner_radius_all(4)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	hb.add_child(sl)
	return sl

func _toggle_sound_panel() -> void:
	Sfx.play("click")
	sound_panel.visible = not sound_panel.visible
	sound_panel.position = Vector2(mute_btn.position.x + mute_btn.size.x - 250.0, mute_btn.position.y + 32.0)

func refresh_fullscreen() -> void:
	var fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	fs_btn.text = "Langas (F11)" if fs else "Pilnas ekranas (F11)"

## Re-anchor everything to the current screen size (any aspect ratio).
func relayout(vp: Vector2) -> void:
	if pol_label == null:
		return
	var x := vp.x - 20.0 - BAR_W
	pol_label.position.x = x
	(pol_fill.get_parent() as Control).position.x = x
	year_label.position.x = x
	(year_fill.get_parent() as Control).position.x = x
	mute_btn.position = Vector2(vp.x - 20.0 - 150.0, 84)
	if sound_panel != null:
		sound_panel.position = Vector2(mute_btn.position.x + mute_btn.size.x - 250.0, mute_btn.position.y + 32.0)
	fs_btn.position = Vector2(vp.x - 20.0 - 150.0 - 8.0 - 150.0, 84)
	event_panel.position.x = vp.x * 0.5 - 210.0
	alert_panel.position = Vector2(vp.x * 0.5 - 170.0, vp.y * 0.5 - 34.0)
	panel.position.x = vp.x - 20.0 - maxf(310.0, panel.size.x)
	clean_btn.position = Vector2(vp.x - 330.0, vp.y - 136.0)
	raw_btn.position = Vector2(vp.x - 330.0, vp.y - 74.0)
	table.position = Vector2(14.0, vp.y - table.size.y - 12.0)

func _refresh_mute() -> void:
	var m := Sfx.inst != null and Sfx.inst.muted
	mute_btn.text = "Garsas: išjungtas" if m else "Garsas: %d %%" % int(Sfx.inst.sfx_vol * 100.0 if Sfx.inst != null else 0)
	if mute_check != null:
		mute_check.set_pressed_no_signal(m)

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
	event_title.add_theme_font_override("font", bold)
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
	alert_title.add_theme_font_override("font", bold)
	alert_desc = _center_label(vb, 13, Color(1.0, 0.9, 0.85))

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
	panel.position = Vector2(DESIGN_W - 330, 118)
	panel.custom_minimum_size = Vector2(310, 0)
	panel.size = Vector2(310, 0)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	_root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 21)
	panel_title.add_theme_font_override("font", bold)
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
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.custom_minimum_size = Vector2(196, 0)
		texts.add_child(n)
		var d := Label.new()
		d.add_theme_font_size_override("font_size", 12)
		d.add_theme_color_override("font_color", Color(0.72, 0.8, 0.9))
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(196, 0)
		texts.add_child(d)
		var b := Button.new()
		b.custom_minimum_size = Vector2(78, 40)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_font_override("font", bold)
		var kind: String = KINDS[i]
		b.pressed.connect(func(): game.upgrade_selected(kind))
		b.tooltip_text = Station.explain(kind)
		row.tooltip_text = Station.explain(kind)
		texts.tooltip_text = Station.explain(kind)
		texts.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(b)
		row_name.append(n)
		row_desc.append(d)
		row_btn.append(b)

func _build_rec_badge() -> void:
	_rec_badge = Label.new()
	_rec_badge.text = "APSIMOKA"
	_rec_badge.add_theme_font_override("font", bold)
	_rec_badge.add_theme_font_size_override("font_size", 11)
	_rec_badge.add_theme_color_override("font_color", Color(0.08, 0.2, 0.1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.55, 1.0, 0.6)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	_rec_badge.add_theme_stylebox_override("normal", sb)
	_rec_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rec_badge.z_index = 5
	_rec_badge.visible = false
	_root.add_child(_rec_badge)

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

# --- Yearly report ---------------------------------------------------------------

func _build_report() -> void:
	report = ColorRect.new()
	report.color = Color(0.02, 0.03, 0.05, 0.82)
	report.set_anchors_preset(Control.PRESET_FULL_RECT)
	report.mouse_filter = Control.MOUSE_FILTER_STOP
	report.visible = false
	_root.add_child(report)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	report.add_child(cc)
	var pc := PanelContainer.new()
	var psb := _style(Color(0.07, 0.09, 0.14, 0.98), Color(0.45, 0.65, 1.0), 18)
	psb.content_margin_left = 24
	psb.content_margin_right = 24
	psb.content_margin_top = 18
	psb.content_margin_bottom = 20
	psb.shadow_color = Color(0, 0, 0, 0.5)
	psb.shadow_size = 20
	pc.add_theme_stylebox_override("panel", psb)
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)

	report_title = _center_label(vb, 30, Color(0.88, 0.94, 1.0))
	report_title.add_theme_font_override("font", bold)

	# stat tiles
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(tiles)
	var tile_defs := [["PAJAMOS", Color(1.0, 0.85, 0.4)], ["Į SĄVARTYNĄ", Color(0.9, 0.65, 0.5)],
		["TARŠA", Color(1.0, 0.55, 0.45)], ["ŽIEDINUMAS", Color(0.55, 1.0, 0.65)]]
	for td in tile_defs:
		var t := PanelContainer.new()
		t.add_theme_stylebox_override("panel", _style(Color(0.12, 0.14, 0.2), Color(td[1], 0.35), 10, 1))
		t.custom_minimum_size = Vector2(150, 0)
		tiles.add_child(t)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		t.add_child(tv)
		var big := _center_label(tv, 26, td[1])
		big.add_theme_font_override("font", bold)
		var small := _center_label(tv, 11, Color(0.65, 0.72, 0.82))
		small.text = td[0]
		report_tiles.append(big)

	# EU goal badge
	var gc := CenterContainer.new()
	vb.add_child(gc)
	report_goal = PanelContainer.new()
	gc.add_child(report_goal)
	report_goal_label = Label.new()
	report_goal_label.add_theme_font_size_override("font_size", 16)
	report_goal_label.add_theme_font_override("font", bold)
	report_goal.add_child(report_goal_label)

	var sep := HSeparator.new()
	vb.add_child(sep)
	var pick := _center_label(vb, 15, Color(0.8, 0.86, 0.95))
	pick.text = "Pasirink VIENĄ investiciją ateinantiems metams:"

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 205)
		b.focus_mode = Control.FOCUS_NONE
		var idx := i
		b.pressed.connect(func(): Sfx.play("card", 0.0); game.choose_card(idx))
		b.mouse_entered.connect(_hover_sound)
		hb.add_child(b)
		var m := MarginContainer.new()
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_right", 12)
		m.add_theme_constant_override("margin_top", 10)
		m.add_theme_constant_override("margin_bottom", 10)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(m)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(cv)
		var chip := Label.new()
		chip.add_theme_font_size_override("font_size", 11)
		chip.add_theme_font_override("font", bold)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(chip)
		var ic := AnimIcon.new()
		ic.custom_minimum_size = Vector2(64, 64)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(ic)
		var tl := Label.new()
		tl.add_theme_font_size_override("font_size", 19)
		tl.add_theme_font_override("font", bold)
		tl.add_theme_color_override("font_color", Color.WHITE)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(186, 0)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(tl)
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(186, 2)
		line.color = Color(1, 1, 1, 0.15)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(line)
		var dl := Label.new()
		dl.add_theme_font_size_override("font_size", 14)
		dl.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(186, 0)
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(dl)
		card_icons.append(ic)
		card_btns.append(b)
		card_chip.append(chip)
		card_title.append(tl)
		card_desc.append(dl)

# --- Start / final overlay -------------------------------------------------------

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.03, 0.05, 0.86)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var holder := VBoxContainer.new()
	cc.add_child(holder)

	# Start screen
	start_box = VBoxContainer.new()
	start_box.add_theme_constant_override("separation", 12)
	holder.add_child(start_box)
	var t := _center_label(start_box, 50, Color(0.85, 0.95, 1.0))
	t.add_theme_font_override("font", bold)
	t.text = "Žiedinė ekonomika"
	var st := _center_label(start_box, 17, Color(0.65, 0.9, 0.7))
	st.text = "Valdyk žiedinės ekonomikos įmonių grandinę 10 metų – uždirbk ir neleisk planetai užsidegti"
	var how := _center_label(start_box, 14, Color(0.75, 0.82, 0.92))
	how.text = ("Spausk stotis – rankinis darbas  •  Pirk patobulinimus  •  Gaudyk € monetas  •  Rūšiuok atliekas\n"
		+ "Tarpas – nauja žaliava  •  V – valymas  •  Esc – pauzė  •  M – garsas  •  F11 – pilnas ekranas")
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	start_box.add_child(sp)
	var dl := _center_label(start_box, 15, Color(1.0, 0.85, 0.45))
	dl.add_theme_font_override("font", bold)
	dl.text = "SUNKUMO LYGIS"
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 12)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	start_box.add_child(dh)
	var diffs: Array = game.DIFFICULTIES
	for i in diffs.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 92)
		b.add_theme_font_size_override("font_size", 14)
		b.text = "%s\n%s" % [diffs[i]["title"], diffs[i]["desc"]]
		var idx := i
		b.pressed.connect(func(): Sfx.play("click"); _select_diff(idx))
		dh.add_child(b)
		diff_btns.append(b)
	var cc2 := CenterContainer.new()
	start_box.add_child(cc2)
	tut_check = CheckBox.new()
	tut_check.text = "Rodyti vedlį (pirmam kartui)"
	tut_check.focus_mode = Control.FOCUS_NONE
	tut_check.add_theme_font_size_override("font_size", 14)
	tut_check.button_pressed = not bool(Settings.get_value("tutorial_done", false))
	cc2.add_child(tut_check)
	var cc3 := CenterContainer.new()
	start_box.add_child(cc3)
	var go := Button.new()
	go.custom_minimum_size = Vector2(260, 56)
	go.add_theme_font_size_override("font_size", 22)
	go.add_theme_font_override("font", bold)
	go.text = "PRADĖTI"
	_button_styles(go, Color(0.35, 0.8, 0.5))
	go.pressed.connect(_on_start_pressed)
	cc3.add_child(go)
	best_label = _center_label(start_box, 13, Color(0.6, 0.68, 0.8))
	_select_diff(int(Settings.get_value("difficulty", 1)))

	# Final screen
	final_box = VBoxContainer.new()
	final_box.add_theme_constant_override("separation", 14)
	final_box.visible = false
	holder.add_child(final_box)
	final_sub = _center_label(final_box, 16, Color(0.65, 0.9, 0.7))
	final_title = _center_label(final_box, 40, Color(1.0, 0.88, 0.45))
	final_title.add_theme_font_override("font", bold)
	var ftiles := HBoxContainer.new()
	ftiles.add_theme_constant_override("separation", 10)
	ftiles.alignment = BoxContainer.ALIGNMENT_CENTER
	final_box.add_child(ftiles)
	var fdefs := [["UŽDIRBTA", Color(1.0, 0.85, 0.4)], ["CIKLŲ", Color(0.6, 0.8, 1.0)],
		["ŽIEDINUMAS", Color(0.55, 1.0, 0.65)], ["TARŠA", Color(1.0, 0.55, 0.45)], ["SĄVARTYNE", Color(0.9, 0.65, 0.5)]]
	for td in fdefs:
		var t2 := PanelContainer.new()
		t2.add_theme_stylebox_override("panel", _style(Color(0.12, 0.14, 0.2), Color(td[1], 0.35), 10, 1))
		t2.custom_minimum_size = Vector2(138, 0)
		ftiles.add_child(t2)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		t2.add_child(tv)
		var big := _center_label(tv, 24, td[1])
		big.add_theme_font_override("font", bold)
		var small := _center_label(tv, 11, Color(0.65, 0.72, 0.82))
		small.text = td[0]
		final_tiles.append(big)
	final_score_label = _center_label(final_box, 30, Color(1, 1, 1))
	final_score_label.add_theme_font_override("font", bold)
	final_text = _center_label(final_box, 14, Color(0.75, 0.82, 0.92))
	final_text.custom_minimum_size = Vector2(760, 0)
	final_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cc4 := CenterContainer.new()
	final_box.add_child(cc4)
	var again := Button.new()
	again.custom_minimum_size = Vector2(260, 52)
	again.add_theme_font_size_override("font_size", 20)
	again.add_theme_font_override("font", bold)
	again.text = "Žaisti dar kartą"
	_button_styles(again, Color(0.35, 0.8, 0.5))
	again.pressed.connect(func(): show_start_overlay())
	cc4.add_child(again)

func _select_diff(i: int) -> void:
	selected_diff = clampi(i, 0, diff_btns.size() - 1)
	var cols := [Color(0.35, 0.8, 0.5), Color(0.45, 0.65, 1.0), Color(0.95, 0.45, 0.35)]
	for k in diff_btns.size():
		var c: Color = cols[k]
		var b := diff_btns[k]
		if k == selected_diff:
			b.add_theme_stylebox_override("normal", _style(c.darkened(0.3), Color.WHITE, 10, 3))
			b.add_theme_stylebox_override("hover", _style(c.darkened(0.25), Color.WHITE, 10, 3))
		else:
			b.add_theme_stylebox_override("normal", _style(c.darkened(0.7), c.darkened(0.3), 10))
			b.add_theme_stylebox_override("hover", _style(c.darkened(0.55), c, 10))
		b.add_theme_stylebox_override("pressed", _style(c.darkened(0.2), Color.WHITE, 10, 3))
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.focus_mode = Control.FOCUS_NONE

func _on_start_pressed() -> void:
	Sfx.play("card", 0.0)
	Settings.set_value("difficulty", selected_diff)
	game.start_game(selected_diff, tut_check.button_pressed)

func show_start_overlay() -> void:
	overlay.visible = true
	start_box.visible = true
	final_box.visible = false
	tut_check.button_pressed = not bool(Settings.get_value("tutorial_done", false))
	var best := int(Settings.get_value("best_score", 0))
	best_label.text = "Tavo rekordas: %d" % best if best > 0 else ""
	_refresh_mute()

# --- Overlays / panels -------------------------------------------------------

func show_report(s: Dictionary, cards: Array) -> void:
	hide_panel()
	report.visible = true
	report_title.text = "%d-ųjų metų ataskaita" % int(s["year"])
	report_tiles[0].text = "€%d" % int(s["earned"])
	report_tiles[1].text = "%d vnt." % int(s["landfill"])
	report_tiles[2].text = "%d %%" % int(s["pollution"])
	report_tiles[3].text = "%d %%" % int(s["circ"])
	if bool(s["met"]):
		report_goal_label.text = "ES žiedinumo tikslas %d %% – PASIEKTAS!   Premija +€%d" % [int(s["target"]), int(s["reward"])]
		report_goal_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65))
		report_goal.add_theme_stylebox_override("panel", _style(Color(0.1, 0.25, 0.14), Color(0.4, 0.9, 0.5), 20))
	else:
		report_goal_label.text = "ES žiedinumo tikslas %d %% – NEPASIEKTAS.   Bauda -€%d" % [int(s["target"]), int(-float(s["reward"]))]
		report_goal_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.6))
		report_goal.add_theme_stylebox_override("panel", _style(Color(0.28, 0.08, 0.07), Color(1.0, 0.45, 0.4), 20))
	for i in card_btns.size():
		if i < cards.size():
			var cat: Dictionary = CATEGORY.get(str(cards[i].get("cat", "fin")), CATEGORY["fin"])
			var c: Color = cat["color"]
			card_btns[i].visible = true
			card_btns[i].add_theme_stylebox_override("normal", _style(c.darkened(0.72), c.darkened(0.25), 12, 2))
			card_btns[i].add_theme_stylebox_override("hover", _style(c.darkened(0.55), c.lightened(0.2), 12, 3))
			card_btns[i].add_theme_stylebox_override("pressed", _style(c.darkened(0.4), Color.WHITE, 12, 3))
			card_chip[i].text = "● " + str(cat["label"])
			card_chip[i].add_theme_color_override("font_color", c)
			card_title[i].text = str(cards[i]["title"])
			card_icons[i].set_sheet("res://art/kortos/%s.png" % str(cards[i]["id"]))
			card_desc[i].text = str(cards[i]["desc"]).replace("\n", " ")
		else:
			card_btns[i].visible = false

func hide_report() -> void:
	if report != null:
		report.visible = false

func show_final(s: Dictionary) -> void:
	hide_panel()
	hide_event()
	overlay.visible = true
	start_box.visible = false
	final_box.visible = true
	final_title.text = game.final_title()
	final_sub.text = "ŽAIDIMAS BAIGTAS" if bool(s.get("lost", false)) else "10 metų baigėsi! Tavo įmonės titulas:"
	var score: int = game.final_score()
	var best := int(Settings.get_value("best_score", 0))
	final_tiles[0].text = "€%d" % int(game.total_earned)
	final_tiles[1].text = str(game.loops)
	final_tiles[2].text = "%d %%" % int(game.circularity())
	final_tiles[3].text = "%d %%" % int(game.pollution)
	final_tiles[4].text = "%d vnt." % game.landfilled
	if score > best:
		Settings.set_value("best_score", score)
		final_score_label.text = "Rezultatas: %d  –  naujas rekordas!" % score
		final_score_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	else:
		final_score_label.text = "Rezultatas: %d   (rekordas: %d)" % [score, best]
		final_score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	if bool(s.get("lost", false)):
		final_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		var why := "Tarša per ilgai laikėsi 100 % – ekosistema žlugo." if game.lost_reason == "planet" \
			else "Skolos viršijo €%d – bankas uždarė įmonę." % int(-game.BANKRUPT_AT)
		final_text.text = ("Įmonė žlugo %d-aisiais metais. %s\n"
			+ "Kadangi įmonė žlugo, rezultatas sumažintas perpus. Sunkumas: %s.") % [
			game.year, why, game.DIFFICULTIES[game.difficulty]["title"]]
		return
	final_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	var goal := "pasiektas" if bool(s["met"]) else "nepasiektas"
	final_text.text = ("Sunkumas: %s.  Paskutinių metų ES tikslas %s.\n"
		+ "Rezultatą lemia uždirbti pinigai, planetos būklė ir žiedinumo rodiklis – turtas ant užterštos planetos vertas mažiau.") % [
		game.DIFFICULTIES[game.difficulty]["title"], goal]

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
	_styled_for = null
	_recommended = ""
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

# --- Tutorial & sorting --------------------------------------------------------

func start_tutorial() -> void:
	if tutorial != null and is_instance_valid(tutorial):
		tutorial.queue_free()
	tutorial = Tutorial.new()
	_root.add_child(tutorial)
	tutorial.setup(game, self, font, bold)
	tutorial.done.connect(func(): game.tutorial_finished())

func tutorial_notify(what: String) -> void:
	if tutorial != null and is_instance_valid(tutorial):
		tutorial.notify(what)

func open_sorting(count: int) -> Sorting:
	sorting = Sorting.new()
	_root.add_child(sorting)
	sorting.open(game, count, font, bold)
	return sorting

# --- Money feedback ---------------------------------------------------------------

## Screen position the flying coins head to.
func money_target() -> Vector2:
	return Vector2(33, 60)

func bump_money() -> void:
	_money_bump = 1.0
	Sfx.play("coin", 0.04)

# --- Callbacks -------------------------------------------------------------

func flash_overflow() -> void:
	pol_flash = 1.0

# --- Per-frame refresh -----------------------------------------------------

func _process(delta: float) -> void:
	_blink_t += delta
	if panel != null and panel.visible:
		var any := false
		for i in KINDS.size():
			var on: bool = KINDS[i] == _recommended and not row_btn[i].disabled
			var pulse := 0.5 + 0.5 * sin(_blink_t * 7.0)
			var k := 1.0 + (0.35 * pulse if on else 0.0)
			row_btn[i].self_modulate = Color(k, k, k, 1.0)
			row_btn[i].pivot_offset = row_btn[i].size * 0.5
			var sc := 1.0 + (0.08 * pulse if on else 0.0)
			row_btn[i].scale = Vector2(sc, sc)
			if on:
				any = true
				_rec_badge.visible = true
				_rec_badge.global_position = row_btn[i].global_position + Vector2(row_btn[i].size.x * 0.5 - _rec_badge.size.x * 0.5, -14.0)
		if not any:
			_rec_badge.visible = false
	elif _rec_badge != null:
		_rec_badge.visible = false
	if pol_flash > 0.0:
		pol_flash = maxf(0.0, pol_flash - delta * 2.5)
		_update_bars()
	if alert_time > 0.0:
		alert_time -= delta
		if alert_time <= 0.0:
			alert_panel.visible = false
	if _money_bump > 0.0:
		_money_bump = maxf(0.0, _money_bump - delta * 4.0)
		money_label.pivot_offset = Vector2(0, money_label.size.y * 0.5)
		var k := 1.0 + 0.18 * _money_bump
		money_label.scale = Vector2(k, k)

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_M:
			_toggle_mute()
		elif ev.keycode == KEY_F11 or (ev.keycode == KEY_ENTER and ev.alt_pressed):
			game.toggle_fullscreen()
			get_viewport().set_input_as_handled()

func refresh() -> void:
	if game == null:
		return

	money_label.text = "€ %d" % int(floor(game.money))
	money_label.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.45) if game.money >= 0.0 else Color(1.0, 0.45, 0.4))
	if game.money < 0.0:
		income_label.text = "Skolos! Bankrotas, kai skola pasieks €%d" % int(-game.BANKRUPT_AT)
		income_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
	else:
		income_label.text = "Pajamos: €%d / min" % int(game.income_per_min())
		income_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.7))
	circ_label.text = "Žiedinumas: %d %%" % int(game.circularity())
	loops_label.text = "Užbaigti ciklai: %d" % game.loops

	_update_bars()

	var rp: float = game.raw_price()
	raw_btn.text = "Pirkti naują žaliavą – €%d   [Tarpas]\nGreita, bet teršia ir mažina žiedinumą" % int(round(rp))
	raw_btn.disabled = game.money < rp or not game.running
	var cp: float = game.cleanup_price()
	clean_btn.text = "Valyti aplinką – €%d   [V]\nTarša -%d %%, kitas valymas bus brangesnis" % [int(cp), int(game.CLEANUP_AMOUNT)]
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
	panel.position.x = get_viewport().get_visible_rect().size.x - 20.0 - maxf(310.0, panel.size.x)
	panel_fact.visible = get_viewport().get_visible_rect().size.y >= 760.0
	var st := panel_station
	var accent := Pipeline.color_of(st.index)
	panel_title.text = "%d. %s" % [st.index + 1, Pipeline.name_of(st.index)]
	panel_title.add_theme_color_override("font_color", accent.lightened(0.15))
	panel_fact.text = Pipeline.fact_of(st.index)
	var rec: String = game.recommend(st)
	if rec != _recommended or st != _styled_for:
		_recommended = rec
		_styled_for = st
		for j in KINDS.size():
			if KINDS[j] == _recommended:
				_button_styles(row_btn[j], Color(0.3, 0.95, 0.45))
				row_btn[j].add_theme_stylebox_override("normal", _style(Color(0.18, 0.62, 0.3), Color(0.75, 1.0, 0.8), 8, 3))
				row_btn[j].add_theme_stylebox_override("hover", _style(Color(0.22, 0.72, 0.36), Color.WHITE, 8, 3))
			else:
				_button_styles(row_btn[j], Pipeline.color_of(st.index))
	for i in KINDS.size():
		var kind: String = KINDS[i]
		var lvl := st.level_of(kind)
		var best := kind == _recommended
		row_name[i].text = Pipeline.upgrade_name(st.index, kind)
		row_name[i].add_theme_color_override("font_color", Color(0.55, 1.0, 0.6) if best else Color(0.95, 0.97, 1.0))
		if st.is_maxed(kind):
			row_desc[i].text = "Lygis %d/%d – maksimalus" % [lvl, Station.MAX_LEVEL]
			row_btn[i].text = "MAX"
			row_btn[i].disabled = true
		else:
			var cost := st.cost_of(kind)
			row_desc[i].text = "Lygis %d → %d.  %s" % [lvl, lvl + 1, st.preview(kind)]
			row_btn[i].text = "€%d" % cost
			row_btn[i].disabled = game.money < cost
