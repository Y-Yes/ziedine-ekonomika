## Render whole, physically connected 3D dioramas into 24-frame PNG strips.
## Run with Godot --path <project> --script res://tools/render_02b_loops.gd
extends SceneTree

const NAMES := ["1_naudotojas", "2_surinkimas", "3_rusiavimas", "4_perdirbimas", "5_gamykla", "6_parduotuve"]
const OUTPUT := "res://art/02b/loops/"
const SIZE := 256
const FRAMES := 24
var viewport: SubViewport
var world: Node3D
var model: Node3D
var updates: Array[Callable] = []
var materials: Dictionary = {}
var meshes: Dictionary = {}
var preview_only := false

func _initialize() -> void:
	preview_only = "--preview" in OS.get_cmdline_user_args()
	call_deferred("run")

func material(hex: String) -> StandardMaterial3D:
	if not materials.has(hex):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(hex)
		m.roughness = 0.65
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[hex] = m
	return materials[hex]

func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot((a + b + c) / 3.0) < 0.0:
		var tmp := b
		b = c
		c = tmp
		normal = -normal
	for p in [a, b, c]:
		st.set_normal(normal)
		st.add_vertex(p)

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	tri(st, a, b, c)
	tri(st, a, c, d)

func bevel_box(size: Vector3, bevel: float) -> Mesh:
	var key := str(size) + str(bevel)
	if meshes.has(key):
		return meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var b := minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.65)
	var inner := h - Vector3.ONE * b
	for axis in 3:
		var u := (axis + 1) % 3
		var v := (axis + 2) % 3
		for sign in [-1, 1]:
			var points: Array[Vector3] = []
			for pair in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis] = h[axis] * sign
				p[u] = inner[u] * pair.x
				p[v] = inner[v] * pair.y
				points.append(p)
			quad(st, points[0], points[1], points[2], points[3])
		for su in [-1, 1]:
			for sv in [-1, 1]:
				var points: Array[Vector3] = []
				for side in [-1, 1]:
					for edge in [0, 1]:
						var p := Vector3.ZERO
						p[axis] = inner[axis] * side
						p[u] = (h[u] if edge == 0 else inner[u]) * su
						p[v] = (inner[v] if edge == 0 else h[v]) * sv
						points.append(p)
				quad(st, points[0], points[1], points[3], points[2])
	for sx in [-1,1]:
		for sy in [-1,1]:
			for sz in [-1,1]:
				var p := inner * Vector3(sx,sy,sz)
				tri(st, p + Vector3(b*sx,0,0), p + Vector3(0,b*sy,0), p + Vector3(0,0,b*sz))
	var result := st.commit()
	meshes[key] = result
	return result

