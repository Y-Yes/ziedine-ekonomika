## Shared 02B sprite atlases. The original euro coin is deliberately separate.
class_name GameArt
extends RefCounted

const DIR := "res://art/02b/"
const PERKS := ["solar", "repair", "deposit", "education", "bond", "automation",
	"ecolabel", "logistics", "cleantech", "tax", "venture", "firebrigade"]
static var _textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _bounds: Dictionary = {}

static func texture(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := DIR + name + ".png"
		_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[name]

static func frame(name: String, index: int, columns: int = 3, rows: int = 2) -> AtlasTexture:
	var key := "%s:%d:%d:%d" % [name, index, columns, rows]
	if not _frames.has(key):
		var tex := texture(name)
		if tex == null:
			return null
		var cell := tex.get_size() / Vector2(columns, rows)
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(index % columns, index / columns) * cell, cell)
		if name == "sorting_items" and index in [0, 1]:
			var replacement := texture("sorting_pet_v3" if index == 0 else "sorting_can_v3")
			if replacement != null:
				at.atlas = replacement
				at.region = Rect2(Vector2.ZERO, replacement.get_size())
		elif name == "perks":
			# Individually bounded icons: the illustrated atlas is not a perfectly
			# registered grid. Exact regions exclude neighbouring scraps.
			var regions := [Rect2(24,36,350,340), Rect2(400,70,320,295),
				Rect2(752,83,300,292), Rect2(1086,85,350,290),
				Rect2(38,412,340,285), Rect2(398,390,330,315),
				Rect2(765,407,287,310), Rect2(1080,414,355,280),
				Rect2(40,708,330,345), Rect2(399,738,330,317),
				Rect2(760,709,300,350), Rect2(1080,704,350,352)]
			var region: Rect2 = regions[index]
			var scale := tex.get_size() / Vector2(1448,1086)
			at.region = Rect2(region.position * scale, region.size * scale)
		elif name == "bins" and index < 3:
			# Open lids in the following row protrude into the closed row's
			# empty bottom margin. Clip only that margin, without resizing bins.
			at.region.size.y = cell.y * 0.93
			at.margin = Rect2(0,0,0,cell.y * 0.07)
		at.filter_clip = true
		_frames[key] = at
	return _frames[key]

## Tight alpha bounds allow extracted moving layers to retain their exact
## on-island placement even if the source PNG includes a different margin.
static func cutout(name: String) -> AtlasTexture:
	var key := name + ":cutout"
	if not _frames.has(key):
		var tex := texture(name)
		if tex == null:
			return null
		var at := AtlasTexture.new()
		at.atlas = tex
		var mask := BitMap.new()
		mask.create_from_image_alpha(tex.get_image(), 0.2)
		var lo := mask.get_size()
		var hi := Vector2i.ZERO
		for y in range(0, mask.get_size().y, 2):
			for x in range(0, mask.get_size().x, 2):
				if mask.get_bit(x, y):
					lo.x = mini(lo.x, x)
					lo.y = mini(lo.y, y)
					hi.x = maxi(hi.x, x)
					hi.y = maxi(hi.y, y)
		at.region = Rect2(Rect2i(lo, hi - lo + Vector2i(2, 2)))
		at.filter_clip = true
		_frames[key] = at
	return _frames[key]

## Follow the actual bottom corners of each slab, rather than one oversized
## generic diamond shared by six differently shaped pictures.
static func footprint(tex: Texture2D) -> PackedVector2Array:
	var key := str(tex.get_rid().get_id())
	if _bounds.has(key):
		return _bounds[key]
	var image := tex.get_image()
	var mask := BitMap.new()
	mask.create_from_image_alpha(image, 0.3)
	var width := image.get_width()
	var height := image.get_height()
	# get_used_rect() includes nearly invisible stray alpha pixels from the
	# exported artwork. Find the solid slab in the LOWER half with the same
	# alpha threshold as the mask; otherwise side corners can end up at y=0.
	var min_x := width
	var max_x := 0
	var front := Vector2(width * 0.5, height * 0.88)
	var lowest := 0
	for y in range(int(height * 0.5), height, 2):
		for x in range(0, width, 2):
			if mask.get_bit(x, y):
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				if y > lowest and x > width * 0.3 and x < width * 0.7:
					lowest = y
					front = Vector2(x, y)
	var inset := maxi(3, int((max_x - min_x) * 0.012))
	var left := Vector2(min_x + inset, height * 0.62)
	var right := Vector2(max_x - inset, height * 0.62)
	for point in [0, 1]:
		var x := int(left.x if point == 0 else right.x)
		var bottom := int(height * 0.62)
		for y in range(height - 1, int(height * 0.4), -1):
			if mask.get_bit(x, y):
				bottom = y
				break
		if point == 0:
			left.y = bottom
		else:
			right.y = bottom
	var back := left + right - front
	var normalized := PackedVector2Array()
	for p in [back, right, front, left, back]:
		normalized.append(p / Vector2(width, height))
	_bounds[key] = normalized
	return normalized
