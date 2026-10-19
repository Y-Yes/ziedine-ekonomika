"""Shared Blender helpers for the 'Žiedinė ekonomika' 3D art.

Style: small low-poly dioramas on floating islands, soft sun + sky light,
bevelled toy-like edges, a restrained earthy palette.
"""
import bpy, bmesh, math, random, os
from mathutils import Vector, Euler

TAU = math.tau


def lin(h):
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1.0,)


# ------------------------------------------------------------------ palette
P = {
    'grass': '#8cc06a', 'grass2': '#6fa552', 'dirt': '#9a6b4a', 'rock': '#9a8270', 'rock2': '#85705f',
    'wall': '#f1e7d3', 'wall2': '#e3d5bb', 'trim': '#3f4a5c', 'glass': '#bfe3ff', 'wood': '#b07a4f',
    'roof_red': '#d0613f', 'orange': '#e8913a', 'yellow': '#e9c548', 'green': '#5cae68', 'blue': '#4f8fd8',
    'purple': '#9271d6', 'metal': '#aab4bd', 'dark': '#2f3542', 'white': '#f7f5ef', 'path': '#d9c9a6',
    'leaf': '#5f9e4a', 'leaf2': '#7bb85a', 'trunk': '#7a5236', 'bin_y': '#efc93f', 'bin_g': '#4fae63',
    'bin_b': '#4b86d3', 'red': '#d9534a', 'concrete': '#c9c3b8',
}

_mats = {}


def mat(key, rough=0.6, metal=0.0, emit=0.0, alpha=1.0, color=None):
    name = f"{key}_{rough}_{metal}_{emit}_{alpha}"
    if name in _mats:
        return _mats[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get('Principled BSDF')
    col = lin(color or P.get(key, key))
    b.inputs['Base Color'].default_value = col
    b.inputs['Roughness'].default_value = rough
    b.inputs['Metallic'].default_value = metal
    if emit > 0:
        b.inputs['Emission Color'].default_value = col
        b.inputs['Emission Strength'].default_value = emit
    if alpha < 1.0:
        b.inputs['Alpha'].default_value = alpha
    _mats[name] = m
    return m


def setup(res=320, samples=40, cam_scale=3.2, cam_target=(0, 0, 0.35), elev=58, azim=45):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 6
    sc.render.film_transparent = True
    sc.render.resolution_x = res
    sc.render.resolution_y = res
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    try:
        sc.view_settings.view_transform = 'AgX'
        sc.view_settings.look = 'AgX - Medium High Contrast'
    except Exception:
        pass
    # world: soft cool sky fill
    w = bpy.data.worlds.new('w')
    w.use_nodes = True
    bg = w.node_tree.nodes['Background']
    bg.inputs['Color'].default_value = lin('#b9d3f0')
    bg.inputs['Strength'].default_value = 0.9
    sc.world = w
    # sun (light from upper-left of the screen)
    sd = bpy.data.lights.new('sun', 'SUN')
    sd.energy = 3.6
    sd.angle = math.radians(12)
    sd.color = lin('#fff1dc')[:3]
    so = bpy.data.objects.new('sun', sd)
    sc.collection.objects.link(so)
    so.rotation_euler = Euler((math.radians(40), 0, math.radians(-15)), 'XYZ')
    # camera
    cd = bpy.data.cameras.new('cam')
    cd.type = 'ORTHO'
    cd.ortho_scale = cam_scale
    co = bpy.data.objects.new('cam', cd)
    sc.collection.objects.link(co)
    sc.camera = co
    rx, rz = math.radians(elev), math.radians(azim)
    fwd = Vector((0, 0, -1))
    fwd.rotate(Euler((rx, 0, rz), 'XYZ'))
    co.location = Vector(cam_target) - fwd * 20
    co.rotation_euler = Euler((rx, 0, rz), 'XYZ')
    cd.clip_end = 100
    return sc


def _finish(o, m, bevel=0.0, seg=2, smooth=True, angle=40):
    if m is not None:
        o.data.materials.append(m)
    if bevel > 0:
        mod = o.modifiers.new('bev', 'BEVEL')
        mod.width = bevel
        mod.segments = seg
        mod.limit_method = 'ANGLE'
    if smooth:
        for p in o.data.polygons:
            p.use_smooth = True
        try:
            o.modifiers.new('sm', 'SMOOTH_BY_ANGLE') if False else None
            bpy.context.view_layer.objects.active = o
            o.select_set(True)
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))
            o.select_set(False)
        except Exception:
            pass
    return o


