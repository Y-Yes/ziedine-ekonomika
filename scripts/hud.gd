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
var pause_layer: ColorRect
var pause_main: VBoxContainer
var pause_gloss: VBoxContainer
var qr_layer: ColorRect
var gloss_popup: PanelContainer
var gloss_title: Label
var gloss_text: Label
var gloss_time: float = 0.0
var music_slider: HSlider
var sfx_slider: HSlider
var mute_check: CheckBox

var pol_label: Label
var pol_fill: HudBar
var top_card: Panel
var stats_card: Panel
var pol_flash: float = 0.0
var year_label: Label
var year_fill: HudBar

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
const SECRET_DIFF := 3
# Learning mode UI
var learn_check: CheckBox
var learn_badge: Label
var lesson_dim: ColorRect
var lesson_box: VBoxContainer
var lesson_head: Label
var lesson_title: Label
var lesson_secs: Array[Label] = []
var lesson_next: Button
var quiz_box: VBoxContainer
var quiz_q: Label
var quiz_btns: Array[Button] = []
var quiz_feedback: Label
var quiz_next: Button
var _lessons_shown: Array[String] = []
var _lesson_queue: Array[String] = []
var _lesson_id: String = ""
var _end_summary: Dictionary = {}
var _quiz_i: int = 0
var _quiz_score: int = 0
var _quiz_answered: bool = false
var _learning_ending: bool = false
var _mid_quiz: bool = false
var quiz_done: bool = false
var _pending_start: bool = false
var _intro_shown_once: bool = false
# Guide tips for first-time situations (fire, strike, sorting…)
var coach_node: Coach
var _coach_on: bool = false
var _coach_seen: Array[String] = []
var _coach_queue: Array = []   # "how to play" before a teaching game: only the first time
var intro_box: VBoxContainer

## "How to play" cards shown on first launch (and from the start screen).
const INTRO_CARDS := [
	["1. TIKSLAS", "Vadovauji 6 įmonėms, kurios sudaro žiedinės ekonomikos ratą. Žaidimas trunka 10 metų (vieni metai – apie 1 minutę). Uždirbk kuo daugiau, bet saugok planetą: geriausias rezultatas – turtinga IR švari įmonė.", Color(0.45, 0.85, 1.0)],
	["2. KAIP JUDA DAIKTAI", "Daiktas keliauja ratu: Naudotojas → Surinkimas → Rūšiavimas → Perdirbimas → Gamykla → Parduotuvė → ir vėl pas Naudotoją. Kiekviena stotis prideda vertės, o pardavus produktą gauni pinigų.", Color(0.55, 1.0, 0.6)],
	["3. KĄ TU DARAI", "Spausk stotį – ji padirba greičiau (kuo daugiau spaudai, tuo greičiau). Pirk patobulinimus: greitį, sandėlį ir vertę. Gaudyk skraidančias € monetas, o mišrias atliekas rūšiuok – tempk daiktą į tinkamą konteinerį.", Color(1.0, 0.85, 0.4)],
	["4. PAVOJAI", "Kai stoties sandėlis prisipildo, daiktai iškrenta į sąvartyną ir didėja tarša. Tarša mažina kainas ir sukelia nelaimes: gaisrus, potvynius, streikus. Jei tarša 100 % laikosi 15 s – planeta sprogsta. Skola didesnė nei €150 – bankrotas.", Color(1.0, 0.5, 0.4)],
	["5. EKONOMIKA", "Kasmet ES tikrina, ar pasiekei žiedinumo tikslą – jei ne, moki baudą. Metų pabaigoje renkiesi vieną iš trijų investicijų, o kitų atsisakai (alternatyvieji kaštai). Nauja žaliava (Tarpas) – greita, bet teršia: tai linijinė ekonomika.", Color(0.75, 0.6, 1.0)],
	["6. VALDYMAS", "Pelė – spaudyti stotis ir pirkti patobulinimus.\nTarpas – nupirkti naują žaliavą.\nV – išvalyti aplinką.\nEsc – meniu, garsas, sąvokų žodynas.", Color(0.7, 0.8, 0.92)],
]
var secret_label: Label
var secret_btn: Button

var tutorial: Tutorial
var sorting: Sorting

var _money_bump: float = 0.0
var _chk_off: ImageTexture
var _chk_on: ImageTexture

func setup(g: Node) -> void:
	game = g
	if ResourceLoader.exists("res://art/ikonos.png"):
		_icons = load("res://art/ikonos.png")
	_load_fonts()
	_build()

const SYMBOL_FONT_PATH := "res://art/fonts/Simboliai.ttf"

func _load_fonts() -> void:
	var old := ThemeDB.fallback_font
	# Symbols missing from Nunito (arrows, stars, check marks…) come from a
	# small bundled DejaVu subset, so they also work in the web version.
	var sym: Font = load(SYMBOL_FONT_PATH) if ResourceLoader.exists(SYMBOL_FONT_PATH) else null
	if ResourceLoader.exists(FONT_PATH):
		var f: FontFile = load(FONT_PATH)
		f.fallbacks = [sym, old] if sym != null else [old]
		font = f
		ThemeDB.fallback_font = f
	else:
		font = old
	if ResourceLoader.exists(FONT_BOLD_PATH):
		var fb: FontFile = load(FONT_BOLD_PATH)
		fb.fallbacks = [sym, old] if sym != null else [old]
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

	# (the game title is shown on the start screen only, not during play)
	stats_card = Panel.new()
	stats_card.add_theme_stylebox_override("panel", _style(Color(0.07, 0.09, 0.13, 0.8), Color(0.3, 0.38, 0.5), 10, 1))
	stats_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_card.position = Vector2(8, 8)
	stats_card.size = Vector2(232, 112)
	_root.add_child(stats_card)
	money_label = _label(_root, Vector2(54, 10), 28, Color(1.0, 0.88, 0.45))
	money_label.add_theme_font_override("font", bold)
	income_label = _label(_root, Vector2(56, 46), 14, T_MUTED)
	circ_label = _label(_root, Vector2(50, 68), 17, T_TEXT)
	loops_label = _label(_root, Vector2(50, 94), 17, T_TEXT)
	status_label = _label(_root, Vector2(14, 126), 15, Color(0.95, 0.8, 0.4))
	_icon(0, Vector2(18, 15), 30)
	_icon(1, Vector2(21, 70), 22)
	_icon(2, Vector2(21, 96), 22)

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
	_build_glossary_popup()
	_build_overlay()
	_build_pause_menu()
	_build_lessons()
	_build_qr()

## Menu-only QR entry points. Preserve the original image's white quiet zone
## against a translucent scrim and keep the underlying menu intact.
func _build_qr() -> void:
	for menu in [overlay, pause_layer]:
		var entry := Button.new()
		entry.text = "QR"
		entry.tooltip_text = Loc.t("Rodyti QR kodą")
		menu.add_child(entry)
		entry.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		entry.offset_left = -100
		entry.offset_top = -60
		entry.offset_right = -20
		entry.offset_bottom = -20
		entry.add_theme_font_size_override("font_size", 18)
		_button_styles(entry)
		entry.pressed.connect(func():
			Sfx.play("click")
			qr_layer.show()
		)
	qr_layer = ColorRect.new()
	qr_layer.color = Color(0.02, 0.03, 0.05, 0.65)
	qr_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	qr_layer.z_index = 100
	_root.add_child(qr_layer)
	qr_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	qr_layer.hide()
	var code := TextureRect.new()
	code.texture = load("res://art/qr_kodas.png")
	code.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	code.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	code.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	code.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qr_layer.add_child(code)
	code.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	code.offset_left = 16
	code.offset_right = -16
	code.offset_top = 68
	code.offset_bottom = -16
	var close := Button.new()
	close.text = Loc.t("Uždaryti") + " (Esc)"
	qr_layer.add_child(close)
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -200
	close.offset_top = 12
	close.offset_right = -16
	close.offset_bottom = 56
	close.add_theme_font_size_override("font_size", 16)
	_button_styles(close)
	close.pressed.connect(func(): Sfx.play("click"); qr_layer.hide())

# --- Theme -----------------------------------------------------------------
# One look for every window: dark glass surfaces, thin light borders, one blue
# accent for actions and highlights, green / red / gold only for meaning.
const T_SURF := Color(0.045, 0.065, 0.105)
const T_RAISED := Color(0.09, 0.13, 0.19)
const T_LINE := Color(0.55, 0.7, 0.9, 0.34)
const T_TEXT := Color(0.93, 0.95, 0.98)
const T_MUTED := Color(0.64, 0.7, 0.79)
const T_ACC := Color(0.45, 0.74, 1.0)
const T_ACC_FILL := Color(0.22, 0.5, 0.88)
const T_GOOD := Color(0.42, 0.88, 0.58)
const T_BAD := Color(1.0, 0.5, 0.45)
const T_GOLD := Color(1.0, 0.85, 0.45)

