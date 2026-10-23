## Fully rendered mechanical card loops: no moving raster cutouts.
extends "res://tools/render_02b_loops.gd"
const IDS := ["solar","repair","deposit","education","bond","automation","ecolabel","logistics","cleantech","tax","venture","firebrigade"]
const DEST := "res://art/02b/perk_loops/"
const PX := 256
const COUNT := 96
var wheels: Array[Node3D] = []

func bevel_box(size: Vector3,bevel: float) -> Mesh:
	var key:="rounded:"+str(size)+str(bevel)
	if meshes.has(key):return meshes[key]
	var r:=minf(bevel,minf(size.x,minf(size.y,size.z))*0.40)
	var cube:=BoxMesh.new()
	cube.size=size
	cube.subdivide_width=32;cube.subdivide_height=24;cube.subdivide_depth=24
	var arrays:=cube.get_mesh_arrays()
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var inner:=size*0.5-Vector3.ONE*r
	for i in vertices.size():
		var nearest:=vertices[i].clamp(-inner,inner)
		var normal:=(vertices[i]-nearest).normalized()
		vertices[i]=nearest+normal*r
		normals[i]=normal
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	meshes[key]=result
	return result

func ball(radius: float, pos: Vector3, color: String, parent: Node3D = null) -> MeshInstance3D:
	var mesh:=SphereMesh.new()
	mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=48;mesh.rings=24
	return part(mesh,pos,color,parent)

func material(hex: String) -> StandardMaterial3D:
	if not materials.has(hex):
		var m:=StandardMaterial3D.new()
		m.albedo_color=Color(hex);m.roughness=0.38
		m.cull_mode=BaseMaterial3D.CULL_DISABLED
		m.metallic=0.45 if hex in ["f3b923","ffd14a","8794a5","c4ced8"] else 0.05
		m.clearcoat_enabled=true;m.clearcoat=0.24;m.clearcoat_roughness=0.25
		materials[hex]=m
	return materials[hex]

func disc(r: float,h: float,pos: Vector3,col: String,parent: Node3D=null) -> MeshInstance3D:
	var n:=cylinder(r,h,pos,col,parent)
	n.rotation.x=PI/2
	return n

func ring_shape(major: float,minor: float,pos: Vector3,col: String,parent: Node3D=null) -> MeshInstance3D:
	var mesh:=TorusMesh.new()
	mesh.inner_radius=major-minor;mesh.outer_radius=major+minor;mesh.rings=48;mesh.ring_segments=16
	var n:=part(mesh,pos,col,parent);n.rotation.x=PI/2
	return n

func text(value: String,pos: Vector3,scale_value: float,col: String,parent: Node3D) -> void:
	var mesh:=TextMesh.new()
	mesh.text=value;mesh.font=load("res://art/fonts/Nunito-ExtraBold.ttf");mesh.font_size=64;mesh.pixel_size=scale_value;mesh.depth=0.012
	part(mesh,pos,col,parent)

func coin(pos: Vector3,parent: Node3D=null,r: float=0.23) -> Node3D:
	var g:=group(pos,parent)
	disc(r,0.055,Vector3.ZERO,"f3b923",g)
	ring_shape(r*0.86,0.012,Vector3(0,0,0.032),"ffd14a",g)
	text("€",Vector3(0,-r*0.46,0.036),r*0.022,"ffd14a",g)
	return g

func leaf(pos: Vector3,parent: Node3D,col: String="70c62b") -> Node3D:
	var g:=group(pos,parent)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var point:=func(u:float,v:float)->Vector3:
		var axis:=Vector2(-0.15,-0.21).lerp(Vector2(0.19,0.26),u)
		var across:=Vector2(0.81,-0.586)*sin(u*PI)*0.18*v
		return Vector3(axis.x+across.x,axis.y+across.y,0.025+sin(u*PI)*0.055*(1-v*v))
	for i in 32:
		for j in 8:
			var u:=float(i)/32;var un:=float(i+1)/32
			var v:=-1.0+j*0.25;var vn:=v+0.25
			var a:Vector3=point.call(u,v);var b:Vector3=point.call(un,v)
			var c:Vector3=point.call(un,vn);var d:Vector3=point.call(u,vn)
			for vertex in [a,b,c,a,c,d]:surface.add_vertex(vertex)
	surface.generate_normals();part(surface.commit(),Vector3.ZERO,col,g)
	for i in 16:
		var a:Vector3=point.call(float(i)/16,0.0);var b:Vector3=point.call(float(i+1)/16,0.0)
		beam(a+Vector3(0,0,0.003),b+Vector3(0,0,0.003),0.007,"d8e9ab",g)
	return g

