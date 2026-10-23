## Whole-island atlases: 96 distinct frames, fixed ground, four-second cycles.
class_name StationMotion
extends RefCounted
const SIDE := 512
const COLUMNS := 12
const FRAME_COUNT := 96
const FPS := 24.0
static var _first_frames: Dictionary = {}

static func region(texture: Texture2D, frame: int) -> Rect2:
	# Legacy horizontal sheets remain readable for older previews.
	if texture.get_height() == SIDE:
		return Rect2((frame % maxi(1,texture.get_width()/SIDE))*SIDE,0,SIDE,SIDE)
	return Rect2((frame % COLUMNS)*SIDE,(frame / COLUMNS)*SIDE,SIDE,SIDE)

static func base(_index: int, texture: Texture2D) -> Texture2D:
	var key := texture.get_rid().get_id()
	if not _first_frames.has(key):
		var first := AtlasTexture.new()
		first.atlas = texture
		first.region = region(texture,0)
		first.filter_clip = true
		_first_frames[key] = first
	return _first_frames[key]

static func draw(owner: CanvasItem, _index: int, texture: Texture2D, rect: Rect2, time: float, _working: bool) -> void:
	var count := (texture.get_width()/SIDE)*(texture.get_height()/SIDE)
	var frame := int(floor(time * FPS)) % count
	owner.draw_texture_rect_region(texture,rect,region(texture,frame))