## Glass surface. The colours passed in are only hints: the fill is always the
## theme surface; a wide border (bw >= 3) means "highlighted" and keeps its colour.
func _style(bg: Color, border: Color, radius: int = 10, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(T_SURF, clampf(bg.a, 0.6, 0.94))
	if bw >= 3:
		sb.border_color = Color(border, 0.95)
		sb.set_border_width_all(2)
	else:
		sb.border_color = T_LINE
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(clampi(radius, 10, 16))
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

## Callout: surface with a coloured stripe on the left (events, alerts, tips).
func _callout(c: Color) -> StyleBoxFlat:
	var sb := _style(Color(0, 0, 0, 0.92), T_LINE, 10, 1)
	sb.border_color = Color(c, 0.75)
	sb.set_border_width_all(1)
	sb.border_width_left = 4
	sb.content_margin_left = 16
	return sb

func _btn_box(bg: Color, border: Color, bw: int = 1) -> StyleBoxFlat:
	var sb := _style(Color(0, 0, 0, bg.a), border, 10, 1)
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb

func _btn_fonts(b: Button, c: Color) -> void:
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, c)
	b.add_theme_color_override("font_disabled_color", Color(T_MUTED, 0.55))
	b.focus_mode = Control.FOCUS_NONE
	if not b.mouse_entered.is_connected(_hover_sound):
		b.mouse_entered.connect(_hover_sound)

## Secondary button (most buttons). `accent` is kept for old calls but the look
## is the same everywhere; only the hover border lights up in the theme accent.
func _button_styles(b: Button, _accent: Color = T_ACC) -> void:
	b.add_theme_stylebox_override("normal", _btn_box(Color(T_RAISED, 0.92), T_LINE))
	b.add_theme_stylebox_override("hover", _btn_box(Color(T_RAISED.lightened(0.08), 0.96), Color(T_ACC, 0.75)))
	b.add_theme_stylebox_override("pressed", _btn_box(Color(T_ACC_FILL.darkened(0.35), 0.96), T_ACC))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(Color(T_ACC_FILL.darkened(0.3), 0.96), T_ACC))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(T_SURF, 0.6), Color(T_LINE, 0.08)))
	_btn_fonts(b, T_TEXT)

## Main action of a window (Start, Continue, Next…): filled accent.
func _primary_styles(b: Button) -> void:
	b.add_theme_stylebox_override("normal", _btn_box(T_ACC_FILL, T_ACC_FILL.lightened(0.2)))
	b.add_theme_stylebox_override("hover", _btn_box(T_ACC_FILL.lightened(0.12), T_ACC.lightened(0.3)))
	b.add_theme_stylebox_override("pressed", _btn_box(T_ACC_FILL.darkened(0.15), T_ACC))
	b.add_theme_stylebox_override("hover_pressed", _btn_box(T_ACC_FILL.darkened(0.1), T_ACC))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(T_SURF, 0.6), Color(T_LINE, 0.08)))
	_btn_fonts(b, Color.WHITE)
	b.add_theme_font_override("font", bold)

## Button that shows a state with colour (right/wrong answer, best buy, danger).
func _tinted_button(b: Button, c: Color) -> void:
	b.add_theme_stylebox_override("normal", _btn_box(Color(c.darkened(0.55), 0.55), Color(c, 0.85), 2))
	b.add_theme_stylebox_override("hover", _btn_box(Color(c.darkened(0.45), 0.7), c, 2))
	b.add_theme_stylebox_override("pressed", _btn_box(Color(c.darkened(0.35), 0.8), Color.WHITE, 2))
	b.add_theme_stylebox_override("disabled", _btn_box(Color(c.darkened(0.6), 0.45), Color(c, 0.6), 2))
	_btn_fonts(b, T_TEXT)
	b.add_theme_color_override("font_disabled_color", T_TEXT)

## Danger button (leave game): secondary look, red on hover.
func _danger_styles(b: Button) -> void:
	_button_styles(b)
	b.add_theme_stylebox_override("hover", _btn_box(Color(T_BAD.darkened(0.7), 0.9), Color(T_BAD, 0.8)))
	b.add_theme_color_override("font_hover_color", T_BAD.lightened(0.2))

## Visible check-box icons for the dark theme.
func _style_check(c: CheckBox) -> void:
	if _chk_off == null:
		_chk_off = _check_icon(false)
		_chk_on = _check_icon(true)
	c.add_theme_icon_override("unchecked", _chk_off)
	c.add_theme_icon_override("checked", _chk_on)
	c.add_theme_icon_override("unchecked_disabled", _chk_off)
	c.add_theme_icon_override("checked_disabled", _chk_on)

func _check_icon(on: bool) -> ImageTexture:
	var n := 20
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			var border := x < 2 or y < 2 or x >= n - 2 or y >= n - 2
			if border:
				img.set_pixel(x, y, Color(0.75, 0.82, 0.92))
			elif on:
				img.set_pixel(x, y, T_ACC_FILL)
			else:
				img.set_pixel(x, y, Color(0.12, 0.14, 0.2))
	if on:
		var pts := [Vector2(5, 10), Vector2(8, 13), Vector2(15, 6)]
		for i in 2:
			for k in 20:
				var p: Vector2 = pts[i].lerp(pts[i + 1], float(k) / 19.0)
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						var xx: int = int(p.x) + int(dx)
						var yy: int = int(p.y) + int(dy)
						if xx >= 0 and yy >= 0 and xx < n and yy < n:
							img.set_pixel(xx, yy, Color.WHITE)
	return ImageTexture.create_from_image(img)

func _hover_sound() -> void:
	Sfx.play("click", 0.1, 1.4)

func _bar(pos: Vector2, h: float, mode: String) -> HudBar:
	var b := HudBar.new()
	b.mode = mode
	b.position = pos
	b.size = Vector2(BAR_W, h)
	_root.add_child(b)
	return b

func _build_bars() -> void:
	var x := DESIGN_W - 20.0 - BAR_W
	top_card = Panel.new()
	var cs := _style(Color(0.07, 0.09, 0.13, 0.8), Color(0.3, 0.38, 0.5), 10, 1)
	top_card.add_theme_stylebox_override("panel", cs)
	top_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_card.position = Vector2(x - 14.0, 8)
	top_card.size = Vector2(BAR_W + 28.0, 76)
	_root.add_child(top_card)
	pol_label = _label(_root, Vector2(x, 12), 15, T_TEXT)
	pol_fill = _bar(Vector2(x, 36), 10, "gradient")
	year_label = _label(_root, Vector2(x, 50), 14, T_TEXT)
	year_fill = _bar(Vector2(x, 72), 6, "segments")
	year_fill.color = Color(0.5, 0.7, 1.0)
	# Menu button (Esc) – sound, language, fullscreen and glossary live there.
	mute_btn = Button.new()
	mute_btn.position = Vector2(DESIGN_W - 20.0 - 150.0, 90)
	mute_btn.size = Vector2(150, 26)
	mute_btn.text = Loc.t("Meniu (Esc)")
	mute_btn.add_theme_font_size_override("font_size", 12)
	_button_styles(mute_btn, Color(0.5, 0.55, 0.7))
	mute_btn.pressed.connect(func(): game.toggle_pause())
	_root.add_child(mute_btn)

func _toggle_mute() -> void:
	if Sfx.inst != null:
		Sfx.inst.set_muted(not Sfx.inst.muted)
	_refresh_mute()

# --- Pause menu ------------------------------------------------------------------

func _menu_button(parent: Control, text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 40)
	b.add_theme_font_size_override("font_size", 16)
	_button_styles(b, accent)
	b.pressed.connect(func(): Sfx.play("click"); cb.call())
	parent.add_child(b)
	return b