func gear(pos: Vector3,parent: Node3D,r: float=0.29) -> Node3D:
	var g:=group(pos,parent)
	disc(r*0.77,0.09,Vector3.ZERO,"8794a5",g)
	for i in 10:
		var a:=i*TAU/10
		var n:=box(Vector3(r*0.32,r*0.34,0.10),Vector3(cos(a)*r*0.88,sin(a)*r*0.88,0),"8794a5",g,0.025)
		n.rotation.z=a-PI/2
	disc(r*0.32,0.105,Vector3(0,0,0.009),"253344",g)
	ring_shape(r*0.34,0.015,Vector3(0,0,0.06),"c4ced8",g)
	return g

func joint(pos: Vector3,parent: Node3D,r: float=0.115) -> void:
	disc(r,0.16,pos,"edac12",parent)
	disc(r*0.75,0.175,pos+Vector3(0,0,0.008),"39495d",parent)
	disc(r*0.34,0.181,pos+Vector3(0,0,0.013),"8794a5",parent)
	ring_shape(r*0.83,0.012,pos+Vector3(0,0,0.095),"c4ced8",parent)

func arm_link(length: float,width: float,pos: Vector3,parent: Node3D) -> void:
	var mesh:=CapsuleMesh.new()
	mesh.radius=width*0.5;mesh.height=length;mesh.radial_segments=48;mesh.rings=16
	var n:=part(mesh,pos,"f3b923",parent)
	n.scale.z=0.82

func arm_model() -> void:
	cylinder(0.24,0.09,Vector3(0.16,-0.57,0),"253344")
	cylinder(0.19,0.17,Vector3(0.16,-0.46,0),"8794a5")
	cylinder(0.20,0.045,Vector3(0.16,-0.37,0),"f3b923")
	var shoulder:=group(Vector3(0.16,-0.30,0))
	joint(Vector3.ZERO,shoulder)
	arm_link(0.55,0.18,Vector3(0,0.22,0),shoulder)
	box(Vector3(0.055,0.32,0.15),Vector3(0,0.22,0.008),"ffd14a",shoulder,0.022)
	var elbow:=group(Vector3(0,0.46,0),shoulder)
	joint(Vector3.ZERO,elbow)
	arm_link(0.49,0.15,Vector3(0,0.20,0),elbow)
	var wrist:=group(Vector3(0,0.43,0),elbow)
	joint(Vector3.ZERO,wrist,0.08)
	box(Vector3(0.15,0.13,0.14),Vector3(0,0.10,0),"c4ced8",wrist)
	var claws:Array[Node3D]=[]
	for side in [-1,1]:
		var claw:=group(Vector3(side*0.06,0.14,0),wrist)
		box(Vector3(0.045,0.18,0.075),Vector3(side*0.035,0.07,0),"c4ced8",claw,0.015)
		box(Vector3(0.075,0.045,0.075),Vector3(side*0.02,0.16,0),"39495d",claw,0.01)
		claws.append(claw)
	updates.append(func(t: float):
		shoulder.rotation.z=-0.55+sin(t*TAU)*0.38
		elbow.rotation.z=1.45+sin(t*TAU+0.9)*0.55
		wrist.rotation.z=-0.45-sin(t*TAU+0.4)*0.35
		for i in 2: claws[i].rotation.z=(1 if i==0 else -1)*(0.15+0.35*(0.5-0.5*cos(t*TAU)))
	)

func solar_model() -> void:
	box(Vector3(0.68,0.06,0.46),Vector3(0,-0.51,0),"39495d",null,0.035)
	for x in [-0.22,0.22]:
		cylinder(0.025,0.27,Vector3(x,-0.35,0),"8794a5")
		beam(Vector3(x,-0.47,-0.13),Vector3(x,-0.18,0.06),0.028,"c4ced8",model)
	var panel:=group(Vector3(0,-0.10,0))
	panel.rotation.x=0.65
	box(Vector3(0.94,0.065,0.70),Vector3.ZERO,"8794a5",panel,0.025)
	box(Vector3(0.90,0.016,0.66),Vector3(0,0.039,0),"c4ced8",panel,0.008)
	for x in 4:
		for z in 3:
			var px:=(x-1.5)*0.214;var pz:=(z-1)*0.207
			box(Vector3(0.201,0.010,0.194),Vector3(px,0.052,pz),"103870",panel,0.007)
			for k in [-1,0,1]:
				box(Vector3(0.19,0.002,0.0025),Vector3(px,0.058,pz+k*0.046),"477bb0",panel,0.001)
			box(Vector3(0.003,0.003,0.183),Vector3(px,0.059,pz),"a5bace",panel,0.001)
	for x in [-0.44,0.44]:
		for z in [-0.32,0.32]:ball(0.010,Vector3(x,0.054,z),"39495d",panel)
	# Rays are tapered sunbeams, not a ring of yellow beads.
	var sun:=group(Vector3(0.43,0.43,-0.12))
	var core:=ball(0.165,Vector3.ZERO,"ffc12b",sun);core.scale.z=0.55
	var rays:Array[Node3D]=[]
	for i in 10:
		var a:=i*TAU/10
		var mesh:=CylinderMesh.new();mesh.top_radius=0.007;mesh.bottom_radius=0.026;mesh.height=0.115;mesh.radial_segments=32
		var ray:=part(mesh,Vector3(cos(a)*0.235,sin(a)*0.235,0),"f5a01c",sun)
		ray.rotation.z=a-PI/2;rays.append(ray)
	updates.append(func(t: float):
		# The tracker turns on its real mounting pivot; its slab stays rigid.
		panel.rotation.y=sin(t*TAU)*0.075
		for i in rays.size():rays[i].scale.y=1.0+0.12*sin(t*TAU*2+i*TAU/10)
	)