def box(size, loc, m, bevel=0.03, rot=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    _finish(o, m, bevel)
    if parent:
        o.parent = parent
    return o


def cyl(r, h, loc, m, verts=32, bevel=0.02, rot=(0, 0, 0), r2=None, parent=None, smooth=True):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=loc, rotation=rot, vertices=verts)
    else:
        bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=r2, depth=h, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object
    _finish(o, m, bevel, smooth=smooth)
    if parent:
        o.parent = parent
    return o


def sphere(r, loc, m, seg=24, scale=(1, 1, 1), parent=None, ico=False, smooth=True):
    if ico:
        bpy.ops.mesh.primitive_ico_sphere_add(radius=r, location=loc, subdivisions=2)
    else:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=seg, ring_count=seg // 2)
    o = bpy.context.active_object
    o.scale = scale
    _finish(o, m, 0, smooth=smooth)
    if parent:
        o.parent = parent
    return o


def torus(R, r, loc, m, rot=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot,
                                     major_segments=32, minor_segments=12)
    o = bpy.context.active_object
    _finish(o, m, 0)
    if parent:
        o.parent = parent
    return o


def empty(loc=(0, 0, 0), parent=None):
    o = bpy.data.objects.new('e', None)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    if parent:
        o.parent = parent
    return o


def prism_roof(w, d, h, loc, m, overhang=0.06, rot_z=0.0):
    """Gable roof: ridge along local X."""
    mesh = bpy.data.meshes.new('roof')
    bm = bmesh.new()
    W, D = w / 2 + overhang, d / 2 + overhang
    v = [bm.verts.new(p) for p in [(-W, -D, 0), (W, -D, 0), (W, D, 0), (-W, D, 0), (-W, 0, h), (W, 0, h)]]
    bm.faces.new([v[0], v[1], v[5], v[4]])
    bm.faces.new([v[3], v[4], v[5], v[2]])
    bm.faces.new([v[0], v[4], v[3]])
    bm.faces.new([v[1], v[2], v[5]])
    bm.faces.new([v[0], v[3], v[2], v[1]])
    bm.to_mesh(mesh)
    o = bpy.data.objects.new('roof', mesh)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    o.rotation_euler = (0, 0, rot_z)
    mod = o.modifiers.new('sol', 'SOLIDIFY')
    mod.thickness = 0.05
    _finish(o, m, 0.015, smooth=False)
    return o


def island(r=1.0, seed=1, grass='grass', top_z=0.0):
    """Floating island: grassy top disc + rocky underside."""
    random.seed(seed)
    cyl(r, 0.14, (0, 0, top_z - 0.07), mat(grass, 0.8), verts=48, bevel=0.05)
    cyl(r * 0.985, 0.16, (0, 0, top_z - 0.21), mat('dirt', 0.9), verts=48, bevel=0.03)
    # rocky cone with jittered vertices (faceted, low-poly)
    bpy.ops.mesh.primitive_cone_add(radius1=r * 0.97, radius2=r * 0.12, depth=r * 0.62, vertices=14,
                                    location=(0, 0, top_z - 0.29 - r * 0.31), rotation=(math.pi, 0, 0))
    o = bpy.context.active_object
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)
    for v in bm.verts:
        if v.co.z < r * 0.39:
            v.co.x += random.uniform(-0.07, 0.07) * r
            v.co.y += random.uniform(-0.07, 0.07) * r
            v.co.z += random.uniform(-0.06, 0.06) * r
    bm.to_mesh(o.data)
    _finish(o, mat('rock', 0.9), 0, smooth=False)
    # a few small dangling rocks
    for k in range(3):
        a = random.uniform(0, TAU)
        sphere(0.07 * r, (math.cos(a) * 0.35 * r, math.sin(a) * 0.35 * r, top_z - 0.55 * r - random.uniform(0, .06)),
               mat('rock2', 0.9), ico=True, smooth=False)