func _build_pause_menu() -> void:
	pause_layer = ColorRect.new()
	pause_layer.color = Color(0.02, 0.03, 0.06, 0.72)
	pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_layer.visible = false
	_root.add_child(pause_layer)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(cc)
	var pc := PanelContainer.new()
	var psb := _style(Color(0.07, 0.09, 0.14, 0.98), Color(0.5, 0.6, 0.85), 16)
	psb.content_margin_left = 22
	psb.content_margin_right = 22
	psb.content_margin_top = 16
	psb.content_margin_bottom = 18
	pc.add_theme_stylebox_override("panel", psb)
	cc.add_child(pc)

	# main page
	pause_main = VBoxContainer.new()
	pause_main.add_theme_constant_override("separation", 8)
	pc.add_child(pause_main)
	var t := _center_label(pause_main, 28, T_TEXT)
	t.add_theme_font_override("font", bold)
	t.text = Loc.t("PAUZĖ")
	_primary_styles(_menu_button(pause_main, Loc.t("Tęsti"), T_ACC, func(): game.toggle_pause()))
	_menu_button(pause_main, Loc.t("Iš naujo"), Color(0.45, 0.65, 1.0), func(): game.start_game())
	_menu_button(pause_main, Loc.t("Ekonomikos žodynėlis"), Color(0.85, 0.7, 0.35), func(): _show_glossary_page(true))
	fs_btn = _menu_button(pause_main, "", Color(0.5, 0.55, 0.7), func(): game.toggle_fullscreen())
	_menu_button(pause_main, Loc.t("Kalba: English") if Loc.lang == "lt" else Loc.t("Kalba: Lietuvių"),
		Color(0.5, 0.55, 0.7), func(): _switch_language())
	var sep := HSeparator.new()
	pause_main.add_child(sep)
	var st := Label.new()
	st.text = Loc.t("Garso nustatymai")
	st.add_theme_font_override("font", bold)
	st.add_theme_font_size_override("font_size", 15)
	pause_main.add_child(st)
	_build_sound_controls(pause_main)
	var sep2 := HSeparator.new()
	pause_main.add_child(sep2)
	_danger_styles(_menu_button(pause_main, Loc.t("Į pradžios ekraną"), T_BAD, func(): game.quit_to_menu()))

	# glossary page
	pause_gloss = VBoxContainer.new()
	pause_gloss.add_theme_constant_override("separation", 8)
	pause_gloss.visible = false
	pc.add_child(pause_gloss)
	var gt := _center_label(pause_gloss, 26, T_TEXT)
	gt.add_theme_font_override("font", bold)
	gt.text = Loc.t("Ekonomikos žodynėlis")
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(560, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pause_gloss.add_child(sc)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	for term in Glossary.TERMS:
		var tr: Array = term[Loc.lang] if term.has(Loc.lang) else term["lt"]
		var name_l := Label.new()
		name_l.text = str(tr[0])
		name_l.add_theme_font_override("font", bold)
		name_l.add_theme_font_size_override("font_size", 17)
		name_l.add_theme_color_override("font_color", T_ACC)
		list.add_child(name_l)
		var d := Label.new()
		d.text = str(tr[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(530, 0)
		d.add_theme_font_size_override("font_size", 14)
		d.add_theme_color_override("font_color", T_MUTED.lightened(0.12))
		list.add_child(d)
	_menu_button(pause_gloss, Loc.t("Atgal"), Color(0.5, 0.55, 0.7), func(): _show_glossary_page(false))

func _show_glossary_page(on: bool) -> void:
	pause_main.visible = not on
	pause_gloss.visible = on

func show_pause(on: bool) -> void:
	pause_layer.visible = on
	if on:
		_show_glossary_page(false)
		refresh_fullscreen()
		_refresh_mute()

func _build_sound_controls(parent: Control) -> void:
	music_slider = _slider_row(parent, Loc.t("Muzika"))
	sfx_slider = _slider_row(parent, Loc.t("Efektai"))
	mute_check = CheckBox.new()
	mute_check.text = Loc.t("Išjungti visą garsą (M)")
	mute_check.focus_mode = Control.FOCUS_NONE
	mute_check.add_theme_font_size_override("font_size", 13)
	_style_check(mute_check)
	mute_check.toggled.connect(func(on: bool):
		if Sfx.inst != null and Sfx.inst.muted != on:
			Sfx.inst.set_muted(on)
		_refresh_mute())
	parent.add_child(mute_check)
	if Sfx.inst != null:
		music_slider.set_value_no_signal(Sfx.inst.music_vol * 100.0)
		sfx_slider.set_value_no_signal(Sfx.inst.sfx_vol * 100.0)
	music_slider.value_changed.connect(func(v: float):
		if Sfx.inst != null:
			Sfx.inst.set_music_volume(v / 100.0))
	sfx_slider.value_changed.connect(func(v: float):
		if Sfx.inst != null:
			Sfx.inst.set_sfx_volume(v / 100.0)
			Sfx.play("coin", 0.0))

func _slider_row(parent: Control, title: String) -> HSlider:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	parent.add_child(hb)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(70, 0)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.78, 0.85, 0.95))
	hb.add_child(l)
	var sl := HSlider.new()
	sl.min_value = 0
	sl.max_value = 100
	sl.step = 1
	sl.custom_minimum_size = Vector2(200, 24)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.1)
	track.set_corner_radius_all(4)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = T_ACC
	fill.set_corner_radius_all(4)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	hb.add_child(sl)
	return sl

func refresh_fullscreen() -> void:
	if fs_btn == null:
		return
	var fs: bool = game.is_fullscreen()
	fs_btn.text = Loc.t("Išeiti iš pilno ekrano") if fs else Loc.t("Pilnas ekranas")

# --- Language ----------------------------------------------------------------------

func _switch_language() -> void:
	Loc.set_lang("en" if Loc.lang == "lt" else "lt")
	rebuild()

## Rebuild the whole interface (used after switching the language).
func rebuild() -> void:
	var was_pause := pause_layer != null and pause_layer.visible
	var was_start := overlay != null and overlay.visible and (start_box.visible or intro_box.visible)
	var was_intro := overlay != null and overlay.visible and intro_box.visible
	var was_final := overlay != null and overlay.visible and final_box.visible
	if tutorial != null and is_instance_valid(tutorial):
		tutorial.finish()
	_root.queue_free()
	for arr in [row_name, row_desc, row_btn, card_btns, card_chip, card_title, card_desc, card_icons,
			report_tiles, final_tiles, diff_btns, lesson_secs, quiz_btns]:
		arr.clear()
	panel_station = null
	_recommended = ""
	_styled_for = null
	_build()
	relayout(get_viewport().get_visible_rect().size)
	refresh()
	if was_intro:
		show_intro()
	elif was_start:
		show_start_overlay()
	elif was_final:
		overlay.visible = true
		start_box.visible = false
		final_box.visible = true
	else:
		hide_overlay()
	if was_pause:
		show_pause(true)
	if game.selected_index >= 0 and not was_start:
		show_panel(game.stations[game.selected_index])

# --- Glossary pop-up ---------------------------------------------------------------

func _build_glossary_popup() -> void:
	gloss_popup = PanelContainer.new()
	var sb := _callout(T_ACC)
	sb.content_margin_left = 16
	sb.content_margin_right = 14
	gloss_popup.add_theme_stylebox_override("panel", sb)
	gloss_popup.position = Vector2(14, 150)
	gloss_popup.custom_minimum_size = Vector2(330, 0)
	gloss_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	gloss_popup.visible = false
	gloss_popup.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			gloss_time = 0.0
			gloss_popup.visible = false)
	_root.add_child(gloss_popup)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gloss_popup.add_child(vb)
	var chip := Label.new()
	chip.text = Loc.t("EKONOMIKOS SĄVOKA")
	chip.add_theme_font_override("font", bold)
	chip.add_theme_font_size_override("font_size", 11)
	chip.add_theme_color_override("font_color", T_ACC)
	vb.add_child(chip)
	gloss_title = Label.new()
	gloss_title.add_theme_font_override("font", bold)
	gloss_title.add_theme_font_size_override("font_size", 19)
	vb.add_child(gloss_title)
	gloss_text = Label.new()
	gloss_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gloss_text.custom_minimum_size = Vector2(300, 0)
	gloss_text.add_theme_font_size_override("font_size", 13)
	gloss_text.add_theme_color_override("font_color", T_MUTED.lightened(0.15))
	vb.add_child(gloss_text)

## Show an economics term the first time it happens in this session.
func show_term(id: String) -> void:
	if game.learning and Learning.LESSONS.has(id):
		show_lesson(id)
		return
	if not Glossary.first(id) or gloss_popup == null:
		return
	var tr := Glossary.term(id)
	gloss_title.text = str(tr[0])
	gloss_text.text = str(tr[1])
	gloss_popup.size = Vector2.ZERO
	gloss_popup.visible = true
	gloss_time = 9.0
	Sfx.play("card", 0.0, 1.2)

## Re-anchor everything to the current screen size (any aspect ratio).
func relayout(vp: Vector2) -> void:
	if pol_label == null:
		return
	var x := vp.x - 20.0 - BAR_W
	pol_label.position.x = x
	pol_fill.position.x = x
	year_label.position.x = x
	year_fill.position.x = x
	top_card.position.x = x - 14.0
	mute_btn.position = Vector2(vp.x - 20.0 - 150.0, 90)
	event_panel.position.x = vp.x * 0.5 - 210.0
	alert_panel.position = Vector2(vp.x * 0.5 - 170.0, vp.y * 0.5 - 34.0)
	panel.position.x = vp.x - 20.0 - maxf(310.0, panel.size.x)
	clean_btn.position = Vector2(vp.x - 330.0, vp.y - 136.0)
	raw_btn.position = Vector2(vp.x - 330.0, vp.y - 74.0)
	table.position = Vector2(14.0, vp.y - table.size.y - 12.0)

func _refresh_mute() -> void:
	var m := Sfx.inst != null and Sfx.inst.muted
	if mute_check != null:
		mute_check.set_pressed_no_signal(m)