func repair_model() -> void:
	var cog:=gear(Vector3(-0.07,0,0),model,0.46)
	var wrench:=group(Vector3(0.12,-0.12,0.16))
	wrench.rotation.z=-0.58
	box(Vector3(0.13,0.62,0.08),Vector3(0,-0.08,0),"f3b923",wrench,0.04)
	box(Vector3(0.073,0.32,0.09),Vector3(0,-0.12,0),"39495d",wrench,0.025)
	ring_shape(0.15,0.055,Vector3(0,0.28,0),"c4ced8",wrench)
	updates.append(func(t: float):cog.rotation.z=t*TAU/2;wrench.rotation.z=-0.58+sin(t*TAU)*0.30)

func bottle(parent: Node3D,pos: Vector3) -> Node3D:
	var g:=group(pos,parent)
	cylinder(0.09,0.33,Vector3(0,0.16,0),"7cd6f4",g)
	var shoulder:=ball(0.09,Vector3(0,0.34,0),"7cd6f4",g);shoulder.scale.y=0.55
	cylinder(0.043,0.10,Vector3(0,0.39,0),"7cd6f4",g)
	cylinder(0.049,0.045,Vector3(0,0.45,0),"2276c5",g)
	for y in [0.08,0.14,0.22]: cylinder(0.094,0.018,Vector3(0,y,0),"b1ecf8",g)
	return g

func deposit_model() -> void:
	# Hollow cabinet with an actual round opening; the bottle axis is exactly
	# aligned with it and never crosses a solid side or rear wall.
	box(Vector3(0.64,0.92,0.055),Vector3(0.19,0,-0.165),"32a52a",null,0.04)
	for x in [-0.105,0.485]:box(Vector3(0.05,0.92,0.35),Vector3(x,0,0),"32a52a",null,0.02)
	for y in [-0.435,0.435]:box(Vector3(0.64,0.05,0.35),Vector3(0.19,y,0),"32a52a",null,0.02)
	var front:=CSGCombiner3D.new();model.add_child(front)
	var plate:=CSGBox3D.new();plate.size=Vector3(0.64,0.92,0.04);plate.position=Vector3(0.19,0,0.19);plate.material=material("32a52a");front.add_child(plate)
	var hole:=CSGCylinder3D.new();hole.radius=0.115;hole.height=0.12;hole.sides=48;hole.rotation.x=PI/2;hole.position=Vector3(0.11,0.20,0.19);hole.operation=CSGShape3D.OPERATION_SUBTRACTION;front.add_child(hole)
	ring_shape(0.14,0.032,Vector3(0.11,0.20,0.22),"8794a5")
	box(Vector3(0.09,0.18,0.025),Vector3(0.39,0.20,0.21),"a3ef45")
	text("♻",Vector3(0.17,-0.28,0.211),0.0045,"ecf1ce",model)
	var sleeve:=CylinderMesh.new();sleeve.top_radius=0.112;sleeve.bottom_radius=0.112;sleeve.height=0.33;sleeve.cap_top=false;sleeve.cap_bottom=false;sleeve.radial_segments=48
	var tunnel:=part(sleeve,Vector3(0.11,0.20,0.025),"253344");tunnel.rotation.x=PI/2
	var b:=bottle(model,Vector3(0.11,0.20,0.74));b.set_meta("deposit_bottle",true);b.scale=Vector3.ONE*0.62;b.rotation.x=-PI/2
	# Each new bottle enters once. Reset occurs fully hidden, never reversing.
	var bottle_materials:Array[StandardMaterial3D]=[]
	for piece in b.get_children():
		if piece is MeshInstance3D:
			var m:StandardMaterial3D=piece.material_override.duplicate()
			m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			piece.material_override=m;bottle_materials.append(m)
	updates.append(func(t: float):
		b.position.z=0.74-smoothstep(0.10,0.82,t)*0.60
		var opacity:=smoothstep(0.0,0.10,t)*(1.0-smoothstep(0.84,0.94,t))
		for m in bottle_materials:m.albedo_color.a=opacity
	)