func part(mesh: Mesh, pos: Vector3, color: String, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	(parent if parent != null else model).add_child(node)
	node.position = pos
	return node

func group(pos: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	(parent if parent != null else model).add_child(node)
	node.position = pos
	return node

func box(size: Vector3, pos: Vector3, color: String, parent: Node3D = null, bevel: float = 0.025) -> MeshInstance3D:
	return part(bevel_box(size, bevel), pos, color, parent)

func cylinder(radius: float, height: float, pos: Vector3, color: String, parent: Node3D = null, top: float = -1) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return part(mesh, pos, color, parent)

func ball(radius: float, pos: Vector3, color: String, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 12
	mesh.rings = 6
	return part(mesh, pos, color, parent)

func beam(a: Vector3, b: Vector3, width: float, color: String, parent: Node3D) -> MeshInstance3D:
	var node := box(Vector3(width, a.distance_to(b), width), (a+b)*0.5, color, parent)
	node.basis = Basis(Quaternion(Vector3.UP, (b-a).normalized()))
	return node

func slab() -> void:
	box(Vector3(2.0,0.17,2.0), Vector3(0,-0.105,0), "b88b57", null, 0.035)
	box(Vector3(2.02,0.055,2.02), Vector3(0,-0.015,0), "a6cd55", null, 0.025)
	for x in [-0.89,0.89]:
		for z in [-0.80,0.80]:
			for i in 3:
				var bush := ball(0.06,Vector3(x+(i-1)*0.04,0.07,z),"7cac38" if i%2 else "94bd42")
				bush.scale.y = 0.85

func tree(pos: Vector3, scale: float = 1) -> void:
	var root := group(pos)
	cylinder(0.035*scale,0.24*scale,Vector3(0,0.12*scale,0),"825d38",root)
	for offset in [Vector3(-0.07,0.31,0), Vector3(0.06,0.36,0.04), Vector3(0,0.44,0),Vector3(0.06,0.42,-0.05)]:
		ball(0.13*scale,offset*scale,"6fa536" if offset.x < 0 else "8abd42",root)
	updates.append(func(t: float): root.rotation.z = sin(t*TAU)*0.025)

func roof(size: Vector3, pos: Vector3, color: String, parent: Node3D = null) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := size.x * 0.5
	var z := size.z * 0.5
	var a := Vector3(-x,0,-z)
	var b := Vector3(x,0,-z)
	var c := Vector3(x,0,z)
	var d := Vector3(-x,0,z)
	var e := Vector3(-x,size.y,0)
	var f := Vector3(x,size.y,0)
	quad(st,a,b,f,e)
	quad(st,d,e,f,c)
	tri(st,a,e,d)
	tri(st,b,c,f)
	part(st.commit(),pos,color,parent)

func person(start: Vector3, finish: Vector3, phase: float = 0) -> void:
	var root := group(start)
	ball(0.043,Vector3(0,0.255,0),"f1b67c",root)
	var hair := ball(0.045,Vector3(0,0.274,-0.008),"63422c",root)
	hair.scale.y = 0.65
	box(Vector3(0.09,0.10,0.06),Vector3(0,0.17,0),"2785c6",root)
	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	for side in [-1,1]:
		var leg := group(Vector3(side*0.023,0.125,0),root)
		box(Vector3(0.032,0.105,0.035),Vector3(0,-0.052,0),"344358",leg,0.006)
		box(Vector3(0.038,0.025,0.06),Vector3(0,-0.105,0.01),"5b4432",leg,0.005)
		legs.append(leg)
		var arm := group(Vector3(side*0.06,0.21,0),root)
		box(Vector3(0.025,0.075,0.03),Vector3(0,-0.037,0),"2785c6",arm,0.006)
		ball(0.019,Vector3(0,-0.085,0),"f1b67c",arm)
		arms.append(arm)
	updates.append(func(t: float):
		var u := (1.0-cos((t+phase)*TAU))*0.5
		root.position = start.lerp(finish,u)
		root.rotation.y = atan2(finish.x-start.x,finish.z-start.z) + (PI if sin((t+phase)*TAU)<0 else 0)
		for i in 2:
			legs[i].rotation.x = sin(t*TAU*3+i*PI)*0.38
			arms[i].rotation.x = -sin(t*TAU*3+i*PI)*0.30)

func home() -> void:
	box(Vector3(0.28,0.014,1.2),Vector3(0.05,0.025,0.30),"d6d2c5")
	box(Vector3(0.83,0.69,0.74),Vector3(0,0.37,-0.15),"f6efe0")
	roof(Vector3(0.98,0.35,0.90),Vector3(0,0.715,-0.15),"df5a30")
	for side in [-1,1]:
		for row in 6:
			var z: float = float(side)*(row+0.5)*0.075
			box(Vector3(0.97,0.012,0.012),Vector3(0,1.065-absf(z)/0.45*0.35,-0.15+z),"ec7846",null,0.004)
	roof(Vector3(0.32,0.13,0.30),Vector3(0.04,0.42,0.26),"e06a38")
	box(Vector3(0.12,0.34,0.12),Vector3(0.25,0.92,-0.32),"eee6d8")
	box(Vector3(0.16,0.04,0.16),Vector3(0.25,1.10,-0.32),"ffffff")
	box(Vector3(0.16,0.29,0.025),Vector3(0.04,0.16,0.23),"986b38")
	for x in [-0.28,0.27]:
		for y in [0.27,0.56]:
			box(Vector3(0.16,0.16,0.025),Vector3(x,y,0.231),"ba894a")
			box(Vector3(0.12,0.12,0.028),Vector3(x,y,0.249),"7db4cd")
	for z in [-0.34,0.04]:
		box(Vector3(0.025,0.17,0.15),Vector3(0.43,0.5,z),"6e9eb8")
	for x in [-0.86,-0.7,-0.54,0.54,0.7,0.86]:
		box(Vector3(0.035,0.20,0.035),Vector3(x,0.10,0.77),"fff7e8",null,0.007)
	for x in [-0.68,0.68]:
		box(Vector3(0.42,0.035,0.025),Vector3(x,0.13,0.77),"fff7e8")
	for x in [-0.86,0.86]:
		for i in 8:
			box(Vector3(0.027,0.17,0.027),Vector3(x,0.085,-0.55+i*0.16),"fff7e8",null,0.005)
		box(Vector3(0.025,0.028,1.25),Vector3(x,0.12,0.03),"fff7e8")
	tree(Vector3(-0.73,0,-0.48),1.1)
	tree(Vector3(0.73,0,-0.5),0.9)
	person(Vector3(0.06,0.025,0.30),Vector3(0.08,0.025,0.82))

func bin_prop(pos: Vector3, color: String, phase: float) -> void:
	var root := group(pos)
	box(Vector3(0.27,0.39,0.28),Vector3(0,0.22,0),color,root,0.025)
	# Exactly two wheels, one rear axle. The front is a solid plastic foot.
	for side in [-1,1]:
		var wheel := cylinder(0.055,0.035,Vector3(side*0.142,0.055,-0.10),"28313b",root)
		wheel.rotation.z = PI*0.5
	var lid := group(Vector3(0,0.42,-0.14),root)
	box(Vector3(0.30,0.035,0.31),Vector3(0,0,0.14),color,lid,0.012)
	box(Vector3(0.11,0.018,0.025),Vector3(0,0.025,0.245),"37404a",lid,0.005)
	for i in 3:
		var mark := box(Vector3(0.025,0.07,0.007),Vector3(-0.045+i*0.045,0.25,0.146),"f9fbf0",root,0.004)
		mark.rotation.z = -0.4 if i==0 else 0.4
	updates.append(func(t: float): lid.rotation.x = -maxf(0,sin((t+phase)*TAU))*0.5)

func collection() -> void:
	box(Vector3(1.86,0.025,1.65),Vector3(0,0.025,0),"c8c6b7")
	box(Vector3(1.84,0.015,0.62),Vector3(0,0.045,-0.36),"8a9192")
	for i in 3:
		bin_prop(Vector3(-0.48+i*0.46,0.04,0.47),["f3c52d","2dad4c","258be0"][i],i*0.18)
	var truck := group(Vector3(0,0.04,-0.34))
	box(Vector3(0.62,0.34,0.40),Vector3(-0.12,0.29,0),"f3f1e8",truck)
	box(Vector3(0.12,0.38,0.42),Vector3(-0.45,0.29,0),"289546",truck)
	box(Vector3(0.63,0.035,0.42),Vector3(-0.1,0.47,0),"30954b",truck)
	box(Vector3(0.27,0.30,0.38),Vector3(0.34,0.26,0),"f7f5ee",truck)
	box(Vector3(0.025,0.13,0.30),Vector3(0.482,0.32,0),"466879",truck)
	box(Vector3(0.19,0.13,0.013),Vector3(0.34,0.32,0.197),"527b8c",truck)
	box(Vector3(0.12,0.12,0.012),Vector3(-0.12,0.31,0.208),"36a84a",truck)
	var beacon := cylinder(0.035,0.055,Vector3(0.33,0.445,0),"f4a52b",truck)
	var wheels: Array[Node3D] = []
	for x in [-0.32,0.31]:
		for z in [-0.205,0.205]:
			var wheel := group(Vector3(x,0.105,z),truck)
			var rubber := cylinder(0.10,0.055,Vector3.ZERO,"273039",wheel)
			rubber.rotation.x = PI*0.5
			var hub := cylinder(0.055,0.06,Vector3.ZERO,"b8c2c2",wheel)
			hub.rotation.x = PI*0.5
			wheels.append(wheel)
	updates.append(func(t: float):
		truck.position.x = sin(t*TAU)*0.26
		for wheel in wheels: wheel.rotation.z = -sin(t*TAU)*2.6
		beacon.scale.y = 1.0+0.12*sin(t*TAU*4))
	tree(Vector3(-0.82,0,-0.76),0.7)
	tree(Vector3(0.84,0,-0.76),0.75)

func conveyor(x: float, z: float, length: float, color: String, phase: float = 0) -> void:
	box(Vector3(0.32,0.10,length),Vector3(x,0.28,z),"9ba6ab")
	box(Vector3(0.24,0.018,length-0.07),Vector3(x,0.34,z),color)
	for dx in [-0.13,0.13]:
		for dz in [-length*0.4,length*0.4]:
			box(Vector3(0.035,0.25,0.04),Vector3(x+dx,0.135,z+dz),"717e85")
	for i in 7:
		var rib := box(Vector3(0.23,0.012,0.018),Vector3(x,0.355,z),"66777f")
		updates.append(func(t: float): rib.position.z = z + (fposmod(t+float(i)/7,1.0)-0.5)*(length-0.08))
	for i in 2:
		var item := box(Vector3(0.12,0.09,0.13),Vector3(x,0.405,z),"c79452" if i==0 else "3aa5df")
		updates.append(func(t: float): item.position.z = z+(fposmod(t+phase+float(i)/2,1.0)-0.5)*(length-0.15))

func sorting() -> void:
	box(Vector3(1.85,0.02,1.85),Vector3(0,0.025,0),"aeb4a6")
	for i in 3:
		conveyor(-0.52+i*0.50,0.03,1.35,"39434c",i*0.16)
		box(Vector3(0.34,0.21,0.23),Vector3(-0.52+i*0.5,0.14,0.80),["eac52e","34a654","378dd2"][i])
	var pedestal := Vector3(0.28,0.39,-0.60)
	cylinder(0.14,0.40,Vector3(0.28,0.22,-0.60),"737f86")
	var rig := group(pedestal)
	rig.scale = Vector3.ONE * 1.32
	var shoulder := group(Vector3.ZERO,rig)
	beam(Vector3.ZERO,Vector3(0,0.37,0.22),0.105,"efb927",shoulder)
	ball(0.085,Vector3.ZERO,"e4ae20",shoulder)
	var elbow := group(Vector3(0,0.37,0.22),shoulder)
	ball(0.075,Vector3.ZERO,"424d55",elbow)
	beam(Vector3.ZERO,Vector3(0,-0.15,0.36),0.09,"f5c42c",elbow)
	var claw := group(Vector3(0,-0.15,0.36),elbow)
	box(Vector3(0.12,0.09,0.10),Vector3(0,-0.025,0),"d2d8d6",claw)
	for side in [-1,1]:
		beam(Vector3(side*0.065,-0.04,0),Vector3(side*0.055,-0.18,0),0.028,"c9d2d2",claw)
	updates.append(func(t: float):
		rig.rotation.y = sin(t*TAU)*0.38
		shoulder.rotation.x = sin(t*TAU)*0.15
		elbow.rotation.x = -sin(t*TAU)*0.20)
	for x in [-0.88,0.88]:
		box(Vector3(0.025,0.32,1.5),Vector3(x,0.17,-0.05),"e8b933")

func recycling() -> void:
	box(Vector3(1.84,0.02,1.84),Vector3(0,0.02,0),"b6be9b")
	box(Vector3(0.65,0.46,0.62),Vector3(-0.30,0.27,-0.35),"8b999f")
	# Open hopper with four slanted walls and visible material.
	for side in [-1,1]:
		var wall := box(Vector3(0.035,0.30,0.70),Vector3(-0.30+side*0.34,0.63,-0.35),"aab6bc")
		wall.rotation.z = -side*0.22
		var end := box(Vector3(0.70,0.30,0.035),Vector3(-0.30,0.63,-0.35+side*0.34),"b5bec1")
		end.rotation.x = side*0.22
	for i in 18:
		var p := Vector3(-0.53+fposmod(i*0.171,0.44),0.55,-0.59+fposmod(i*0.213,0.45))
		var chip := box(Vector3(0.055,0.045,0.06),p,["ecf0dd","3293c8","e0b43d"][i%3])
		updates.append(func(t: float): chip.position.y=p.y+sin((t+float(i)/18)*TAU)*0.018)
	conveyor(0.34,0.03,0.95,"34914b")
	for x in [-0.65,-0.37,-0.09]:
		for z in [0.53,0.79]:
			box(Vector3(0.24,0.23,0.22),Vector3(x,0.14,z),"e7e3ca")
			for dx in [-0.06,0.06]:
				box(Vector3(0.015,0.24,0.23),Vector3(x+dx,0.14,z),"647477",null,0.002)
			for i in 8:
				box(Vector3(0.035,0.025,0.018),Vector3(x-0.08+(i%4)*0.05,0.08+(i/4)*0.11,z+0.116),["4a9ed0","e8be45","c7d4c3","96ac7c"][i%4],null,0.004)
	for x in [0.59,0.82]:
		cylinder(0.09,0.24,Vector3(x,0.14,0.68),"f1ead7",null,0.075)
	tree(Vector3(-0.83,0,-0.76),0.65)

func factory() -> void:
	box(Vector3(1.15,0.58,0.85),Vector3(-0.12,0.32,-0.15),"edf0e4")
	for i in 3:
		roof(Vector3(1.23,0.16,0.31),Vector3(-0.12,0.61,-0.45+i*0.31),"2f8bd8")
	box(Vector3(0.25,0.35,0.025),Vector3(-0.27,0.20,0.29),"75858b")
	for x in [-0.53,0.23,0.40]:
		box(Vector3(0.13,0.13,0.025),Vector3(x,0.39,0.29),"5ca5c8")
	cylinder(0.085,1.05,Vector3(0.60,0.54,-0.55),"eeeada")
	for y in [0.81,0.98]:
		cylinder(0.087,0.10,Vector3(0.60,y,-0.55),"df5538")
	for i in 4:
		var puff := ball(0.06,Vector3.ZERO,"c9d6dc")
		updates.append(func(t: float):
			var u := fposmod(t+float(i)/4,1.0)
			puff.position=Vector3(0.60+u*0.10,1.12+u*0.28,-0.55)
			puff.scale=Vector3.ONE*(0.5+u*0.7)*(1.0-smoothstep(0.7,1.0,u)))
	for x in [0.58,0.81]:
		cylinder(0.095,0.30,Vector3(x,0.17,0.25),"aeb9be")
	for i in 3:
		box(Vector3(0.34,0.025,0.25),Vector3(-0.56,0.05+i*0.04,0.62),"bf8e4e")
	conveyor(0.17,0.64,0.48,"466f8c")

func shop() -> void:
	box(Vector3(1.8,0.02,1.8),Vector3(0,0.025,0),"d3d0be")
	box(Vector3(1.25,0.65,0.9),Vector3(0,0.35,-0.20),"f0e4c9")
	box(Vector3(1.32,0.07,0.96),Vector3(0,0.70,-0.2),"4c5863")
	box(Vector3(0.17,0.13,0.17),Vector3(0.12,0.80,-0.24),"b9c0bc")
	for x in [-0.43,-0.14,0.14,0.43]:
		box(Vector3(0.25,0.42,0.025),Vector3(x,0.30,0.262),"57666b")
		box(Vector3(0.22,0.37,0.030),Vector3(x,0.31,0.28),"a7c2ba")
		for y in [0.20,0.35]:
			box(Vector3(0.19,0.02,0.01),Vector3(x,y,0.30),"d5b06c")
			for i in 3:
				box(Vector3(0.043,0.065,0.012),Vector3(x-0.06+i*0.06,y+0.04,0.307),["e2b443","d97943","83af7b"][i],null,0.003)
	box(Vector3(0.25,0.24,0.055),Vector3(0.35,0.58,0.30),"38a444")
	box(Vector3(0.13,0.10,0.01),Vector3(0.35,0.56,0.335),"eef5df")
	for x in [0.43,0.72]:
		box(Vector3(0.23,0.12,0.22),Vector3(x,0.09,0.59),"b27b3d")
		for i in 4:
			ball(0.04,Vector3(x-0.06+(i%2)*0.12,0.17,0.54+(i/2)*0.10),"d45832" if x<0.5 else "9bb13b")
	tree(Vector3(-0.83,0,-0.65),0.85)
	tree(Vector3(0.83,0,-0.65),0.85)
	person(Vector3(-0.78,0.04,0.72),Vector3(-0.13,0.04,0.45),0.2)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(SIZE,SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world = Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.TRANSPARENT
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8,0.88,1)
	environment.environment.ambient_light_energy = 0.38
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment.ssao_enabled = false
	environment.environment.ssao_radius = 0.7
	environment.environment.ssao_intensity = 2.0
	environment.environment.ssao_power = 1.5
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_energy = 1.8
	sun.light_angular_distance = 2.0
	sun.shadow_enabled = true
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 10
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,140,0)
	fill.light_energy = 0.35
	world.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.4
	world.add_child(camera)
	camera.position = Vector3(4,3.8,5)
	camera.look_at(Vector3(0,0.45,0))
	var builders: Array[Callable] = [home,collection,sorting,recycling,factory,shop]
	for index in 6:
		model = Node3D.new()
		world.add_child(model)
		updates.clear()
		slab()
		builders[index].call()
		var strip := Image.create(SIZE*FRAMES,SIZE,false,Image.FORMAT_RGBA8)
		for frame in (1 if preview_only else FRAMES):
			for update in updates:
				update.call(float(frame)/FRAMES)
			for settle in (5 if frame == 0 else 1):
				await process_frame
				await RenderingServer.frame_post_draw
			var picture := viewport.get_texture().get_image()
			strip.blit_rect(picture,Rect2i(0,0,SIZE,SIZE),Vector2i(frame*SIZE,0))
			if frame == 0:
				picture.save_png(OUTPUT+NAMES[index]+"-preview.png")
		if not preview_only:
			assert(strip.save_png(OUTPUT+NAMES[index]+".png") == OK)
		print("LOOP_OK ",NAMES[index]," ",FRAMES," frames")
		world.remove_child(model)
		model.free()
		await process_frame
	quit()