func _build_event_banner() -> void:
	event_panel = PanelContainer.new()
	event_panel.add_theme_stylebox_override("panel", _callout(T_GOLD))
	event_panel.position = Vector2(DESIGN_W * 0.5 - 210, 6)
	event_panel.custom_minimum_size = Vector2(420, 0)
	event_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_panel.visible = false
	_root.add_child(event_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	event_panel.add_child(vb)
	event_title = _center_label(vb, 17, T_TEXT)
	event_title.add_theme_font_override("font", bold)
	event_desc = _center_label(vb, 13, T_MUTED.lightened(0.15))
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(1, 1, 1, 0.08)
	bar_bg.custom_minimum_size = Vector2(396, 4)
	vb.add_child(bar_bg)
	event_bar = ColorRect.new()
	event_bar.color = T_GOLD
	event_bar.size = Vector2(396, 4)
	bar_bg.add_child(event_bar)

func _build_alert() -> void:
	alert_panel = PanelContainer.new()
	alert_panel.add_theme_stylebox_override("panel", _callout(T_BAD))
	alert_panel.position = Vector2(DESIGN_W * 0.5 - 170, 290)
	alert_panel.custom_minimum_size = Vector2(340, 0)
	alert_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alert_panel.visible = false
	_root.add_child(alert_panel)
	var vb := VBoxContainer.new()
	alert_panel.add_child(vb)
	alert_title = _center_label(vb, 17, T_BAD.lightened(0.1))
	alert_title.add_theme_font_override("font", bold)
	alert_desc = _center_label(vb, 13, T_TEXT)

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
		b.custom_minimum_size = Vector2(78, 60)
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
	_rec_badge.text = Loc.t("APSIMOKA")
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

var _act: Dictionary = {}

## Action button: bold title + price on the left, small hint below,
## keyboard key in a chip on the right. Same glass style as the panels.
func _action_button(accent: Color, pos: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(310, 54)
	b.focus_mode = Control.FOCUS_NONE
	var mk := func(bg_a: float, bc: Color) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.09, 0.13, bg_a)
		sb.border_color = bc
		sb.set_border_width_all(1)
		sb.border_width_left = 4
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
		sb.anti_aliasing = true
		return sb
	b.add_theme_stylebox_override("normal", mk.call(0.82, Color(accent, 0.75)))
	var hv: StyleBoxFlat = mk.call(0.9, accent.lightened(0.15))
	hv.bg_color = Color(accent.darkened(0.7), 0.92)
	b.add_theme_stylebox_override("hover", hv)
	var pr: StyleBoxFlat = mk.call(0.95, Color.WHITE)
	pr.bg_color = Color(accent.darkened(0.55), 0.95)
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("disabled", mk.call(0.6, Color(0.35, 0.4, 0.48, 0.5)))
	b.mouse_entered.connect(_hover_sound)
	b.pressed.connect(cb)
	_root.add_child(b)
	var title := Label.new()
	title.position = Vector2(18, 7)
	title.add_theme_font_override("font", bold)
	title.add_theme_font_size_override("font_size", 15)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(title)
	var sub := Label.new()
	sub.position = Vector2(18, 29)
	sub.add_theme_font_size_override("font_size", 12)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sub)
	var key := Label.new()
	key.add_theme_font_override("font", bold)
	key.add_theme_font_size_override("font_size", 11)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(1, 1, 1, 0.08)
	ks.border_color = Color(1, 1, 1, 0.25)
	ks.set_border_width_all(1)
	ks.set_corner_radius_all(5)
	ks.content_margin_left = 7
	ks.content_margin_right = 7
	ks.content_margin_top = 2
	ks.content_margin_bottom = 2
	key.add_theme_stylebox_override("normal", ks)
	b.add_child(key)
	_act[b] = {"title": title, "sub": sub, "key": key, "accent": accent}
	return b

func _set_action(b: Button, title: String, sub: String, key: String, disabled: bool) -> void:
	var d: Dictionary = _act[b]
	b.disabled = disabled
	(d["title"] as Label).text = title
	(d["sub"] as Label).text = sub
	var kl: Label = d["key"]
	kl.text = key
	kl.reset_size()
	kl.position = Vector2(b.size.x - kl.size.x - 12.0, 9.0)
	var accent: Color = d["accent"]
	(d["title"] as Label).add_theme_color_override("font_color", Color(0.55, 0.6, 0.66) if disabled else Color(0.95, 0.97, 1.0))
	(d["sub"] as Label).add_theme_color_override("font_color", Color(0.45, 0.5, 0.56) if disabled else accent.lerp(Color.WHITE, 0.45))
	kl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6) if disabled else Color(0.85, 0.9, 0.95))

func _build_buttons() -> void:
	clean_btn = _action_button(Color(0.35, 0.75, 0.95), Vector2(DESIGN_W - 330, DESIGN_H - 136), func(): game.clean_up())
	raw_btn = _action_button(Color(0.95, 0.62, 0.3), Vector2(DESIGN_W - 330, DESIGN_H - 74), func(): game.buy_raw())

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

	report_title = _center_label(vb, 28, T_TEXT)
	report_title.add_theme_font_override("font", bold)

	# stat tiles
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(tiles)
	var tile_defs := [[Loc.t("PAJAMOS"), Color(1.0, 0.85, 0.4)], [Loc.t("Į SĄVARTYNĄ"), Color(0.9, 0.65, 0.5)],
		[Loc.t("TARŠA"), Color(1.0, 0.55, 0.45)], [Loc.t("ŽIEDINUMAS"), Color(0.55, 1.0, 0.65)]]
	for td in tile_defs:
		var t := PanelContainer.new()
		t.add_theme_stylebox_override("panel", _style(Color(0.12, 0.14, 0.2), Color(td[1], 0.35), 10, 1))
		t.custom_minimum_size = Vector2(150, 0)
		tiles.add_child(t)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		t.add_child(tv)
		var big := _center_label(tv, 26, T_TEXT)
		big.add_theme_font_override("font", bold)
		var small := _center_label(tv, 11, T_MUTED)
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
	var pick := _center_label(vb, 15, T_MUTED.lightened(0.15))
	pick.text = Loc.t("Pasirink VIENĄ investiciją ateinantiems metams:")

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 255)
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
		ic.custom_minimum_size = Vector2(84, 84)
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
	overlay.color = Color(0.02, 0.03, 0.05, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(cc)
	var holder := VBoxContainer.new()
	cc.add_child(holder)

	_build_intro(holder)

	# Start screen
	start_box = VBoxContainer.new()
	start_box.add_theme_constant_override("separation", 12)
	holder.add_child(start_box)
	var t := _center_label(start_box, 50, T_TEXT)
	t.add_theme_font_override("font", bold)
	t.text = Loc.t("Žiedinė ekonomika")
	var st := _center_label(start_box, 17, T_MUTED.lightened(0.2))
	st.text = Loc.t("Valdyk žiedinės ekonomikos įmonių grandinę 10 metų – uždirbk ir neleisk planetai užsidegti")
	var how := _center_label(start_box, 14, Color(0.75, 0.82, 0.92))
	how.text = (Loc.t("Spausk stotis – rankinis darbas  •  Pirk patobulinimus  •  Gaudyk € monetas  •  Rūšiuok atliekas\n")
		+ Loc.t("Tarpas – nauja žaliava  •  V – valymas  •  Esc – meniu"))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	start_box.add_child(sp)
	var dl := _center_label(start_box, 13, T_ACC)
	dl.add_theme_font_override("font", bold)
	dl.text = Loc.t("SUNKUMO LYGIS")
	var dh := HBoxContainer.new()
	dh.add_theme_constant_override("separation", 12)
	dh.alignment = BoxContainer.ALIGNMENT_CENTER
	start_box.add_child(dh)
	var diffs: Array = game.DIFFICULTIES
	for i in diffs.size():
		if bool(diffs[i].get("hidden", false)):
			continue
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 92)
		b.add_theme_font_size_override("font_size", 14)
		b.text = "%s\n%s" % [Loc.t(str(diffs[i]["title"])), Loc.t(str(diffs[i]["desc"]))]
		var idx := i
		b.pressed.connect(func(): Sfx.play("click"); _select_diff(idx))
		dh.add_child(b)
		diff_btns.append(b)
	secret_label = _center_label(start_box, 15, Color(1.0, 0.35, 0.3))
	secret_label.add_theme_font_override("font", bold)
	secret_label.visible = false
	var cc2 := CenterContainer.new()
	start_box.add_child(cc2)
	tut_check = CheckBox.new()
	tut_check.text = Loc.t("Rodyti vedlį (pirmam kartui)")
	tut_check.focus_mode = Control.FOCUS_NONE
	tut_check.add_theme_font_size_override("font_size", 14)
	_style_check(tut_check)
	tut_check.button_pressed = not bool(Settings.get_value("tutorial_done", false))
	var checks := VBoxContainer.new()
	checks.add_theme_constant_override("separation", 6)
	cc2.add_child(checks)
	checks.add_child(tut_check)
	# Teaching mode lives next to the guide; always off when the game starts.
	learn_check = CheckBox.new()
	learn_check.text = Loc.t("Mokomasis režimas (paaiškina ekonomikos sąvokas, pabaigoje testas)")
	learn_check.focus_mode = Control.FOCUS_NONE
	learn_check.add_theme_font_size_override("font_size", 14)
	learn_check.tooltip_text = Loc.t("Pirmus 4 metus žaidimas sustoja ir paaiškina visas ekonomikos sąvokas (pralaimėti negalima), tada trumpas testas, o toliau žaidi pasirinktu sunkumu.")
	_style_check(learn_check)
	learn_check.button_pressed = false
	learn_check.toggled.connect(func(on: bool):
		Sfx.play("click")
		if on:
			tut_check.button_pressed = true   # the guide is part of the teaching flow
	)
	checks.add_child(learn_check)
	var cc3 := CenterContainer.new()
	start_box.add_child(cc3)
	var go := Button.new()
	go.custom_minimum_size = Vector2(260, 56)
	go.add_theme_font_size_override("font_size", 22)
	go.add_theme_font_override("font", bold)
	go.text = Loc.t("PRADĖTI")
	_primary_styles(go)
	go.pressed.connect(_on_start_pressed)
	cc3.add_child(go)
	best_label = _center_label(start_box, 13, Color(0.6, 0.68, 0.8))
	var cc5 := CenterContainer.new()
	start_box.add_child(cc5)
	var lang_btn := Button.new()
	lang_btn.text = "English" if Loc.lang == "lt" else "Lietuvių"
	lang_btn.custom_minimum_size = Vector2(140, 32)
	lang_btn.add_theme_font_size_override("font_size", 13)
	_button_styles(lang_btn, Color(0.5, 0.55, 0.7))
	lang_btn.pressed.connect(func(): Sfx.play("click"); _switch_language())
	var row5 := HBoxContainer.new()
	row5.add_theme_constant_override("separation", 10)
	cc5.add_child(row5)
	var help_btn := Button.new()
	help_btn.text = Loc.t("Kaip žaisti?")
	help_btn.custom_minimum_size = Vector2(140, 32)
	help_btn.add_theme_font_size_override("font_size", 13)
	_button_styles(help_btn, Color(0.35, 0.7, 0.95))
	help_btn.pressed.connect(func(): Sfx.play("click"); show_intro())
	row5.add_child(help_btn)
	var fs_start := Button.new()
	fs_start.text = Loc.t("Pilnas ekranas")
	fs_start.custom_minimum_size = Vector2(140, 32)
	fs_start.add_theme_font_size_override("font_size", 13)
	_button_styles(fs_start)
	fs_start.pressed.connect(func(): game.toggle_fullscreen())
	row5.add_child(fs_start)
	row5.add_child(lang_btn)
	_build_secret_button()
	# The secret level is never pre-selected on launch – it stays a secret;
	# if it was played last time, "Sunkus" is offered instead.
	var saved := int(Settings.get_value("difficulty", 1))
	_select_diff(mini(saved, SECRET_DIFF - 1))

	# Final screen
	final_box = VBoxContainer.new()
	final_box.add_theme_constant_override("separation", 14)
	final_box.visible = false
	holder.add_child(final_box)
	final_sub = _center_label(final_box, 16, T_MUTED.lightened(0.15))
	final_title = _center_label(final_box, 40, Color(1.0, 0.88, 0.45))
	final_title.add_theme_font_override("font", bold)
	var ftiles := HBoxContainer.new()
	ftiles.add_theme_constant_override("separation", 10)
	ftiles.alignment = BoxContainer.ALIGNMENT_CENTER
	final_box.add_child(ftiles)
	var fdefs := [[Loc.t("UŽDIRBTA"), Color(1.0, 0.85, 0.4)], [Loc.t("CIKLŲ"), Color(0.6, 0.8, 1.0)],
		[Loc.t("ŽIEDINUMAS"), Color(0.55, 1.0, 0.65)], [Loc.t("TARŠA"), Color(1.0, 0.55, 0.45)], [Loc.t("SĄVARTYNE"), Color(0.9, 0.65, 0.5)]]
	for td in fdefs:
		var t2 := PanelContainer.new()
		t2.add_theme_stylebox_override("panel", _style(Color(0.12, 0.14, 0.2), Color(td[1], 0.35), 10, 1))
		t2.custom_minimum_size = Vector2(138, 0)
		ftiles.add_child(t2)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		t2.add_child(tv)
		var big := _center_label(tv, 24, T_TEXT)
		big.add_theme_font_override("font", bold)
		var small := _center_label(tv, 11, T_MUTED)
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
	again.text = Loc.t("Žaisti dar kartą")
	_primary_styles(again)
	again.pressed.connect(func(): show_start_overlay())
	cc4.add_child(again)

