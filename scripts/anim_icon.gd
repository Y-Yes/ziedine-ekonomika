## Investment cards use complete rendered frames, with connected 3D mechanisms.
class_name AnimIcon
extends Control
const CELL := 256
const COLUMNS := 12
var sheet: Texture2D
var frames: int = 16
var fps: float = 10.0
var _t: float = 0.0
var _perk: String = ""
var _whole: bool = false

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func set_sheet(path: String) -> void:
	_perk=""
	_whole=false
	frames=16
	fps=10.0
	sheet=load(path) if ResourceLoader.exists(path) else null
	queue_redraw()

func set_perk(id: String) -> void:
	_perk=id
	var path:="res://art/02b/perk_loops/"+id+".png"
	_whole=ResourceLoader.exists(path)
	if _whole:
		sheet=load(path)
		frames=96
		fps=24.0
	else:
		var index:=GameArt.PERKS.find(id)
		sheet=GameArt.frame("perks",index,4,3) if index>=0 else null
		frames=1
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t+=delta
		queue_redraw()

func _draw() -> void:
	if sheet==null:
		return
	if _whole:
		var side:=minf(size.x,size.y)
		var frame:=int(_t*fps)%frames
		var source:=Rect2((frame%COLUMNS)*CELL,(frame/COLUMNS)*CELL,CELL,CELL)
		draw_texture_rect_region(sheet,Rect2((size-Vector2.ONE*side)*0.5,Vector2.ONE*side),source)
	elif frames==1:
		var fit:=minf(size.x/sheet.get_width(),size.y/sheet.get_height())
		var extent:=sheet.get_size()*fit
		draw_texture_rect(sheet,Rect2((size-extent)*0.5,extent),false)
	else:
		var fw:=float(sheet.get_width())/frames
		var frame:=int(_t*fps)%frames
		draw_texture_rect_region(sheet,Rect2(Vector2.ZERO,size),Rect2(fw*frame,0,fw,sheet.get_height()))