func book_model() -> void:
	for side in [-1,1]:
		var g:=group(Vector3(0,-0.15,0))
		box(Vector3(0.46,0.06,0.66),Vector3(side*0.24,0,0),"359f31",g)
		box(Vector3(0.43,0.075,0.61),Vector3(side*0.24,0.06,0),"f3eedb",g,0.015)
		for j in 5:
			box(Vector3(0.30,0.008,0.012),Vector3(side*0.25,0.102,-0.20+j*0.09),"c9c5b2",g,0.003)
	# The turning leaf starts at the bound spine, exactly on top of the stack.
	var spine:=cylinder(0.023,0.61,Vector3(0,-0.065,0),"e5dfc5")
	spine.rotation.x=PI/2
	var page:=group(Vector3(0,-0.047,0))
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in 32:
		var u:=float(j)/32;var v:=float(j+1)/32
		var a:=Vector3(u*0.43,sin(u*PI)*0.025,-0.30)
		var b:=Vector3(v*0.43,sin(v*PI)*0.025,-0.30)
		var c:=Vector3(v*0.43,sin(v*PI)*0.025,0.30)
		var d:=Vector3(u*0.43,sin(u*PI)*0.025,0.30)
		for p in [a,b,c,a,c,d]:surface.add_vertex(p)
	surface.generate_normals()
	part(surface.commit(),Vector3.ZERO,"fff9e8",page)
	# Ink follows the bound curved sheet through the entire page turn.
	for row in 5:
		for segment in 8:
			var x:=0.05+segment*0.037;var nx:=x+0.037
			var z:=-0.19+row*0.082
			beam(Vector3(x,sin(x/0.43*PI)*0.025+0.003,z),Vector3(nx,sin(nx/0.43*PI)*0.025+0.003,z),0.0025,"8a9c8a",page)

	updates.append(func(t: float):page.rotation.z=(0.5-0.5*cos(t*TAU))*PI)

func tax_model() -> void:
	# A complete invoice, inset discount seal and resting coins form one icon.
	box(Vector3(0.95,0.055,0.52),Vector3(0,-0.53,0.04),"39495d",null,0.035)
	var invoice:=group(Vector3(-0.16,-0.01,-0.07))
	box(Vector3(0.65,0.96,0.055),Vector3.ZERO,"d7d3c0",invoice,0.025)
	box(Vector3(0.61,0.92,0.015),Vector3(0,0.005,0.033),"fff4d9",invoice,0.018)
	box(Vector3(0.50,0.075,0.012),Vector3(0,0.34,0.048),"2b8857",invoice,0.008)
	for i in 3:
		box(Vector3(0.37-i*0.045,0.017,0.010),Vector3(-0.035,0.22-i*0.065,0.049),"859b95",invoice,0.005)
	# The benefit amount belongs in the card description; the seal is visual.
	var seal:=group(Vector3(-0.12,-0.08,0.055))
	disc(0.275,0.065,Vector3.ZERO,"166c42",seal)
	disc(0.245,0.020,Vector3(0,0,0.042),"2baf58",seal)
	ring_shape(0.245,0.011,Vector3(0,0,0.055),"91d4a0",seal)
	for offset in [Vector3(-0.080,0.090,0.070),Vector3(0.080,-0.090,0.070)]:
		ring_shape(0.047,0.015,offset,"fff9e8",seal)
	beam(Vector3(-0.075,-0.12,0.070),Vector3(0.075,0.12,0.070),0.018,"fff9e8",seal)
	for j in 3:
		var c:=coin(Vector3(0.31,-0.465+j*0.062,0.01),model,0.18)
		c.rotation.x=-PI/2
	var main:=coin(Vector3(0.29,-0.375,0.27),model,0.15)
	updates.append(func(t: float):main.rotation.y=sin(t*TAU)*0.16)