func _build_intro(holder: Control) -> void:
	intro_box = VBoxContainer.new()
	intro_box.add_theme_constant_override("separation", 10)
	intro_box.visible = false
	holder.add_child(intro_box)
	var t := _center_label(intro_box, 34, T_TEXT)
	t.add_theme_font_override("font", bold)
	t.text = Loc.t("Kaip žaisti?")
	var sub := _center_label(intro_box, 15, T_MUTED.lightened(0.15))
	sub.text = Loc.t("Žiedinė ekonomika – daiktai ne išmetami, o vėl ir vėl panaudojami. Štai kaip tai veikia žaidime:")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	intro_box.add_child(grid)
	for card in INTRO_CARDS:
		var c: Color = card[2]
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.9), T_LINE, 10, 1))
		p.custom_minimum_size = Vector2(420, 128)
		grid.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		p.add_child(v)
		var hd := Label.new()
		hd.text = Loc.t(str(card[0]))
		hd.add_theme_font_override("font", bold)
		hd.add_theme_font_size_override("font_size", 15)
		hd.add_theme_color_override("font_color", T_ACC)
		v.add_child(hd)
		var body := Label.new()
		body.text = Loc.t(str(card[1]))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(396, 0)
		body.add_theme_font_size_override("font_size", 13)
		body.add_theme_color_override("font_color", T_MUTED.lightened(0.18))
		v.add_child(body)
	var tip := _center_label(intro_box, 13, T_MUTED)
	tip.text = Loc.t("Dėstytojams ir pristatymui: pradžios ekrane įjunk „Mokomasis režimas“ – per pirmus 4 metus žaidimas pats sustos ir paaiškins kiekvieną ekonomikos sąvoką, tada bus trumpas testas.")
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(852, 0)
	var cc := CenterContainer.new()
	intro_box.add_child(cc)
	var ok := Button.new()
	ok.custom_minimum_size = Vector2(300, 52)
	ok.add_theme_font_size_override("font_size", 20)
	ok.add_theme_font_override("font", bold)
	ok.text = Loc.t("Supratau – pirmyn!")
	_primary_styles(ok)
	ok.pressed.connect(func():
		Sfx.play("click")
		Settings.set_value("intro_seen", true)
		if _pending_start:
			_on_start_pressed()
		else:
			show_start_overlay())
	cc.add_child(ok)

# --- Learning mode ------------------------------------------------------------

func _build_lessons() -> void:
	lesson_dim = ColorRect.new()
	lesson_dim.color = Color(0.01, 0.02, 0.04, 0.72)
	lesson_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	lesson_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	lesson_dim.visible = false
	_root.add_child(lesson_dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	lesson_dim.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.06, 0.09, 0.14, 0.97), Color(0.45, 0.8, 1.0), 14, 2))
	cc.add_child(p)
	var holder := VBoxContainer.new()
	p.add_child(holder)
	# lesson page
	lesson_box = VBoxContainer.new()
	lesson_box.add_theme_constant_override("separation", 6)
	holder.add_child(lesson_box)
	lesson_head = Label.new()
	lesson_head.add_theme_font_size_override("font_size", 13)
	lesson_head.add_theme_color_override("font_color", T_ACC)
	lesson_box.add_child(lesson_head)
	lesson_title = Label.new()
	lesson_title.add_theme_font_override("font", bold)
	lesson_title.add_theme_font_size_override("font_size", 30)
	lesson_title.add_theme_color_override("font_color", Color(1, 1, 1))
	lesson_box.add_child(lesson_title)
	var heads := [[Loc.t("KAS TAI?"), T_ACC], [Loc.t("REALIAME PASAULYJE"), T_ACC],
		[Loc.t("KAIP TAI MATYTI ŽAIDIME"), T_ACC]]
	for hd in heads:
		var hl := Label.new()
		hl.text = hd[0]
		hl.add_theme_font_override("font", bold)
		hl.add_theme_font_size_override("font_size", 14)
		hl.add_theme_color_override("font_color", hd[1])
		lesson_box.add_child(hl)
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(660, 0)
		body.add_theme_font_size_override("font_size", 16)
		body.add_theme_color_override("font_color", T_TEXT)
		lesson_box.add_child(body)
		lesson_secs.append(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	lesson_box.add_child(row)
	lesson_next = Button.new()
	lesson_next.custom_minimum_size = Vector2(200, 46)
	lesson_next.add_theme_font_size_override("font_size", 18)
	lesson_next.add_theme_font_override("font", bold)
	lesson_next.text = Loc.t("Toliau ▶")
	_primary_styles(lesson_next)
	lesson_next.pressed.connect(_close_lesson)
	row.add_child(lesson_next)
	# quiz page
	quiz_box = VBoxContainer.new()
	quiz_box.add_theme_constant_override("separation", 10)
	quiz_box.visible = false
	holder.add_child(quiz_box)
	quiz_q = Label.new()
	quiz_q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quiz_q.custom_minimum_size = Vector2(660, 0)
	quiz_q.add_theme_font_override("font", bold)
	quiz_q.add_theme_font_size_override("font_size", 22)
	quiz_box.add_child(quiz_q)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(660, 46)
		b.add_theme_font_size_override("font_size", 16)
		var idx := i
		b.pressed.connect(func(): _answer(idx))
		quiz_box.add_child(b)
		quiz_btns.append(b)
	quiz_feedback = Label.new()
	quiz_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quiz_feedback.custom_minimum_size = Vector2(660, 0)
	quiz_feedback.add_theme_font_size_override("font_size", 15)
	quiz_box.add_child(quiz_feedback)
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_END
	quiz_box.add_child(row2)
	quiz_next = Button.new()
	quiz_next.custom_minimum_size = Vector2(200, 46)
	quiz_next.add_theme_font_size_override("font_size", 18)
	quiz_next.add_theme_font_override("font", bold)
	quiz_next.text = Loc.t("Toliau ▶")
	_primary_styles(quiz_next)
	quiz_next.pressed.connect(_next_question)
	row2.add_child(quiz_next)
	# small badge so everyone sees the mode is on
	learn_badge = Label.new()
	learn_badge.text = Loc.t("mokomasis režimas")
	learn_badge.add_theme_font_size_override("font_size", 11)
	learn_badge.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 0.45))
	learn_badge.position = Vector2(280, 16)
	learn_badge.visible = false
	learn_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(learn_badge)

