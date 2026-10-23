## Tutorial
##
## First-game guide: a speech bubble with a pulsing highlight pointing at the
## thing to try. Some steps continue on "Toliau", others wait for the player
## to actually do it (click a station, buy an upgrade, catch a coin).
## Can be skipped at any time; shown only once (stored in Settings).
class_name Tutorial
extends Control

signal done

var game: Node
var hud: Node
var font: Font
var bold: Font

var _step: int = -1
var _steps: Array = []
var _bubble: PanelContainer
var _text: Label
var _title: Label
var _next_btn: Button
var _skip_btn: Button
var _t: float = 0.0
var _target := Vector2.ZERO
var _target_r := 50.0
var _rect := Rect2()        # when non-empty, highlight this rectangle instead of a circle
var _clicks: int = 0

func setup(g: Node, h: Node, f: Font, fb: Font) -> void:
	game = g
	hud = h
	font = f
	bold = fb
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_steps = [
		{"title": Loc.t("Sveikas, direktoriau!"),
			"text": Loc.t("Tai tavo įmonių ratas. Daiktai keliauja per 6 stotis, o kiekviena prideda produktui vertės. Parduotuvėje jis parduodamas, o naudotojas vėl grąžina jį į ratą."),
			"target": func(): return game.center, "r": 120.0, "wait": ""},
		{"title": Loc.t("Rankinis darbas"),
			"text": Loc.t("Kai stotyje laukia daiktai, spausk ją daug kartų – kiekvienas paspaudimas pagreitina darbą, o keli paspaudimai iškart apdoroja daiktą. Kuo greičiau spaudi, tuo daugiau pagamini! Pabandyk su Surinkimu – paspausk 3 kartus."),
			"target": func(): return game.stations[1].guide_highlight()["center"], "r": func(): return game.stations[1].guide_highlight()["radius"], "wait": "work"},
		{"title": Loc.t("Investuok"),
			"text": Loc.t("Dešinėje atsidarė stoties patobulinimai. Nupirk vieną – pvz., greitį. Lentelėje kairėje žaliai švyti labiausiai užsipildžiusi stotis – ją verta patobulinti pirmiausia, o dešinėje mirksi tai, kas labiausiai apsimoka."),
			"target": func(): return _ctl_rect([hud.panel]), "r": 0.0, "wait": "upgrade"},
		{"title": Loc.t("Investuotojai"),
			"text": Loc.t("Kartais pasirodo auksinės monetos – investuotojų pinigai. Spėk pagauti, kol neišnyko!"),
			"target": func(): return game.tutorial_bonus_pos(), "r": 40.0, "wait": "bonus"},
		{"title": Loc.t("Tarša"),
			"text": Loc.t("Ko nespėsi apdoroti – keliaus į sąvartyną. Tarša mažina kainas, sukelia gaisrus ir potvynius, o planeta pradeda degti."),
			"target": func(): return _ctl_rect([hud.pol_label, hud.pol_fill]), "r": 0.0, "wait": ""},
		{"title": Loc.t("10 metų"),
			"text": Loc.t("Kas minutę – metų ataskaita, ES tikslas ir naujos investicijos. Kartais Rūšiavime pasirodys mišrių atliekų – išrūšiuok jas! Sėkmės!"),
			"target": func(): return _ctl_rect([hud.year_label, hud.year_fill]), "r": 0.0, "wait": ""},
	]
	_build()
	_go(0)