def tree(loc, s=1.0, sway=0.0, kind=0):
    root = empty(loc)
    root.rotation_euler = (sway, sway * 0.5, 0)
    cyl(0.035 * s, 0.22 * s, (0, 0, 0.11 * s), mat('trunk', 0.8), verts=8, bevel=0, parent=root)
    if kind == 0:
        sphere(0.15 * s, (0, 0, 0.32 * s), mat('leaf', 0.8), parent=root, ico=True, smooth=True)
        sphere(0.11 * s, (0.07 * s, 0.05 * s, 0.42 * s), mat('leaf2', 0.8), parent=root, ico=True)
    else:
        cyl(0.15 * s, 0.32 * s, (0, 0, 0.36 * s), mat('leaf', 0.8), verts=8, r2=0.0, bevel=0, parent=root,
            smooth=False)
        cyl(0.11 * s, 0.24 * s, (0, 0, 0.5 * s), mat('leaf2', 0.8), verts=8, r2=0.0, bevel=0, parent=root,
            smooth=False)
    return root


def bush(loc, s=1.0):
    sphere(0.07 * s, loc, mat('leaf2', 0.85), ico=True)
    sphere(0.055 * s, (loc[0] + 0.06 * s, loc[1] + 0.02, loc[2] - 0.01), mat('leaf', 0.85), ico=True)


def bin3(loc, colkey, s=1.0, lid_open=0.0, rot_z=0.0):
    root = empty(loc)
    root.rotation_euler = (0, 0, rot_z)
    box((0.13 * s, 0.13 * s, 0.17 * s), (0, 0, 0.085 * s), mat(colkey, 0.5), bevel=0.012, parent=root)
    hinge = empty((0, 0.065 * s, 0.17 * s), parent=root)
    hinge.rotation_euler = (-lid_open, 0, 0)
    box((0.14 * s, 0.14 * s, 0.025 * s), (0, -0.065 * s, 0.012 * s), mat('trim', 0.5), bevel=0.008, parent=hinge)
    return root


def render_frames(update, n, out_dir, name):
    sc = bpy.context.scene
    os.makedirs(out_dir, exist_ok=True)
    paths = []
    for i in range(n):
        p = os.path.join(out_dir, f"{name}_{i:02d}.png")
        if os.environ.get('SKIP_EXISTING') and os.path.exists(p):
            paths.append(p)
            continue
        update(i / n)
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    return paths


def decor(seed=1, n=26, r_in=0.62, r_out=0.92, avoid=()):
    """Scatter flowers, grass tufts and pebbles around the island rim."""
    random.seed(seed * 31 + 7)
    flowers = ['#ffffff', '#ffd75e', '#f49ac1', '#ffb36b']
    placed = 0
    tries = 0
    while placed < n and tries < 400:
        tries += 1
        a = random.uniform(0, TAU)
        r = random.uniform(r_in, r_out)
        x, y = r * math.cos(a), r * math.sin(a)
        if any((x - ax) ** 2 + (y - ay) ** 2 < ar ** 2 for ax, ay, ar in avoid):
            continue
        k = random.random()
        if k < 0.45:
            c = random.choice(flowers)
            cyl(0.006, 0.05, (x, y, 0.025), mat('leaf', 0.8), verts=6, bevel=0, smooth=False)
            sphere(0.018, (x, y, 0.055), mat(c, 0.6, color=c), ico=True)
        elif k < 0.8:
            for j in range(3):
                cyl(0.014, 0.06, (x + 0.015 * (j - 1), y + 0.01 * (j % 2), 0.03), mat('grass2', 0.8), verts=5,
                    r2=0.0, bevel=0, smooth=False, rot=(0.25 * (j - 1), 0.2 * (j - 1), 0))
        else:
            sphere(0.03, (x, y, 0.01), mat('#c8bfb0', 0.8, color='#c8bfb0'), ico=True, scale=(1.2, 1, 0.6),
                   smooth=False)
        placed += 1