## Called by the game at every start.
func start_learning(on: bool) -> void:
	_lessons_shown.clear()
	_lesson_queue.clear()
	_learning_ending = false
	_mid_quiz = false
	quiz_done = false
	_quiz_score = 0
	learn_badge.visible = on
	lesson_dim.visible = false
	if on:
		get_tree().create_timer(0.6).timeout.connect(func(): show_lesson("intro"))

func show_lesson(id: String) -> void:
	if id in _lessons_shown or Learning.lesson(id).is_empty():
		return
	if lesson_dim.visible or game.tutorial_active or (coach_node != null and coach_node.is_active()):
		if not id in _lesson_queue:
			_lesson_queue.append(id)
		return
	_lesson_queue.erase(id)
	_lessons_shown.append(id)
	game.lesson_timer = 0.0
	_lesson_id = id
	var l := Learning.lesson(id)
	lesson_head.text = Loc.t("Sąvoka %d iš %d") % [_lessons_shown.size(), Learning.ORDER.size()]
	lesson_title.text = str(l[0])
	for i in 3:
		lesson_secs[i].text = str(l[i + 1])
	lesson_box.visible = true
	quiz_box.visible = false
	lesson_dim.visible = true
	game.lesson_open = true
	Sfx.play("card", 0.0, 1.1)

func _close_lesson() -> void:
	Sfx.play("click")
	lesson_dim.visible = false
	game.lesson_open = false
	if not _lesson_queue.is_empty():
		show_lesson(_lesson_queue.pop_front())
	elif _learning_ending:
		_continue_ending()

func lessons_left() -> int:
	var n := 0
	for id in Learning.ORDER:
		if not id in _lessons_shown:
			n += 1
	return n

## Scheduled lesson: the next one in ORDER that has not been shown yet.
func next_lesson() -> void:
	if lesson_dim.visible or game.in_report or game.sorting_active:
		return
	if not _lesson_queue.is_empty():
		show_lesson(_lesson_queue.pop_front())
		return
	for id in Learning.ORDER:
		if not id in _lessons_shown:
			show_lesson(id)
			return

## Lessons that waited for the guide to finish.
func flush_lessons() -> void:
	if not lesson_dim.visible and not _lesson_queue.is_empty():
		show_lesson(_lesson_queue.pop_front())

## After year LESSON_YEARS: any missing lessons, then the quiz; the game then goes on.
func learning_mid_quiz() -> void:
	_mid_quiz = true
	_learning_ending = true
	game.lesson_open = true
	_continue_ending()

## End of a learning game: lessons that never came up, then the quiz.
func learning_finish(summary: Dictionary) -> void:
	_end_summary = summary
	_learning_ending = true
	game.lesson_open = true
	_continue_ending()

func _continue_ending() -> void:
	for id in Learning.ORDER:
		if not id in _lessons_shown:
			show_lesson(id)
			return
	_start_quiz()

func _start_quiz() -> void:
	_quiz_i = 0
	_quiz_score = 0
	lesson_box.visible = false
	quiz_box.visible = true
	lesson_dim.visible = true
	game.lesson_open = true
	_show_question()

func _show_question() -> void:
	var q: Array = Learning.quiz()[_quiz_i]
	quiz_q.text = (Loc.t("Klausimas %d iš %d") % [_quiz_i + 1, Learning.quiz().size()]) + "\n" + str(q[0])
	var ans: Array = q[1]
	for i in 3:
		var b := quiz_btns[i]
		b.text = str(ans[i])
		b.disabled = false
		_button_styles(b, Color(0.45, 0.55, 0.75))
	quiz_feedback.text = ""
	quiz_next.visible = false
	_quiz_answered = false

func _answer(i: int) -> void:
	if _quiz_answered:
		return
	_quiz_answered = true
	var q: Array = Learning.quiz()[_quiz_i]
	var right := int(q[2])
	for k in 3:
		if k == right:
			_tinted_button(quiz_btns[k], T_GOOD)
		elif k == i:
			_tinted_button(quiz_btns[k], T_BAD)
		else:
			_button_styles(quiz_btns[k])
	if i == right:
		_quiz_score += 1
		Sfx.play("sort_ok")
		quiz_feedback.add_theme_color_override("font_color", T_GOOD)
		quiz_feedback.text = Loc.t("Teisingai! ") + str(q[3])
	else:
		Sfx.play("sort_bad")
		quiz_feedback.add_theme_color_override("font_color", T_BAD)
		quiz_feedback.text = Loc.t("Neteisingai. ") + str(q[3])
	quiz_next.visible = true

func _next_question() -> void:
	Sfx.play("click")
	_quiz_i += 1
	if _quiz_i < Learning.quiz().size():
		_show_question()
		return
	lesson_dim.visible = false
	game.lesson_open = false
	_learning_ending = false
	quiz_done = true
	if _mid_quiz:
		_mid_quiz = false
		FloatText.spawn(self, get_viewport().get_visible_rect().size * Vector2(0.5, 0.3),
			Loc.t("Testas: %d iš %d teisingai") % [_quiz_score, Learning.quiz().size()], Color(0.55, 0.9, 1.0), 26)
		Juice.confetti(self, Vector2(get_viewport().get_visible_rect().size.x * 0.5, 160.0), 40, 1.2)
		return
	show_final(_end_summary)
	if _quiz_score * 2 >= Learning.quiz().size():
		Juice.confetti(self, Vector2(get_viewport().get_visible_rect().size.x * 0.5, 160.0), 60, 1.4)

func show_intro() -> void:
	_intro_shown_once = true
	overlay.visible = true
	intro_box.visible = true
	start_box.visible = false
	final_box.visible = false

## Invisible button in the bottom-left corner of the start screen that
## unlocks the secret "Ekstremalus" difficulty.
func _build_secret_button() -> void:
	var sb := Button.new()
	sb.flat = true
	sb.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		sb.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	sb.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	sb.offset_left = 0.0
	sb.offset_top = -48.0
	sb.offset_right = 48.0
	sb.offset_bottom = 0.0
	sb.pressed.connect(func():
		if start_box.visible:
			Sfx.play("upgrade", 0.0, 0.7)
			Sfx.play("whoosh")
			_select_diff(SECRET_DIFF))
	sb.draw.connect(_draw_secret_glint)
	overlay.add_child(sb)
	secret_btn = sb

## After "Sunkus" is beaten the hidden corner twinkles now and then – a hint.
func _draw_secret_glint() -> void:
	if not bool(Settings.get_value("hard_beaten", false)) or not start_box.visible:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var c := Vector2(20, secret_btn.size.y - 20)
	# soft breathing glow
	var breath := 0.5 + 0.5 * sin(t * 1.6)
	secret_btn.draw_circle(c, 13.0, Color(1.0, 0.85, 0.4, 0.05 + 0.06 * breath))
	secret_btn.draw_circle(c, 6.0, Color(1.0, 0.9, 0.55, 0.06 + 0.08 * breath))
	# a star-shaped glint flashes every ~2.5 s
	var ph := fmod(t, 2.5) / 2.5
	if ph < 0.35:
		var k := sin(ph / 0.35 * PI)
		var L := 4.0 + 12.0 * k
		var w := 1.0 + 1.2 * k
		var col := Color(1.0, 0.95, 0.75, 0.85 * k)
		var rot := t * 1.5
		for i in 4:
			var d := Vector2.RIGHT.rotated(rot + float(i) * PI * 0.5)
			var n := d.orthogonal()
			secret_btn.draw_colored_polygon(PackedVector2Array([c + n * w, c + d * L, c - n * w]), col)
		secret_btn.draw_circle(c, 2.0 + 1.5 * k, Color(1, 1, 1, 0.9 * k))

func _select_diff(i: int) -> void:
	selected_diff = clampi(i, 0, game.DIFFICULTIES.size() - 1)
	if selected_diff == SECRET_DIFF:
		secret_label.text = Loc.t("★ SLAPTAS LYGIS: EKSTREMALUS ★") + "\n" + \
			Loc.t("Dar daugiau atliekų, mažiau pinigų, griežčiausi ES tikslai ir nelaimės be perstojo")
		secret_label.visible = true
	else:
		secret_label.visible = false
	for k in diff_btns.size():
		var b := diff_btns[k]
		_button_styles(b)
		if k == selected_diff:
			b.add_theme_stylebox_override("normal", _btn_box(Color(T_ACC_FILL, 0.3), T_ACC, 2))
			b.add_theme_stylebox_override("hover", _btn_box(Color(T_ACC_FILL, 0.4), T_ACC.lightened(0.2), 2))

