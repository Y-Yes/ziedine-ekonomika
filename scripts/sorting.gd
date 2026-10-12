## Sorting
##
## Mini-game: a batch of mixed waste arrives at the sorting station. Drag each
## item into the correct Lithuanian bin (yellow – plastic & metal, green –
## glass, blue – paper) – or just click the bin. Time slows down in the main
## game meanwhile. Correct items earn money with a combo multiplier and reduce
## pollution; wrong ones end up in the landfill.
class_name Sorting
extends Control

signal finished(correct: int, total: int, money: float)

const ITEMS_TEX := "res://art/rusiavimas_daiktai.png"
const BINS_TEX := "res://art/konteineriai.png"
const ITEMS := [
	{"name": "PET butelis", "bin": 0},
	{"name": "Skardinė", "bin": 0},
	{"name": "Stiklainis", "bin": 1},
	{"name": "Stiklo butelis", "bin": 1},
	{"name": "Laikraštis", "bin": 2},
	{"name": "Kartono dėžė", "bin": 2},
]
const BIN_NAMES := ["PLASTIKAS IR METALAS", "STIKLAS", "POPIERIUS"]
const BIN_COLORS := [Color("f2c81e"), Color("27a855"), Color("2f72c8")]
const TIME := 15.0
const REWARD := 3.0

var game: Node
var font: Font
var bold: Font

var _items_tex: Texture2D
var _bins_tex: Texture2D
var _queue: Array[int] = []
var _total: int = 0
var _correct: int = 0
var _combo: int = 0
var _money: float = 0.0
var _time_left: float = TIME
var _done: bool = false
var _done_t: float = 0.0

# current item
var _cur: int = -1
var _pos: Vector2
var _home: Vector2
var _appear: float = 0.0
var _drag: bool = false
var _drag_off: Vector2
var _fly: float = -1.0
var _fly_from: Vector2
var _fly_to: Vector2
var _fly_ok: bool = false
var _shake: float = 0.0

var _bin_open: Array[float] = [0.0, 0.0, 0.0]
var _bin_flash: Array[float] = [0.0, 0.0, 0.0]
var _bin_ok: Array[bool] = [true, true, true]
var _tip: String = ""
var _tip_t: float = 0.0
var _hover_bin: int = -1
var _t: float = 0.0

var _panel: Rect2

func open(g: Node, count: int, f: Font, fb: Font) -> void:
	game = g
	font = f
	bold = fb
	_items_tex = load(ITEMS_TEX) if ResourceLoader.exists(ITEMS_TEX) else null
	_bins_tex = load(BINS_TEX) if ResourceLoader.exists(BINS_TEX) else null
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var vp := get_viewport_rect().size
	_panel = Rect2(vp.x * 0.5 - 320.0, 70.0, 640.0, 548.0)
	_home = Vector2(vp.x * 0.5, 248.0)
	_queue.clear()
	for i in count:
		_queue.append(randi() % ITEMS.size())
	_total = count
	_next_item()
	Sfx.play("sort_open", 0.0)

func _bin_rect(i: int) -> Rect2:
	var cx := _panel.position.x + _panel.size.x * 0.5 + (float(i) - 1.0) * 200.0
	return Rect2(cx - 80.0, _panel.position.y + 316.0, 160.0, 160.0)

func _bin_at(p: Vector2) -> int:
	for i in 3:
		if _bin_rect(i).grow(10.0).has_point(p):
			return i
	return -1

func _next_item() -> void:
	if _queue.is_empty():
		_finish()
		return
	_cur = _queue.pop_front()
	_pos = _home
	_appear = 0.0
	_drag = false
	_fly = -1.0

func _finish() -> void:
	_cur = -1
	_done = true
	_done_t = 0.0
	if _correct == _total and _total > 0:
		_money += 10.0
		Juice.confetti(self, _panel.get_center(), 40)
		Sfx.play("confetti", 0.0)