func coins_model(tax: bool=false) -> void:
	for j in 5:
		var c:=coin(Vector3(0.14,-0.43+j*0.095,-0.04),model,0.24)
		c.rotation.x=-PI/2
	var main:=coin(Vector3(-0.24,-0.22,0.46),model,0.32)
	var plant:=leaf(Vector3(0.43,-0.32,0.20),model);plant.scale=Vector3.ONE*0.6
	if tax:
		plant.hide()
		var a:=arrow(Vector3(0.48,-0.20,0.32),"e85436",model)
		a.rotation.z=PI
	updates.append(func(t: float):main.rotation.y=sin(t*TAU)*0.65;main.rotation.z=sin(t*TAU)*0.12)

func medal_model() -> void:
	var m:=group(Vector3.ZERO)
	for i in 16:
		var a:=i*TAU/16
		disc(0.09,0.075,Vector3(cos(a)*0.39,sin(a)*0.39,0),"3fbe26",m)
	disc(0.405,0.095,Vector3.ZERO,"39a923",m)
	ring_shape(0.31,0.018,Vector3(0,0,0.065),"f3eedb",m)
	var l:=leaf(Vector3(0,0,0.08),m,"f3eedb");l.scale=Vector3.ONE*0.85
	for side in [-1,1]:
		var ribbon:=box(Vector3(0.17,0.31,0.035),Vector3(side*0.18,-0.44,-0.02),"249b26",m)
		ribbon.rotation.z=side*0.27
	updates.append(func(t: float):m.rotation.y=sin(t*TAU)*0.48)

func truck_model() -> void:
	var tr:=group(Vector3.ZERO)
	box(Vector3(0.62,0.47,0.39),Vector3(-0.15,0.10,0),"2fa72f",tr,0.07)
	box(Vector3(0.32,0.35,0.39),Vector3(0.33,0.0,0),"f3f2e8",tr,0.07)
	box(Vector3(0.14,0.19,0.016),Vector3(0.37,0.085,0.204),"253f54",tr)
	box(Vector3(0.08,0.12,0.016),Vector3(0.515,0.02,0.11),"ffd14a",tr)
	var l:=leaf(Vector3(-0.15,0.08,0.21),tr,"f3eedb");l.scale=Vector3.ONE*0.37
	var ws:Array[Node3D]=[]
	for x in [-0.30,0.31]:
		for z in [-0.205,0.205]:
			var w:=group(Vector3(x,-0.22,z),tr);ws.append(w)
			disc(0.105,0.055,Vector3.ZERO,"253344",w)
			disc(0.06,0.06,Vector3.ZERO,"8794a5",w)
			box(Vector3(0.014,0.10,0.065),Vector3.ZERO,"c4ced8",w,0.005)
	updates.append(func(t: float):tr.position.x=sin(t*TAU)*0.13;for w in ws:w.rotation.z=-sin(t*TAU)*2.5)

func arrow(pos: Vector3,col: String,parent: Node3D) -> Node3D:
	var g:=group(pos,parent)
	var polygon:=CSGPolygon3D.new()
	polygon.polygon=PackedVector2Array([Vector2(-0.06,-0.23),Vector2(0.06,-0.23),Vector2(0.06,0.12),Vector2(0.17,0.12),Vector2(0,0.31),Vector2(-0.17,0.12),Vector2(-0.06,0.12)])
	polygon.depth=0.055;polygon.material=material(col);g.add_child(polygon)
	return g

func water_model() -> void:
	var drop:=ball(0.25,Vector3(0,-0.13,0.12),"27bde9")
	drop.scale.y=1.35
	var tip:=cylinder(0.19,0.40,Vector3(0,0.16,0.12),"27bde9",null,0.01)
	var cycle:=group(Vector3(0,0,-0.10))
	for i in 3:
		var g:=group(Vector3.ZERO,cycle);g.rotation.z=i*TAU/3
		var a:=arrow(Vector3(0.42,0,0),"4abb29",g);a.scale=Vector3.ONE*0.7;a.rotation.z=-0.45
	updates.append(func(t: float):cycle.rotation.z=t*TAU)