func _on_start_pressed() -> void:
	Sfx.play("card", 0.0)
	Settings.set_value("difficulty", selected_diff)
	if learn_check.button_pressed and not _pending_start and not _intro_shown_once:
		_intro_shown_once = true
		# teaching mode: first the "how to play" page, then the game with the guide
		_pending_start = true
		show_intro()
		return
	_pending_start = false
	var learn := learn_check.button_pressed
	game.start_game(selected_diff, tut_check.button_pressed or learn, learn)

func show_start_overlay() -> void:
	overlay.visible = true
	# A brand-new player first sees the "how to play" page.
	if not bool(Settings.get_value("intro_seen", false)):
		show_intro()
		return
	intro_box.visible = false
	start_box.visible = true
	final_box.visible = false
	tut_check.button_pressed = not bool(Settings.get_value("tutorial_done", false)) or learn_check.button_pressed
	var best := int(Settings.get_value("best_score", 0))
	best_label.text = Loc.t("Tavo rekordas: %d") % best if best > 0 else ""
	_refresh_mute()

# --- Overlays / panels -------------------------------------------------------

func show_report(s: Dictionary, cards: Array) -> void:
	coach("report")
	hide_panel()
	report.visible = true
	report_title.text = Loc.t("%d-ųjų metų ataskaita") % int(s["year"])
	report_tiles[0].text = "€%d" % int(s["earned"])
	report_tiles[1].text = "%d vnt." % int(s["landfill"])
	report_tiles[2].text = "%d %%" % int(s["pollution"])
	report_tiles[3].text = "%d %%" % int(s["circ"])
	if bool(s["met"]):
		report_goal_label.text = Loc.t("ES žiedinumo tikslas %d %% – PASIEKTAS!   Premija +€%d") % [int(s["target"]), int(s["reward"])]
		report_goal_label.add_theme_color_override("font_color", T_GOOD)
		report_goal.add_theme_stylebox_override("panel", _callout(T_GOOD))
	else:
		report_goal_label.text = Loc.t("ES žiedinumo tikslas %d %% – NEPASIEKTAS.   Bauda -€%d") % [int(s["target"]), int(-float(s["reward"]))]
		report_goal_label.add_theme_color_override("font_color", T_BAD)
		report_goal.add_theme_stylebox_override("panel", _callout(T_BAD))
	for i in card_btns.size():
		if i < cards.size():
			var cat: Dictionary = CATEGORY.get(str(cards[i].get("cat", "fin")), CATEGORY["fin"])
			var c: Color = cat["color"]
			card_btns[i].visible = true
			_button_styles(card_btns[i])
			card_btns[i].add_theme_stylebox_override("hover", _btn_box(Color(T_RAISED.lightened(0.08), 0.96), Color(c, 0.9), 2))
			card_chip[i].text = "● " + Loc.t(str(cat["label"]))
			card_chip[i].add_theme_color_override("font_color", c)
			card_title[i].text = Loc.t(str(cards[i]["title"]))
			card_icons[i].set_perk(str(cards[i]["id"]))
			card_desc[i].text = Loc.t(str(cards[i]["desc"])).replace("\n", " ")
		else:
			card_btns[i].visible = false
	_fit_report_cards.call_deferred()

func _fit_report_cards() -> void:
	# Buttons do not inherit their child's minimum height. Measure after text
	# wrapping, so long translated titles and descriptions stay inside the card.
	await get_tree().process_frame
	var height := 255.0
	for button in card_btns:
		if button.visible:
			height = maxf(height, button.get_child(0).get_combined_minimum_size().y)
	for button in card_btns:
		button.custom_minimum_size.y = ceilf(height)

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
	final_sub.text = Loc.t("ŽAIDIMAS BAIGTAS") if bool(s.get("lost", false)) else Loc.t("10 metų baigėsi! Tavo įmonės titulas:")
	if game.learning:
		final_sub.text = Loc.t("Mokomasis žaidimas baigtas! Tavo įmonės titulas:")
	var score: int = game.final_score()
	var best := int(Settings.get_value("best_score", 0))
	if game.learning:
		best = maxi(best, score + 1)   # learning games don't count for the record
	final_tiles[0].text = "€%d" % int(game.total_earned)
	final_tiles[1].text = str(game.loops)
	final_tiles[2].text = "%d %%" % int(game.circularity())
	final_tiles[3].text = "%d %%" % int(game.pollution)
	final_tiles[4].text = "%d vnt." % game.landfilled
	if score > best:
		Settings.set_value("best_score", score)
		final_score_label.text = Loc.t("Rezultatas: %d  –  naujas rekordas!") % score
		final_score_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	else:
		final_score_label.text = Loc.t("Rezultatas: %d   (rekordas: %d)") % [score, best]
		final_score_label.add_theme_color_override("font_color", Color(1, 1, 1))
	if bool(s.get("lost", false)):
		final_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		var why := Loc.t("Tarša per ilgai laikėsi 100 % – ekosistema žlugo.") if game.lost_reason == "planet" \
			else Loc.t("Skolos viršijo €%d – bankas uždarė įmonę.") % int(-game.BANKRUPT_AT)
		final_text.text = (Loc.t("Įmonė žlugo %d-aisiais metais. %s\n")
			+ Loc.t("Kadangi įmonė žlugo, rezultatas sumažintas perpus. Sunkumas: %s.")) % [
			game.year, why, Loc.t(str(game.DIFFICULTIES[game.difficulty]["title"]))]
		return
	final_title.add_theme_color_override("font_color", T_TEXT)
	var goal := Loc.t("pasiektas") if bool(s["met"]) else Loc.t("nepasiektas")
	final_text.text = (Loc.t("Sunkumas: %s.  Paskutinių metų ES tikslas %s.\n")
		+ Loc.t("Rezultatą lemia uždirbti pinigai, planetos būklė ir žiedinumo rodiklis – turtas ant užterštos planetos vertas mažiau.")) % [
		Loc.t(str(game.DIFFICULTIES[game.difficulty]["title"])), goal]
	if game.learning:
		final_score_label.text = (Loc.t("Rezultatas: %d") % score) + "   ·   " + \
			Loc.t("Testas: %d iš %d teisingai") % [_quiz_score, Learning.quiz().size()]
		final_score_label.add_theme_color_override("font_color", Color(0.55, 0.9, 1.0))
		final_text.text = Loc.t("Šiame žaidime pamatėme: linijinę ir žiedinę ekonomiką, pridėtinę vertę, pirminę ir antrinę žaliavą, išorinį poveikį, Pigou mokestį, masto ekonomiją, ekonomikos augimą, ES žiedinumo tikslus, alternatyviuosius kaštus, paklausą ir pasiūlą bei darbo rinką.")

func hide_overlay() -> void:
	overlay.visible = false

func set_paused(p: bool) -> void:
	show_pause(p)
	# the guide must not float over the pause menu
	if tutorial != null and is_instance_valid(tutorial):
		tutorial.visible = not p
	if coach_node != null and coach_node.is_active():
		coach_node.visible = not p

func show_panel(station: Station) -> void:
	panel_station = station
	panel.visible = true
	var accent := Pipeline.color_of(station.index)
	panel.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.92), T_LINE, 12, 1))
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
	event_title.text = Loc.t(str(e["title"]))
	event_desc.text = Loc.t(str(e["desc"]))
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

# --- Guide tips for first-time situations ---------------------------------------

func start_coach(on: bool) -> void:
	if coach_node == null or not is_instance_valid(coach_node):
		coach_node = Coach.new()
		_root.add_child(coach_node)
		coach_node.setup(game, self, font, bold)
		coach_node.tip_closed.connect(flush_lessons)
	coach_node.close()
	_coach_on = on
	_coach_seen.clear()
	_coach_queue.clear()

func coach_disable() -> void:
	_coach_on = false
	_coach_queue.clear()
	if coach_node != null:
		coach_node.close()

## Ask for a first-time tip (shown once per game, only when the guide is on).
func coach(id: String, st: Station = null) -> void:
	if not _coach_on or id in _coach_seen:
		return
	_coach_seen.append(id)
	_coach_queue.append([id, st])

func _try_coach() -> void:
	if coach_node == null or not _coach_on or _coach_queue.is_empty() or coach_node.is_active():
		return
	if not game.running or game.finished or game.tutorial_active or lesson_dim.visible:
		return
	if pause_layer != null and pause_layer.visible:
		return
	var it: Array = _coach_queue.pop_front()
	var tip := _coach_tip(str(it[0]), it[1])
	if not tip.is_empty():
		coach_node.show_tip(tip)

func _st_pos(st: Station) -> Vector2:
	return st.global_position