func _drop_into(bin: int) -> void:
	if _cur < 0 or _fly >= 0.0:
		return
	_drag = false
	var ok: bool = int(ITEMS[_cur]["bin"]) == bin
	_fly_from = _pos
	_fly_to = _bin_rect(bin).position + Vector2(80, 40)
	_fly = 0.0
	_fly_ok = ok
	_bin_open[bin] = 1.0
	_bin_flash[bin] = 1.0
	_bin_ok[bin] = ok
	if ok:
		_correct += 1
		_combo += 1
		var mult := 1.0 + 0.5 * float(mini(_combo - 1, 2))
		var m := REWARD * mult
		_money += m
		Sfx.play("sort_ok", 0.03, 1.0 + 0.08 * float(mini(_combo, 5)))
		var txt := "+€%s" % (str(int(m)) if m == floor(m) else "%.1f" % m)
		if _combo >= 2:
			txt += "  ×%.1f" % mult
		FloatText.spawn(self, _fly_to + Vector2(0, 40), txt, Color(0.55, 1.0, 0.6), 20)
	else:
		_combo = 0
		Sfx.play("sort_bad", 0.0)
		var correct_bin: int = ITEMS[_cur]["bin"]
		_tip = "%s – į %s konteinerį (%s)" % [ITEMS[_cur]["name"],
			["geltoną", "žalią", "mėlyną"][correct_bin], BIN_NAMES[correct_bin].to_lower()]
		_tip_t = 3.0
		FloatText.spawn(self, _fly_to + Vector2(0, 40), "Klaida!", Color(1.0, 0.45, 0.4), 22)
		if game != null:
			game.sorting_mistake(_cur)

func _gui_input(ev: InputEvent) -> void:
	if _done:
		if ev is InputEventMouseButton and ev.pressed and _done_t > 0.6:
			_close()
		accept_event()
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			if _cur >= 0 and _fly < 0.0 and ev.position.distance_to(_pos) < 56.0:
				_drag = true
				_drag_off = _pos - ev.position
				Sfx.play("click")
			else:
				var b := _bin_at(ev.position)
				if b >= 0:
					_drop_into(b)
		else:
			if _drag:
				var b2 := _bin_at(_pos)
				if b2 >= 0:
					_drop_into(b2)
				else:
					_drag = false
		accept_event()
	elif ev is InputEventMouseMotion:
		_hover_bin = _bin_at(ev.position)
		if _drag:
			_pos = ev.position + _drag_off
			_hover_bin = _bin_at(_pos)
		accept_event()

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_1, KEY_KP_1:
				_drop_into(0)
			KEY_2, KEY_KP_2:
				_drop_into(1)
			KEY_3, KEY_KP_3:
				_drop_into(2)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_t += delta
	for i in 3:
		_bin_open[i] = maxf(0.0, _bin_open[i] - delta * 2.5)
		_bin_flash[i] = maxf(0.0, _bin_flash[i] - delta * 2.0)
	_tip_t = maxf(0.0, _tip_t - delta)
	_shake = maxf(0.0, _shake - delta * 4.0)
	if _done:
		_done_t += delta
		if _done_t > 2.8:
			_close()
		queue_redraw()
		return
	_time_left -= delta
	if _time_left <= 0.0:
		# Time is up: the remaining items go unsorted to the landfill.
		var left := _queue.size() + (1 if _cur >= 0 else 0)
		for i in left:
			if game != null:
				game.sorting_mistake(-1)
		_queue.clear()
		_combo = 0
		Sfx.play("sort_bad", 0.0)
		_finish()
	_appear = minf(1.0, _appear + delta * 4.0)
	if _fly >= 0.0:
		_fly += delta * 3.5
		var u := minf(_fly, 1.0)
		var arc := Vector2(0, -80.0 * sin(u * PI))
		_pos = _fly_from.lerp(_fly_to, u) + arc
		if _fly >= 1.0:
			_next_item()
	queue_redraw()

func _close() -> void:
	if not is_inside_tree():
		return
	finished.emit(_correct, _total, _money)
	queue_free()