func case_model() -> void:
	# Four walls and a floor, not an opaque cube pretending to be a container.
	box(Vector3(0.83,0.07,0.36),Vector3(0,-0.445,0),"8e4b22",null,0.03)
	for z in [-0.16,0.16]:box(Vector3(0.83,0.32,0.045),Vector3(0,-0.25,z),"8e4b22",null,0.02)
	for x in [-0.39,0.39]:box(Vector3(0.05,0.32,0.36),Vector3(x,-0.25,0),"8e4b22",null,0.02)
	box(Vector3(0.12,0.09,0.03),Vector3(0,-0.16,0.20),"f3b923")
	for x in [-0.30,0.30]:
		box(Vector3(0.075,0.10,0.027),Vector3(x,-0.12,0.19),"f3b923",null,0.014)
	for x in [-0.34,0.34]:
		for y in [-0.35,-0.20]:ball(0.009,Vector3(x,y,0.186),"d7ae74")
	var lid:=group(Vector3(0,-0.07,-0.18))
	box(Vector3(0.83,0.08,0.36),Vector3(0,0,0.18),"a45c2a",lid,0.04)
	box(Vector3(0.34,0.04,0.055),Vector3(0,0.13,0.17),"8e4b22",lid)
	for x in [-0.15,0.15]:box(Vector3(0.04,0.14,0.055),Vector3(x,0.07,0.17),"8e4b22",lid)
	var c:=coin(Vector3(0,-0.25,0),model,0.15)
	updates.append(func(t: float):var p:=0.5-0.5*cos(t*TAU);lid.rotation.x=-p*1.2;c.position.y=-0.25+maxf(0.0,(p-0.35)/0.65)*0.40;c.rotation.y=t*TAU)

func bond_model() -> void:
	var document:=group(Vector3(0,0.02,0))
	box(Vector3(0.72,0.90,0.045),Vector3.ZERO,"f3eedb",document,0.035)
	box(Vector3(0.64,0.11,0.015),Vector3(0,0.34,0.028),"32983b",document,0.016)
	for j in 4:
		box(Vector3(0.42-j*0.035,0.017,0.008),Vector3(-0.05,0.15-j*0.09,0.032),"8a9c8a",document,0.005)
	var sprout:=leaf(Vector3(0.17,0.02,0.05),document,"5eaf36");sprout.scale=Vector3.ONE*0.46
	var seal:=coin(Vector3(0.19,-0.30,0.08),document,0.12)
	for side in [-1,1]:
		var ribbon:=box(Vector3(0.06,0.18,0.02),Vector3(0.19+side*0.035,-0.45,0.04),"32983b",document,0.008)
		ribbon.rotation.z=side*0.20
	updates.append(func(t: float):document.rotation.y=sin(t*TAU)*0.25)

func warehouse_model() -> void:
	# Both loading bays are genuinely open. The parcel stays within the left
	# bay, on its roller bed, and stops clear of the closed rear wall.
	box(Vector3(1.10,0.06,0.72),Vector3(0,-0.43,0),"8794a5")
	box(Vector3(1.10,0.08,0.72),Vector3(0,0.28,0),"3a735d")
	box(Vector3(1.10,0.63,0.05),Vector3(0,-0.07,-0.335),"dce5db")
	for x in [-0.52,0.52]:box(Vector3(0.06,0.63,0.72),Vector3(x,-0.07,0),"dce5db")
	for x in [-0.48,0,0.48]:box(Vector3(0.055,0.58,0.05),Vector3(x,-0.08,0.33),"3a735d")
	box(Vector3(1.02,0.10,0.05),Vector3(0,0.20,0.335),"dce5db")
	box(Vector3(0.35,0.05,0.95),Vector3(-0.24,-0.36,0.29),"39495d")
	for j in 9:
		var roller:=cylinder(0.020,0.30,Vector3(-0.24,-0.325,-0.06+j*0.09),"c4ced8");roller.rotation.z=PI/2
	for j in 3:
		box(Vector3(0.20,0.16,0.19),Vector3(0.25,-0.30+j*0.16,-0.13),"bc894d",null,0.018)
	for i in 7:
		box(Vector3(0.018,0.010,0.65),Vector3(-0.45+i*0.15,0.325,0),"568f7a",null,0.004)
	for x in [-0.25,0.25]:
		box(Vector3(0.10,0.035,0.025),Vector3(x,0.20,0.37),"ffd887",null,0.008)
	var parcel:=group(Vector3(-0.24,-0.235,0.60))
	box(Vector3(0.21,0.18,0.19),Vector3.ZERO,"bc894d",parcel,0.022)
	box(Vector3(0.040,0.008,0.19),Vector3(0,0.094,0),"e4cc99",parcel,0.003)
	updates.append(func(t: float):parcel.position.z=0.60-(0.5-0.5*cos(t*TAU))*0.70)

