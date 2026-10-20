## Coach
##
## Continuation of the guide: the first time something new happens (a fire, a
## strike, mixed waste, the first landfill item…) a speech bubble points at it
## and explains what to do. Dangerous moments freeze the game until the player
## has tried it, so learning costs nothing. Only active in games started with
## the guide ("Rodyti vedlį").
class_name Coach
extends Control

signal tip_closed

var game: Node
var hud: Node
var font: Font
var bold: Font

var _tip: Dictionary = {}
var _bubble: PanelContainer
var _title: Label
var _text: Label
var _ok_btn: Button
var _skip_btn: Button
var _t: float = 0.0
var _target := Vector2.ZERO
var _target_r := 50.0
var _rect := Rect2()

func setup(g: Node, h: Node, f: Font, fb: Font) -> void:
	game = g
	hud = h
	font = f
	bold = fb
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false

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
	_skip_btn.text = Loc.t("Daugiau nerodyti patarimų")
	_skip_btn.flat = true
	_skip_btn.focus_mode = Control.FOCUS_NONE
	_skip_btn.add_theme_color_override("font_color", Hud.T_MUTED)
	_skip_btn.add_theme_color_override("font_hover_color", Hud.T_TEXT)
	_skip_btn.add_theme_font_size_override("font_size", 13)
	_skip_btn.pressed.connect(func(): hud.coach_disable())
	hb.add_child(_skip_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_ok_btn = Button.new()
	_ok_btn.focus_mode = Control.FOCUS_NONE
	_ok_btn.custom_minimum_size = Vector2(110, 34)
	_ok_btn.text = Loc.t("Supratau")
	var nb := StyleBoxFlat.new()
	nb.bg_color = Hud.T_ACC_FILL
	nb.set_corner_radius_all(10)
	nb.anti_aliasing = true
	var nh := nb.duplicate()
	nh.bg_color = Hud.T_ACC_FILL.lightened(0.12)
	_ok_btn.add_theme_stylebox_override("normal", nb)
	_ok_btn.add_theme_stylebox_override("hover", nh)
	_ok_btn.add_theme_stylebox_override("pressed", nb)
	_ok_btn.add_theme_color_override("font_color", Color.WHITE)
	_ok_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_ok_btn.pressed.connect(func(): Sfx.play("click"); close())
	hb.add_child(_ok_btn)

func is_active() -> bool:
	return not _tip.is_empty()

## tip: {title, text, target: Callable -> Vector2|Rect2, r, done: Callable -> bool,
##       button: bool, freeze: bool, on_close: Callable}
func show_tip(tip: Dictionary) -> void:
	_tip = tip
	_title.text = str(tip["title"])
	_text.text = str(tip["text"])
	_ok_btn.visible = bool(tip.get("button", true))
	_target_r = float(tip.get("r", 50.0))
	_bubble.size = Vector2.ZERO
	_bubble.reset_size.call_deferred()
	visible = true
	get_parent().move_child(self, -1)   # above the sorting game and panels
	if bool(tip.get("freeze", false)):
		game.coach_freeze = true
	Sfx.play("whoosh", 0.0)
	_t = 0.0

func close() -> void:
	if _tip.is_empty():
		return
	var oc = _tip.get("on_close")
	_tip = {}
	visible = false
	game.coach_freeze = false
	if oc is Callable and (oc as Callable).is_valid():
		(oc as Callable).call()
	tip_closed.emit()

func _process(delta: float) -> void:
	if _tip.is_empty():
		return
	_t += delta
	var dn = _tip.get("done")
	if dn is Callable and bool((dn as Callable).call()):
		Sfx.play("upgrade", 0.0, 1.2)
		close()
		return
	var pr = _tip.get("progress")
	if pr is Callable:
		_text.text = str(_tip["text"]) + str((pr as Callable).call())
	var tv = (_tip["target"] as Callable).call()
	if tv is Rect2:
		_rect = tv
		_target = _rect.get_center()
	else:
		_rect = Rect2()
		_target = tv
	var vp := get_viewport_rect().size
	var bs := _bubble.size
	var half := Vector2(_target_r, _target_r)
	if _rect.size != Vector2.ZERO:
		half = _rect.size * 0.5
	var p := _target + Vector2(half.x + 30.0, -bs.y * 0.5)
	if p.x + bs.x > vp.x - 10.0:
		p.x = _target.x - half.x - 30.0 - bs.x
	if p.x < 10.0:
		p.x = clampf(_target.x - bs.x * 0.5, 10.0, vp.x - bs.x - 10.0)
		p.y = _target.y + half.y + 24.0
		if p.y + bs.y > vp.y - 10.0:
			p.y = _target.y - half.y - 24.0 - bs.y
	p.y = clampf(p.y, 10.0, vp.y - bs.y - 10.0)
	_bubble.position = p
	queue_redraw()

func _draw() -> void:
	if _tip.is_empty():
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var r := _target_r + 6.0 * pulse
	var col := Hud.T_ACC.lightened(0.15)
	if _rect.size != Vector2.ZERO:
		var g := _rect.grow(3.0 * pulse)
		_rounded_rect(g, Color(col, 0.9), 4.0)
		_rounded_rect(g.grow(8.0), Color(col, 0.35 * pulse), 3.0)
	else:
		draw_arc(_target, r, 0.0, TAU, 64, Color(col, 0.9), 4.0, true)
		draw_arc(_target, r + 10.0, 0.0, TAU, 64, Color(col, 0.35 * pulse), 3.0, true)
	var bc := _bubble.position + _bubble.size * 0.5
	var dir := (bc - _target).normalized()
	var from := _target + dir * (r + 4.0)
	if _rect.size != Vector2.ZERO:
		from = _edge_point(_rect.grow(6.0), dir)
	var to := bc - dir * minf(_bubble.size.x, _bubble.size.y) * 0.45
	if from.distance_to(to) > 10.0:
		draw_line(from, to, Color(col, 0.8), 3.0, true)
		var a := dir.angle()
		draw_colored_polygon(PackedVector2Array([
			from, from + Vector2.from_angle(a + 0.45) * 14.0, from + Vector2.from_angle(a - 0.45) * 14.0]),
			Color(col, 0.95))

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

func _edge_point(r: Rect2, d: Vector2) -> Vector2:
	var c := r.get_center()
	var h := r.size * 0.5
	var tx := h.x / maxf(absf(d.x), 0.0001)
	var ty := h.y / maxf(absf(d.y), 0.0001)
	return c + d * minf(tx, ty)