func _draw() -> void:
	var f := font if font != null else ThemeDB.fallback_font
	var fb := bold if bold != null else f
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.02, 0.03, 0.06, 0.6))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.15, 0.97)
	sb.border_color = Color("d9c94a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 18
	draw_style_box(sb, _panel)

	var cx := _panel.get_center().x
	_text(fb, "MIŠRIOS ATLIEKOS!", Vector2(cx, _panel.position.y + 42.0), 28, Color("ffe36a"))
	_text(f, "Nutempk daiktą į teisingą konteinerį (arba spausk konteinerį / klavišus 1–3)",
		Vector2(cx, _panel.position.y + 68.0), 14, Color(0.78, 0.84, 0.92))

	# timer bar
	var bar := Rect2(_panel.position.x + 40.0, _panel.position.y + 82.0, _panel.size.x - 80.0, 8.0)
	draw_rect(bar, Color(0.18, 0.2, 0.26))
	var frac := clampf(_time_left / TIME, 0.0, 1.0)
	var tc := Color(0.45, 0.9, 0.55) if frac > 0.35 else Color(1.0, 0.5, 0.35)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), tc)

	# progress + combo
	var prog := "Daiktas %d / %d" % [mini(_total - _queue.size(), _total), _total]
	draw_string(f, Vector2(_panel.position.x + 40.0, _panel.position.y + 114.0), prog, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color(0.75, 0.82, 0.9))
	if _combo >= 2:
		var ck := 1.0 + 0.1 * sin(_t * 10.0)
		var ct := "KOMBO ×%.1f" % (1.0 + 0.5 * float(mini(_combo - 1, 2)))
		draw_string(fb, Vector2(_panel.end.x - 170.0, _panel.position.y + 116.0), ct, HORIZONTAL_ALIGNMENT_LEFT, -1,
			int(18 * ck), Color(1.0, 0.8, 0.3))

	# bins
	for i in 3:
		var r := _bin_rect(i)
		var hop := -6.0 * _bin_flash[i] if _bin_ok[i] else 0.0
		var shake_x := sin(_t * 60.0) * 5.0 * _bin_flash[i] if not _bin_ok[i] else 0.0
		var rr := Rect2(r.position + Vector2(shake_x, hop), r.size)
		if _hover_bin == i and _cur >= 0:
			draw_circle(r.get_center() + Vector2(0, 20), 86.0, Color(BIN_COLORS[i], 0.18))
		if _bins_tex != null:
			var bw := float(_bins_tex.get_width()) / 6.0
			var idx := i + (3 if _bin_open[i] > 0.05 or (_hover_bin == i and _drag) else 0)
			draw_texture_rect_region(_bins_tex, rr, Rect2(bw * idx, 0, bw, float(_bins_tex.get_height())))
		if _bin_flash[i] > 0.0:
			var fc := Color(0.4, 1.0, 0.5, 0.35 * _bin_flash[i]) if _bin_ok[i] else Color(1.0, 0.3, 0.25, 0.4 * _bin_flash[i])
			draw_circle(r.get_center() + Vector2(0, 20), 80.0, fc)
		_text(fb, BIN_NAMES[i], Vector2(r.get_center().x, r.end.y + 18.0), 13, BIN_COLORS[i].lightened(0.25))
		_text(f, str(i + 1), Vector2(r.get_center().x, r.position.y + 6.0), 12, Color(1, 1, 1, 0.5))

	# current item
	if _cur >= 0 and _items_tex != null:
		var iw := float(_items_tex.get_width()) / float(ITEMS.size())
		var k := _appear * (1.0 + 0.08 * sin(_t * 5.0)) * (0.6 if _fly >= 0.0 and _fly > 0.6 else 1.0)
		if _drag:
			k *= 1.12
		var sz := 104.0 * k
		if not _drag and _fly < 0.0:
			draw_circle(_pos + Vector2(0, 52), 34.0, Color(0, 0, 0, 0.25))
		draw_texture_rect_region(_items_tex, Rect2(_pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)),
			Rect2(iw * _cur, 0, iw, float(_items_tex.get_height())))
		if _fly < 0.0:
			_text(fb, ITEMS[_cur]["name"], _pos + Vector2(0, 74.0), 17, Color(0.95, 0.97, 1.0))

	# tip after a mistake
	if _tip_t > 0.0:
		_text(fb, _tip, Vector2(cx, _panel.end.y - 18.0), 15, Color(1.0, 0.65, 0.55, minf(1.0, _tip_t)))

	# results
	if _done:
		var rb := Rect2(cx - 220.0, _panel.position.y + 128.0, 440.0, 150.0)
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.05, 0.07, 0.1, 0.97)
		s2.border_color = Color(0.45, 0.9, 0.55) if _correct == _total else Color(1.0, 0.8, 0.3)
		s2.set_border_width_all(2)
		s2.set_corner_radius_all(14)
		draw_style_box(s2, rb)
		var title := "Puikiai! Viskas išrūšiuota!" if _correct == _total else "Išrūšiuota %d / %d" % [_correct, _total]
		_text(fb, title, Vector2(cx, rb.position.y + 44.0), 24, Color(1, 1, 1))
		_text(fb, "+€%d" % int(_money), Vector2(cx, rb.position.y + 84.0), 26, Color(1.0, 0.85, 0.4))
		var extra := "+€10 premija už tobulą rūšiavimą" if _correct == _total else "Neteisingi daiktai iškeliavo į sąvartyną"
		_text(f, extra, Vector2(cx, rb.position.y + 116.0), 13, Color(0.75, 0.82, 0.9))

func _text(f: Font, s: String, center: Vector2, sz: int, col: Color) -> void:
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(center.x - w * 0.5, center.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