func cleaning_model() -> void:
	# A river litter interceptor on grassy banks: environmental cleanup.
	box(Vector3(1.12,0.09,0.88),Vector3(0,-0.48,0),"94704b",null,0.04)
	for x in [-0.40,0.40]:
		box(Vector3(0.31,0.055,0.87),Vector3(x,-0.41,0),"70b933",null,0.03)
	box(Vector3(0.50,0.035,0.86),Vector3(0,-0.43,0),"318fba",null,0.015)
	# Filter housing sits beside the water; pipe mouths meet the river surface.
	box(Vector3(0.25,0.33,0.29),Vector3(0.39,-0.22,0.04),"e5eae4",null,0.04)
	box(Vector3(0.26,0.10,0.30),Vector3(0.39,-0.02,0.04),"36a65c",null,0.025)
	beam(Vector3(0.26,-0.15,0.04),Vector3(0.13,-0.15,0.04),0.06,"8794a5",model)
	beam(Vector3(0.13,-0.15,0.04),Vector3(0.13,-0.40,0.04),0.06,"8794a5",model)
	# Visible collection barrier and mesh basket across the channel.
	for x in [-0.23,0.23]:
		cylinder(0.028,0.22,Vector3(x,-0.34,0.23),"ffd14a")
	beam(Vector3(-0.23,-0.24,0.23),Vector3(0.23,-0.24,0.23),0.027,"ffd14a",model)
	for x in [-0.18,-0.09,0.0,0.09,0.18]:
		beam(Vector3(x,-0.42,0.23),Vector3(x,-0.25,0.23),0.012,"8794a5",model)
	for y in [-0.38,-0.32]:beam(Vector3(-0.23,y,0.23),Vector3(0.23,y,0.23),0.012,"8794a5",model)
	# Litter floats on water and meets the interceptor, with no floor-cleaning props.
	var litter:=bottle(model,Vector3(-0.07,-0.37,-0.08))
	litter.scale=Vector3.ONE*0.23;litter.rotation.z=PI/2
	var waves:Array[Node3D]=[]
	for i in 4:
		var wave:=box(Vector3(0.14,0.004,0.013),Vector3(0.02,-0.408,-0.31+i*0.16),"8edbe7",null,0.002)
		waves.append(wave)
	for x in [-0.43,0.43]:
		cylinder(0.023,0.20,Vector3(x,-0.28,-0.28),"94704b")
		ball(0.115,Vector3(x,-0.13,-0.28),"48a83c")
	updates.append(func(t: float):
		litter.position.z=-0.13+0.10*(0.5-0.5*cos(t*TAU))
		litter.rotation.y=0.08*sin(t*TAU*2)
		for i in waves.size():waves[i].position.x=sin(t*TAU+float(i))*0.025
	)

func luminous_flame(height: float,width: float,lean: float,pos: Vector3,col: String,parent: Node3D) -> Node3D:
	var n:=part(flame_geometry(height,width,lean),pos,col,parent)
	var m:=StandardMaterial3D.new()
	m.albedo_color=Color(col);m.cull_mode=BaseMaterial3D.CULL_DISABLED
	m.roughness=0.75
	m.emission_enabled=true;m.emission=Color(col);m.emission_energy_multiplier=0.45
	n.material_override=m
	return n

func flame_geometry(height: float,width: float,lean: float) -> Mesh:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings:=32;var sides:=32
	var points:Array[Vector3]=[]
	for y in range(rings+1):
		var t:=float(y)/rings
		var radius:=maxf(0.001,pow(sin(PI*t),0.78)*pow(1.0-t,0.28)*width)
		var bend:=lean*t*t+sin(t*PI)*0.025
		for k in sides:
			var a:=k*TAU/sides
			points.append(Vector3(bend+cos(a)*radius,t*height,sin(a)*radius*0.60))
	for y in rings:
		for k in sides:
			var a:=points[y*sides+k];var b:=points[y*sides+(k+1)%sides]
			var c:=points[(y+1)*sides+(k+1)%sides];var d:=points[(y+1)*sides+k]
			for v in [a,b,c,a,c,d]:st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func fire_model() -> void:
	var extinguisher:=group(Vector3(-0.25,-0.13,0))
	cylinder(0.15,0.53,Vector3.ZERO,"df342b",extinguisher)
	ball(0.15,Vector3(0,0.25,0),"df342b",extinguisher)
	cylinder(0.055,0.09,Vector3(0,0.37,0),"8794a5",extinguisher)
	box(Vector3(0.24,0.035,0.055),Vector3(0.05,0.43,0),"253344",extinguisher)
	box(Vector3(0.17,0.19,0.016),Vector3(0,0,0.15),"f3eedb",extinguisher)
	for y in [-0.05,0.0,0.05]:box(Vector3(0.10,0.010,0.008),Vector3(0,y,0.163),"ac2c23",extinguisher,0.003)
	disc(0.048,0.028,Vector3(0.07,0.33,0.065),"c4ced8",extinguisher)
	disc(0.036,0.030,Vector3(0.07,0.33,0.083),"fff4d9",extinguisher)
	beam(Vector3(0.07,0.33,0.103),Vector3(0.085,0.35,0.103),0.005,"253344",extinguisher)
	beam(Vector3(-0.03,0.40,0),Vector3(-0.20,0.24,0.03),0.04,"253344",extinguisher)
	beam(Vector3(-0.20,0.24,0.03),Vector3(-0.20,-0.16,0.03),0.045,"253344",extinguisher)
	var flame:=group(Vector3(0.30,-0.43,0.12))
	part(flame_geometry(0.52,0.18,0.07),Vector3.ZERO,"f27c13",flame)
	part(flame_geometry(0.40,0.11,-0.07),Vector3(-0.10,0,0.01),"ffad1f",flame)
	part(flame_geometry(0.31,0.09,0.035),Vector3(0.025,0.008,0.08),"ffe26a",flame)
	updates.append(func(t: float):flame.scale=Vector3(1.0+0.04*sin(t*TAU*3),0.94+0.06*sin(t*TAU*4),1.0);flame.rotation.z=sin(t*TAU*2)*0.045)

