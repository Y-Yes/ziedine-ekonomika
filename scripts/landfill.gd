## Landfill
##
## Visible pile of everything that fell out of the loop (overflows, floods).
## Starts empty. Every overflow adds one individual object on the dirt.
class_name Landfill
extends Node2D

const BASE_ART := "res://art/02b/landfill_ground_v3.png"
const BASE_W := 150.0
const LIFT := -40.0
const MAX_SHOWN := 240

var count: int = 0
var _items: Array = [] # One individual prop per counter unit, never grouped bales.
var _base: Texture2D
var _loader: Texture2D
var _bump := 0.0
var _time := 0.0

func _ready() -> void:
	z_index = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_base = load(BASE_ART)
	_loader = load("res://art/02b/landfill_loader_v3.png")

func add(form: int) -> void:
	count += 1
	_bump = 1.0
	if _items.size() >= MAX_SHOWN:return
	var rng := RandomNumberGenerator.new()
	rng.seed = count * 7919
	var n := _items.size()
	# Eighteen separate positions fill the dirt before the next layer grows.
	# A permuted grid avoids covering the previous item on every arrival.
	var slot := (n * 7) % 18
	var row := slot / 6
	var col := slot % 6
	var layer := n / 18
	var pos := Vector2(-46.0 + col * 8.0 + row * 2.5, -7.0 + row * 8.0 - col * 3.0)
	pos += Vector2(rng.randf_range(-1.5,1.5),rng.randf_range(-1.0,1.0)-layer*5.5)
	# All of these sprites show exactly one discarded object.
	var single: int = posmod(form+rng.randi_range(0,5),6)
	_items.append({"pos":pos,"single":single,"rot":rng.randf_range(-0.55,0.55),"size":rng.randf_range(16.0,19.0),"age":0.0})
	_items.sort_custom(func(a: Dictionary,b: Dictionary):return a.pos.y<b.pos.y)

func reset() -> void:
	count = 0
	_items.clear()

func _process(delta: float) -> void:
	_time += delta
	_bump = maxf(0.0,_bump-delta*3.0)
	for item in _items:item.age=minf(1.0,float(item.age)+delta*2.5)
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Ground: a small floating junk island (falls back to a flat mound)
	if _base != null:
		draw_texture_rect(_base, Rect2(-BASE_W * 0.5, LIFT - BASE_W * 0.52, BASE_W, BASE_W), false)
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-70, 6), Vector2(-60, -2), Vector2(60, -2), Vector2(70, 6)]), Color(0.2, 0.17, 0.14, 0.9))
	# The loader travels along the right-hand dirt lane. The island never moves.
	var travel := 0.5-0.5*cos(_time*TAU/7.0)
	var vehicle_offset := Vector2(-5.0*travel,2.5*travel)
	if _loader != null:
		draw_texture_rect(_loader,Rect2(Vector2(0,-82)+vehicle_offset,Vector2.ONE*66),false)
	for j in 4:
		var phase := fmod(_time*0.36+j*0.25,1.0)
		var smoke := Vector2(52,-65)+vehicle_offset+Vector2(phase*6,-phase*15)
		draw_circle(smoke,1.2+phase*2,Color(0.60,0.65,0.69,0.20*(1-phase)))
	for item in _items:
		var off: Vector2 = item.pos
		var age: float = item.age
		var size: float = item.size
		var fall := pow(1.0-age,2.0)*24.0
		var p := Vector2(0,LIFT+8)+off
		draw_set_transform(p,0,Vector2(1,0.38))
		draw_circle(Vector2.ZERO,size*0.24,Color(0.21,0.15,0.08,0.20*age))
		draw_set_transform(p-Vector2(0,fall),float(item.rot))
		draw_texture_rect(GameArt.frame("landfill_litter_v3",int(item.single)),Rect2(-size*0.5,-size*0.8,size,size),false,Color(0.96,0.94,0.89))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	var txt := Loc.t("Sąvartynas: %d") % count
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	var k2 := 1.0 + 0.15 * _bump
	draw_string_outline(font, Vector2(-w * 0.5 * k2, 22.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(13 * k2), 5,
		Color(0.04, 0.06, 0.1, 0.9))
	draw_string(font, Vector2(-w * 0.5 * k2, 22.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(13 * k2),
		Color(0.85, 0.7, 0.55) if count > 0 else Color(0.55, 0.6, 0.68))