func _coach_tip(id: String, st: Station) -> Dictionary:
	match id:
		"fire":
			if st == null or st.fire <= 0.0:
				return {}
			return {"title": Loc.t("Gaisras!"),
				"text": Loc.t("Stotis dega ir nedirba, o dūmai didina taršą. Spausk ją greitai kelis kartus – kiekvienas paspaudimas gesina. Kol mokaisi, žaidimas sustabdytas."),
				"target": func(): return _st_pos(st), "r": 70.0, "freeze": true, "button": false,
				"done": func(): return st.fire <= 0.0,
				"progress": func(): return Loc.t("\n\nLiko paspaudimų: %d") % int(ceil(st.fire))}
		"strike":
			if st == null or st.strike <= 0.0:
				return {}
			return {"title": Loc.t("Streikas"),
				"text": Loc.t("Darbuotojai nori didesnių algų, todėl stotis nedirba. Spausk ją ir sumokėk – arba palauk, kol streikas baigsis, bet tada prarasi gamybą."),
				"target": func(): return _st_pos(st), "r": 70.0, "freeze": true, "button": true,
				"done": func(): return st.strike <= 0.0}
		"flood":
			return {"title": Loc.t("Potvynis"),
				"text": Loc.t("Vanduo išplovė stoties sandėlį – daiktai iškrito į sąvartyną. Kuo greičiau stotys apdoroja daiktus, tuo mažiau jų gali pražūti."),
				"target": func(): return _st_pos(st) if st != null else game.center, "r": 70.0, "freeze": true, "button": true}
		"storm":
			return {"title": Loc.t("Vėtra"),
				"text": Loc.t("Vėtra nupūtė daiktus nuo konvejerio. Nelaimių išvengti negalima, bet greitos stotys sumažina nuostolius."),
				"target": func(): return game.center, "r": game.ring.radius + 20.0, "freeze": true, "button": true}
		"heat":
			return {"title": Loc.t("Karščio banga"),
				"text": Loc.t("Kurį laiką visos stotys dirba lėčiau. Padėk joms – spausk tas, kuriose kaupiasi daiktai."),
				"target": func(): return game.center, "r": game.ring.radius + 20.0, "freeze": true, "button": true}
		"sort_alert":
			if st == null:
				return {}
			return {"title": Loc.t("Mišrios atliekos"),
				"text": Loc.t("Į Rūšiavimą atvežė sumaišytų atliekų. Paspausk Rūšiavimo stotį – atsidarys rūšiavimo žaidimas."),
				"target": func(): return _st_pos(st), "r": 70.0, "freeze": true, "button": false,
				"done": func(): return game.sorting_active}
		"sort_drag":
			var s := sorting
			if s == null or not is_instance_valid(s):
				return {}
			s.hold_timer = true
			return {"title": Loc.t("Rūšiuok"),
				"text": Loc.t("Pele nutempk daiktą į tinkamą konteinerį: geltonas – plastikas ir metalas, žalias – stiklas, mėlynas – popierius. Kol mokaisi, laikas sustabdytas."),
				"target": func(): return Rect2(s._pos - Vector2(70, 70), Vector2(140, 140)) if is_instance_valid(s) else Rect2(),
				"freeze": false, "button": false,
				"done": func(): return not is_instance_valid(s) or s.drops > 0,
				"on_close": func(): if is_instance_valid(s): s.hold_timer = false}
		"landfill":
			return {"title": Loc.t("Sąvartynas"),
				"text": Loc.t("Šis daiktas nespėjo būti apdorotas ir iškrito į sąvartyną. Už kiekvieną moki mokestį, o tarša kyla. Pirk greitį ir didesnius sandėlius ten, kur kaupiasi daiktai."),
				"target": func(): return game.landfill.global_position + Vector2(0, -40), "r": 80.0, "freeze": true, "button": true}
		"event":
			return {"title": Loc.t("Rinkos įvykis"),
				"text": Loc.t("Viršuje – rinkos naujiena. Ji kurį laiką keičia kainas ar paklausą. Stebėk ją ir prisitaikyk."),
				"target": func(): return Rect2(event_panel.global_position, event_panel.size).grow(4.0),
				"freeze": true, "button": true}
		"report":
			return {"title": Loc.t("Metų pabaiga"),
				"text": Loc.t("Viršuje matai metų rezultatus ir ES tikslą. Apačioje rinkis VIENĄ investiciją ateinantiems metams – ji padės visą likusį žaidimą."),
				"target": func(): return _report_cards_rect(), "freeze": false, "button": true}
	return {}

func _report_cards_rect() -> Rect2:
	var r := Rect2()
	for b in card_btns:
		if is_instance_valid(b) and b.visible:
			var br := b.get_global_rect()
			r = br if r.size == Vector2.ZERO else r.merge(br)
	return r.grow(6.0)

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
	if secret_btn != null and overlay.visible:
		secret_btn.queue_redraw()
	_try_coach()
	_blink_t += delta
	if panel != null and panel.visible and not pause_layer.visible and not overlay.visible and not qr_layer.visible and not report.visible:
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
	if gloss_time > 0.0:
		gloss_time -= delta
		gloss_popup.modulate.a = clampf(gloss_time / 0.6, 0.0, 1.0)
		if gloss_time <= 0.0:
			gloss_popup.visible = false
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
	if is_instance_valid(qr_layer) and qr_layer.visible:
		if ev is InputEventKey:
			if ev.pressed and ev.keycode == KEY_ESCAPE:
				qr_layer.hide()
			get_viewport().set_input_as_handled()
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_M:
			_toggle_mute()
		elif not OS.has_feature("web") and (ev.keycode == KEY_F11 or (ev.keycode == KEY_ENTER and ev.alt_pressed)):
			game.toggle_fullscreen()
			get_viewport().set_input_as_handled()

func refresh() -> void:
	if game == null:
		return

	money_label.text = "€ %d" % int(floor(game.money))
	money_label.add_theme_color_override("font_color",
		Color(1.0, 0.88, 0.45) if game.money >= 0.0 else Color(1.0, 0.45, 0.4))
	if game.money < 0.0:
		income_label.text = Loc.t("Skolos! Bankrotas, kai skola pasieks €%d") % int(-game.BANKRUPT_AT)
		income_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
	else:
		income_label.text = Loc.t("Pajamos: €%d / min") % int(game.income_per_min())
		income_label.add_theme_color_override("font_color", T_MUTED)
	circ_label.text = Loc.t("Žiedinumas: %d %%") % int(game.circularity())
	loops_label.text = Loc.t("Užbaigti ciklai: %d") % game.loops

	_update_bars()

	var rp: float = game.raw_price()
	_set_action(raw_btn, Loc.t("Pirkti naują žaliavą") + "  ·  €%d" % int(round(rp)),
		Loc.t("Greita, bet teršia ir mažina žiedinumą"), Loc.t("Tarpas"), game.money < rp or not game.running)
	var cp: float = game.cleanup_price()
	_set_action(clean_btn, Loc.t("Valyti aplinką") + "  ·  €%d" % int(cp),
		Loc.t("Tarša -%d %%, kitas valymas bus brangesnis") % int(game.CLEANUP_AMOUNT), "V",
		game.money < cp or not game.running or game.pollution < 1.0)

	_refresh_panel()

func _update_bars() -> void:
	var p: float = clampf(game.pollution / 100.0, 0.0, 1.0)
	pol_label.text = Loc.t("Tarša: %d %%  –  %s") % [int(game.pollution), game.pollution_stage()]
	pol_fill.ratio = p
	pol_fill.flash = maxf(pol_flash, 0.0)
	year_label.text = Loc.t("Metai %d / %d") % [game.year, game.total_years()]
	var ty: int = game.total_years()
	year_fill.segments = ty
	year_fill.ratio = (float(game.year - 1) + clampf(game.year_time / game.YEAR_LEN, 0.0, 1.0)) / float(ty)

func _refresh_panel() -> void:
	if not panel.visible or panel_station == null:
		return
	panel.position.x = get_viewport().get_visible_rect().size.x - 20.0 - maxf(310.0, panel.size.x)
	panel_fact.visible = get_viewport().get_visible_rect().size.y >= 760.0
	var st := panel_station
	var accent := Pipeline.color_of(st.index)
	panel_title.text = "%d. %s" % [st.index + 1, Pipeline.name_of(st.index)]
	panel_title.add_theme_color_override("font_color", T_TEXT)
	panel_fact.text = Pipeline.fact_of(st.index)
	var rec: String = game.recommend(st)
	if rec != _recommended or st != _styled_for:
		_recommended = rec
		_styled_for = st
		for j in KINDS.size():
			if KINDS[j] == _recommended:
				_tinted_button(row_btn[j], T_GOOD)
			else:
				_button_styles(row_btn[j])
	for i in KINDS.size():
		var kind: String = KINDS[i]
		var lvl := st.level_of(kind)
		var best := kind == _recommended
		row_name[i].text = Pipeline.upgrade_name(st.index, kind)
		row_name[i].add_theme_color_override("font_color", T_GOOD if best else T_TEXT)
		if st.is_maxed(kind):
			row_desc[i].text = Loc.t("Lygis %d/%d – maksimalus") % [lvl, Station.MAX_LEVEL]
			row_btn[i].text = "MAX"
			row_btn[i].disabled = true
		else:
			var cost := st.cost_of(kind)
			row_desc[i].text = Loc.t("Lygis %d → %d.  %s") % [lvl, lvl + 1, st.preview(kind)]
			row_btn[i].text = "€%d" % cost
			row_btn[i].disabled = game.money < cost