func fire_effect_model() -> void:
	var flame:=group(Vector3(0,-0.64,0))
	flame.scale=Vector3.ONE*2.45
	luminous_flame(0.52,0.19,0.07,Vector3.ZERO,"ff4808",flame)
	luminous_flame(0.40,0.12,-0.08,Vector3(-0.10,0,0.035),"ff9b05",flame)
	luminous_flame(0.39,0.13,0.02,Vector3(0.015,0.005,0.10),"ffba08",flame)
	luminous_flame(0.28,0.085,-0.025,Vector3(0.01,0.01,0.19),"fff333",flame)
	luminous_flame(0.14,0.046,0.01,Vector3(0.015,0.015,0.24),"fff5b8",flame)
	updates.append(func(t: float):
		flame.scale=Vector3(2.45*(1.0+0.055*sin(t*TAU*5)),2.45*(0.92+0.08*sin(t*TAU*7)),2.45)
		flame.rotation.z=sin(t*TAU*3)*0.055
	)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DEST))
	viewport=SubViewport.new();viewport.size=Vector2i(1024,1024);viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_4X;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world=Node3D.new();viewport.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.TRANSPARENT;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(0.78,0.85,1);env.environment.ambient_light_energy=0.28
	var sky:=Sky.new()
	var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color(0.70,0.79,0.96)
	sky_material.sky_horizon_color=Color(0.95,0.92,0.84)
	sky_material.ground_bottom_color=Color(0.19,0.24,0.32)
	sky_material.ground_horizon_color=Color(0.75,0.78,0.82)
	sky.sky_material=sky_material
	env.environment.sky=sky
	env.environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	env.environment.ssao_enabled=true
	env.environment.ssao_radius=0.30
	env.environment.ssao_intensity=1.3
	world.add_child(env)
	for data in [[Vector3(-40,-35,0),1.22],[Vector3(-20,140,0),0.40]]:
		var light:=DirectionalLight3D.new();light.rotation_degrees=data[0];light.light_energy=data[1];light.shadow_enabled=false;world.add_child(light)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.75;world.add_child(camera);camera.position=Vector3(1.8,2.4,4);camera.look_at(Vector3(0,0,0))
	var builders:Array[Callable]=[solar_model,repair_model,deposit_model,book_model,bond_model,arm_model,medal_model,warehouse_model,cleaning_model,tax_model,case_model,fire_model]
	var selected:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--icon="):selected=arg.trim_prefix("--icon=")
	var render_ids:=IDS.duplicate()
	if selected=="fire_effect":
		render_ids.append("fire_effect")
		builders.append(fire_effect_model)
	for index in render_ids.size():
		if not selected.is_empty() and render_ids[index]!=selected:continue
		model=Node3D.new();world.add_child(model);updates.clear();builders[index].call()
		var atlas:=Image.create(PX*12,PX*8,false,Image.FORMAT_RGBA8)
		for f in (1 if preview_only else COUNT):
			for update in updates:update.call(float(f)/COUNT)
			for settle in (4 if f==0 else 1):
				await process_frame
				await RenderingServer.frame_post_draw
			var picture:=viewport.get_texture().get_image();picture.resize(PX,PX,Image.INTERPOLATE_LANCZOS)
			atlas.blit_rect(picture,Rect2i(0,0,PX,PX),Vector2i((f%12)*PX,(f/12)*PX))
			if f==0:picture.save_png(DEST+render_ids[index]+"-preview.png")
		if not preview_only:atlas.save_png("res://art/02b/fire_loop.png" if render_ids[index]=="fire_effect" else DEST+render_ids[index]+".png")
		print("WHOLE_PERK_OK ",render_ids[index])
		model.free();await process_frame
	quit()
