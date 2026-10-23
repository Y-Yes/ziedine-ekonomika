## Bake high-resolution whole-island frames. Architecture is never UV-warped.
extends SceneTree
const NAMES := ["1_naudotojas","2_surinkimas","3_rusiavimas","4_perdirbimas","5_gamykla","6_parduotuve"]
const OUT := "res://art/02b/approved_loops/"
const SIDE := 512
const FRAMES := 96
const COLS := 12
var phase := 0.0
var layers: Array[Sprite2D] = []

func _initialize() -> void:
	call_deferred("run")

func sprite(viewport: SubViewport, path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load("res://art/02b/" + path + ".png")
	s.centered = false
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.scale = Vector2.ONE * SIDE / s.texture.get_width()
	viewport.add_child(s)
	layers.append(s)
	return s

func quad_point(q: PackedVector2Array, u: float, v: float) -> Vector2:
	return q[0].lerp(q[1],u).lerp(q[3].lerp(q[2],u),v)

func section(q: PackedVector2Array, left: float, top: float, right: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([quad_point(q,left,top),quad_point(q,right,top),quad_point(q,right,bottom),quad_point(q,left,bottom)])

func textured_quad(node: Node2D, dest: PackedVector2Array, uv: PackedVector2Array, tex: Texture2D) -> void:
	var points:=PackedVector2Array()
	for p in dest:
		points.append(p*SIDE)
	node.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,tex)

func doorway(node: Node2D, q: PackedVector2Array, kind: int, tex: Texture2D) -> void:
	var opening: float = 0.5-0.5*cos(phase*TAU)
	# A recessed interior is painted only inside the original opening. Frames,
	# masonry and surrounding windows remain the untouched source illustration.
	var points:=PackedVector2Array()
	for p in q:
		points.append(p*SIDE)
	var warm := kind==5
	var ceiling:=Color(0.24,0.20,0.15) if warm else Color(0.15,0.13,0.10)
	var floor_color:=Color(0.57,0.43,0.26) if warm else Color(0.25,0.25,0.24)
	node.draw_polygon(points,PackedColorArray([ceiling,ceiling,floor_color,floor_color]))
	if warm:
		# Recessed entrance with a clear floor and side reveals. No shelf is
		# pasted immediately behind the opening or duplicated from the window.
		var floor_points:=PackedVector2Array([quad_point(q,0,1)*SIDE,quad_point(q,1,1)*SIDE,quad_point(q,0.82,0.72)*SIDE,quad_point(q,0.18,0.72)*SIDE])
		node.draw_polygon(floor_points,PackedColorArray([Color(0.43,0.37,0.29),Color(0.43,0.37,0.29),Color(0.26,0.23,0.19),Color(0.26,0.23,0.19)]))
	if kind==0:
		# Knob is on the left: the right edge is the fixed hinge. The complete
		# door leaf narrows toward that hinge, within the measured door frame.
		var free_edge:=opening*0.80
		var leaf:=PackedVector2Array([quad_point(q,free_edge,opening*0.04),q[1],q[2],quad_point(q,free_edge,1.0-opening*0.04)])
		textured_quad(node,leaf,q,tex)
	elif kind==5:
		# Both leaves slide apart along the same facade plane. Clip each leaf
		# at the opening's outer jamb so it disappears behind the fixed glazing.
		var slide:=opening*0.43
		textured_quad(node,section(q,0,0,0.5-slide,1),section(q,slide,0,0.5,1),tex)
		textured_quad(node,section(q,0.5+slide,0,1,1),section(q,0.5,0,1-slide,1),tex)
	else:
		# The shutter travels upward, retaining the spacing of all metal slats.
		var rise:=opening*0.78
		textured_quad(node,section(q,0,0,1,1-rise),section(q,0,rise,1,1),tex)

func details(node: Node2D, index: int, tex: Texture2D) -> void:
	if index==5:
		doorway(node,PackedVector2Array([Vector2(0.379,0.459),Vector2(0.519,0.504),Vector2(0.519,0.650),Vector2(0.379,0.605)]),index,tex)
	elif index==4:
		doorway(node,PackedVector2Array([Vector2(0.301,0.556),Vector2(0.350,0.575),Vector2(0.350,0.647),Vector2(0.301,0.628)]),index,tex)
	if index!=4 and index!=0:
		return
	var foot:=Vector2(0.75,0.16) if index==4 else Vector2(0.655,0.225)
	for j in 6:
		var p:=fposmod(phase*2.0+j/6.0,1.0)
		var position:=(foot+Vector2(p*0.045,-p*0.16))*SIDE
		var radius:=SIDE*(0.012+p*0.025)
		# Soft puffs have a smooth alpha falloff, avoiding hard circular blobs.
		for ring in range(8,0,-1):
			node.draw_circle(position,radius*ring/8.0,Color(0.83,0.9,0.96,sin(p*PI)*(1.0-p)*0.16))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var viewport:=SubViewport.new()
	# Render at 1024 and resolve to 512: antialias the moving door edges and
	# robot silhouette without relying on unsupported Compatibility MSAA.
	viewport.size=Vector2i(SIDE*2,SIDE*2)
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.canvas_transform=Transform2D().scaled(Vector2.ONE*2.0)
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
uniform float phase=0.0;
uniform int kind=0;
void fragment() {
 vec2 uv=UV;
 vec4 original=texture(TEXTURE,uv);
 // No colour-keyed whole-image distortion: roofs, chimney, walls and trees
 // remain pixel-registered. Only the bounded machine surfaces are animated.
 vec4 color=texture(TEXTURE,uv);
 if(kind==3) {
  // Carry the illustrated fragments and belt ribs along the actual top
  // plane. Invert its four measured corners; the housing/rails never move.
  vec2 a=vec2(0.565,0.450), b=vec2(0.616,0.425);
  vec2 c=vec2(0.787,0.504), d=vec2(0.719,0.540);
  vec2 ab=b-a, ad=d-a, curve=a-b+c-d;
  vec2 local=vec2(0.5,0.5);
  for(int i=0;i<4;i++) {
   vec2 error=a+ab*local.x+ad*local.y+curve*local.x*local.y-UV;
   vec2 dx=ab+curve*local.y, dy=ad+curve*local.x;
   float determinant=dx.x*dy.y-dx.y*dy.x;
   local-=vec2(error.x*dy.y-error.y*dy.x,dx.x*error.y-dx.y*error.x)/determinant;
  }
  if(local.x>0.04 && local.x<0.96 && local.y>0.02 && local.y<0.98) {
   float travel=fract(local.y-phase*2.0);
   vec2 source=mix(mix(a,b,local.x),mix(d,c,local.x),travel);
   color=texture(TEXTURE,source);
  }
  // Moving highlights on the metal teeth, with ZERO texture displacement.
  // The casing, hopper, bales, sacks and their outlines stay unchanged.
  float rollers=step(0.32,UV.x)*step(UV.x,0.46)*step(0.425,UV.y)*step(UV.y,0.495);
  rollers*=step(abs(color.r-color.g),0.05)*step(abs(color.g-color.b),0.07);
  color.rgb*=1.0+rollers*0.13*sin((UV.y*90.0-phase*4.0)*6.283185);
 }
 if(kind==2) {
  float belt=step(0.25,UV.y)*step(UV.y,0.64)*step(0.19,UV.x)*step(UV.x,0.89);
  belt*=step(color.r,0.39)*step(color.g,0.39)*step(color.b,0.43)*step(0.15,color.r);
  color.rgb*=1.0+belt*0.11*sin((UV.x*45.0-phase*4.0)*6.283185);
 }
 COLOR=color;
}"""
	var requested := -1
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--station="):
			requested = argument.trim_prefix("--station=").to_int()
	for index in 6:
		if requested>=0 and index!=requested:
			continue
		var picture:=sprite(viewport,"collection_ground" if index==1 else "sorting_ground" if index==2 else NAMES[index])
		var material:=ShaderMaterial.new()
		material.shader=shader
		material.set_shader_parameter("kind",index)
		picture.material=material
		var truck: Sprite2D
		var arm: Sprite2D
		if index==1:
			truck=sprite(viewport,"collection_truck")
			truck.scale*=0.60
			var bins:=sprite(viewport,"collection_bins")
			bins.scale*=0.70
			bins.position=Vector2(0.115,0.174)*SIDE
		if index==2:
			arm=sprite(viewport,"sorting_arm")
			arm.offset=-Vector2(0.664,0.313)*arm.texture.get_width()
			arm.position=Vector2(0.596,0.341)*SIDE
		var effects:=Node2D.new()
		viewport.add_child(effects)
		effects.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		effects.draw.connect(func(): details(effects,index,picture.texture))
		var atlas:=Image.create(SIDE*COLS,SIDE*(FRAMES/COLS),false,Image.FORMAT_RGBA8)
		var registered_ground: Image
		for frame in FRAMES:
			phase=float(frame)/FRAMES
			material.set_shader_parameter("phase",phase)
			if truck!=null:
				# Entire wheel contact patch stays inside the paved lane. Route
				# starts to the right/front of the tree; never reverse into it.
				var travel:=(0.5-0.5*cos(phase*TAU))*0.025
				truck.position=Vector2(0.25+travel,0.075+travel*0.5)*SIDE
			if arm!=null:
				arm.rotation=sin(phase*TAU)*0.22
			effects.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var image:=viewport.get_texture().get_image()
			image.resize(SIDE,SIDE,Image.INTERPOLATE_LANCZOS)
			var ground_y:=int(SIDE*0.80)
			if frame==0:
				registered_ground=image.duplicate()
			else:
				image.blit_rect(registered_ground,Rect2i(0,ground_y,SIDE,SIDE-ground_y),Vector2i(0,ground_y))
			atlas.blit_rect(image,Rect2i(0,0,SIDE,SIDE),Vector2i((frame%COLS)*SIDE,(frame/COLS)*SIDE))
		assert(atlas.save_png(OUT+NAMES[index]+".png")==OK)
		print("HIRES_LOOP_OK ",NAMES[index]," frames=",FRAMES," side=",SIDE)
		for layer in layers:
			layer.free()
		layers.clear()
		effects.free()
	quit()