func _build() -> void:
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Hud.T_SURF, 0.97)
	sb.border_color = Color(Hud.T_ACC, 0.8)
	sb.set_border_width_all(1)
	sb.border_width_left = 4
	sb.set_corner_radius_all(12)
	sb.anti_aliasing = true
	sb.content_margin_left = 18
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 14
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble.custom_minimum_size = Vector2(340, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bubble)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_bubble.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 19)
	_title.add_theme_color_override("font_color", Hud.T_TEXT)
	if bold != null:
		_title.add_theme_font_override("font", bold)
	vb.add_child(_title)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 14)
	_text.add_theme_color_override("font_color", Hud.T_MUTED.lightened(0.18))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(308, 0)
	vb.add_child(_text)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	_skip_btn = Button.new()
	_skip_btn.text = Loc.t("Praleisti vedlį")
	_skip_btn.flat = true
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_skip_btn.add_theme_color_override("font_color", Hud.T_MUTED)
	_skip_btn.add_theme_color_override("font_hover_color", Hud.T_TEXT)
	_skip_btn.add_theme_font_size_override("font_size", 13)
	_skip_btn.pressed.connect(finish)
	hb.add_child(_skip_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_next_btn = Button.new()
	_next_btn.focus_mode = Control.FOCUS_NONE
	_next_btn.custom_minimum_size = Vector2(110, 34)
	var nb := StyleBoxFlat.new()
	nb.bg_color = Hud.T_ACC_FILL
	nb.set_corner_radius_all(10)
	nb.anti_aliasing = true
	var nh := nb.duplicate()
	nh.bg_color = Hud.T_ACC_FILL.lightened(0.12)
	_next_btn.add_theme_stylebox_override("normal", nb)
	_next_btn.add_theme_stylebox_override("hover", nh)
	_next_btn.add_theme_stylebox_override("pressed", nb)
	_next_btn.add_theme_color_override("font_color", Color.WHITE)
	_next_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_next_btn.pressed.connect(func(): Sfx.play("click"); _go(_step + 1))
	hb.add_child(_next_btn)

## Screen rectangle covering the given controls (in this control's coordinates).
func _ctl_rect(ctls: Array) -> Rect2:
	var r := Rect2()
	for c in ctls:
		if c == null or not (c is Control):
			continue
		var cr: Rect2 = (c as Control).get_global_rect()
		cr.position -= get_global_rect().position
		r = cr if r.size == Vector2.ZERO else r.merge(cr)
	return r.grow(8.0)

func _go(i: int) -> void:
	if i >= _steps.size():
		finish()
		return
	_step = i
	var s: Dictionary = _steps[i]
	_title.text = s["title"]
	_text.text = s["text"]
	var waiting := str(s["wait"]) != ""
	_next_btn.visible = not waiting
	_next_btn.text = Loc.t("Pradėti!") if i == _steps.size() - 1 else Loc.t("Toliau")
	_target_r = _read_radius(s["r"])
	# shrink the bubble to fit the new text (a PanelContainer never shrinks by itself)
	_bubble.size = Vector2.ZERO
	_bubble.reset_size.call_deferred()
	if str(s["wait"]) == "bonus":
		game.tutorial_spawn_bonus()
	Sfx.play("whoosh", 0.0)

## Called by the game when the player does something.
func notify(what: String) -> void:
	if _step < 0 or _step >= _steps.size():
		return
	if str(_steps[_step]["wait"]) == what:
		if what == "work":
			_clicks += 1
			_text.text = str(_steps[_step]["text"]) + Loc.t("\n\nPaspausta: %d / 3") % _clicks
			if _clicks < 3:
				return
		_go(_step + 1)

func finish() -> void:
	Settings.set_value("tutorial_done", true)
	done.emit()
	queue_free()

func _process(delta: float) -> void:
	_t += delta
	if _step >= 0:
		var s: Dictionary = _steps[_step]
		_target_r = _read_radius(s["r"])
		var tf: Callable = s["target"]
		var tv = tf.call()
		if tv is Rect2:
			_rect = tv
			_target = _rect.get_center()
		else:
			_rect = Rect2()
			_target = tv
	# place bubble near the target but inside the screen
	var vp := get_viewport_rect().size
	var bs := _bubble.size
	var half := Vector2(_target_r, _target_r)
	if _rect.size != Vector2.ZERO:
		half = _rect.size * 0.5
	var p := _target + Vector2(half.x + 30.0, -bs.y * 0.5)
	if p.x + bs.x > vp.x - 10.0:
		p.x = _target.x - half.x - 30.0 - bs.x
		if _rect.size != Vector2.ZERO:
			p.y = clampf(_rect.position.y, 10.0, vp.y - bs.y - 10.0)
	if p.x < 10.0:
		p.x = clampf(_target.x - bs.x * 0.5, 10.0, vp.x - bs.x - 10.0)
		p.y = _target.y + half.y + 24.0
		if p.y + bs.y > vp.y - 10.0:
			p.y = _target.y - half.y - 24.0 - bs.y
	p.y = clampf(p.y, 10.0, vp.y - bs.y - 10.0)
	_bubble.position = p
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := _target_r + 6.0 * pulse
	if _rect.size != Vector2.ZERO:
		# rectangle highlight hugging the real UI element
		var g := _rect.grow(3.0 * pulse)
		_rounded_rect(g, Color(1.0, 0.9, 0.4, 0.9), 4.0)
		_rounded_rect(g.grow(8.0), Color(1.0, 0.9, 0.4, 0.35 * pulse), 3.0)
		r = minf(g.size.x, g.size.y) * 0.5
	else:
		draw_arc(_target, r, 0.0, TAU, 64, Color(1.0, 0.9, 0.4, 0.9), 4.0, true)
		draw_arc(_target, r + 10.0, 0.0, TAU, 64, Color(1.0, 0.9, 0.4, 0.35 * pulse), 3.0, true)
	# connector from bubble to the highlight
	var bc := _bubble.position + _bubble.size * 0.5
	var dir := (bc - _target).normalized()
	var from := _target + dir * (r + 4.0)
	if _rect.size != Vector2.ZERO:
		from = _edge_point(_rect.grow(6.0), dir)
	var to := bc - dir * minf(_bubble.size.x, _bubble.size.y) * 0.45
	if from.distance_to(to) > 10.0:
		draw_line(from, to, Color(1.0, 0.9, 0.4, 0.8), 3.0, true)
		var a := dir.angle()
		var tip := from
		draw_colored_polygon(PackedVector2Array([
			tip, tip + Vector2.from_angle(a + 0.45) * 14.0, tip + Vector2.from_angle(a - 0.45) * 14.0]),
			Color(1.0, 0.9, 0.4, 0.95))


func _rounded_rect(r: Rect2, c: Color, w: float) -> void:
	var k := 10.0
	var pts := PackedVector2Array()
	var corners := [r.position + Vector2(k, k), Vector2(r.end.x - k, r.position.y + k), r.end - Vector2(k, k), Vector2(r.position.x + k, r.end.y - k)]
	var starts := [PI, PI * 1.5, 0.0, PI * 0.5]
	for i in 4:
		for s in 7:
			var a: float = starts[i] + PI * 0.5 * float(s) / 6.0
			pts.append(corners[i] + Vector2(cos(a), sin(a)) * k)
	pts.append(pts[0])
	draw_polyline(pts, c, w, true)

## Point where a ray from the rect centre in direction d leaves the rect.
func _edge_point(r: Rect2, d: Vector2) -> Vector2:
	var c := r.get_center()
	var h := r.size * 0.5
	var tx := h.x / maxf(absf(d.x), 0.0001)
	var ty := h.y / maxf(absf(d.y), 0.0001)
	return c + d * minf(tx, ty)

func _read_radius(value: Variant) -> float:
	return float(value.call()) if value is Callable else float(value)
