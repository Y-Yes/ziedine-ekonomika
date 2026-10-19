"""Square floating city tiles (v2 station art): dense little districts on a grass-edged slab."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
from lib import *
from lib import _finish

HALF = 0.8          # half size of the tile
PAL = {
    'pave': '#7b8086', 'asph': '#3d4248', 'line': '#e9e6da', 'conc': '#c3c0b8', 'glassb': '#7fb2d9',
    'win': '#ffe2a0', 'roofd': '#4a5058', 'roofl': '#d5d2ca', 'solar': '#22406e',
}


def M(key, rough=0.6, metal=0.0, emit=0.0):
    return mat(key, rough, metal, emit, color=PAL.get(key, P.get(key, key)))


# ------------------------------------------------------------------ tile body
def tile(seed=1, ground='pave'):
    random.seed(seed)
    first = set(bpy.data.objects)
    box((2 * HALF + 0.1, 2 * HALF + 0.1, 0.07), (0, 0, -0.035), M('grass', 0.85), bevel=0.035)
    box((2 * HALF + 0.06, 2 * HALF + 0.06, 0.2), (0, 0, -0.17), M('dirt', 0.9), bevel=0.02)
    box((2 * HALF - 0.04, 2 * HALF - 0.04, 0.012), (0, 0, 0.006), M(ground, 0.85), bevel=0.004)
    # jagged rocky underside: square pyramid + spikes
    bpy.ops.mesh.primitive_cone_add(radius1=HALF * 1.38, radius2=0.08, depth=0.75, vertices=4,
                                    location=(0, 0, -0.27 - 0.375), rotation=(math.pi, 0, math.pi / 4))
    o = bpy.context.active_object
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
    for v in bm.verts:
        if v.co.z < 0.36:
            v.co.x += random.uniform(-0.09, 0.09); v.co.y += random.uniform(-0.09, 0.09)
            v.co.z += random.uniform(-0.08, 0.06)
    bm.to_mesh(o.data)
    _finish(o, M('rock', 0.9), 0, smooth=False)
    for k in range(5):
        x, y = random.uniform(-0.6, 0.6), random.uniform(-0.6, 0.6)
        cyl(random.uniform(0.08, 0.14), random.uniform(0.2, 0.35), (x, y, -0.36), M('rock2', 0.9), verts=5,
            r2=0.0, bevel=0, rot=(math.pi, 0, random.uniform(0, 3)), smooth=False)
    # grass tufts and small trees along the rim
    for k in range(14):
        side = random.randint(0, 3)
        t = random.uniform(-HALF + 0.05, HALF - 0.05)
        x, y = [(t, -HALF + 0.03), (HALF - 0.03, t), (t, HALF - 0.03), (-HALF + 0.03, t)][side]
        sphere(random.uniform(0.025, 0.04), (x, y, 0.02), M('leaf2', 0.85), ico=True, scale=(1.3, 1.3, 0.8))
    for o in bpy.data.objects:
        if o not in first:
            o['tile'] = True


# ------------------------------------------------------------------ props
def road(x0, y0, x1, y1, w=0.16, dashes=True):
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    horiz = abs(x1 - x0) > abs(y1 - y0)
    L = abs(x1 - x0) if horiz else abs(y1 - y0)
    box((L, w, 0.008) if horiz else (w, L, 0.008), (cx, cy, 0.016), M('asph', 0.8), bevel=0.0)
    if dashes:
        n = int(L / 0.12)
        for k in range(n):
            u = -L / 2 + (k + 0.5) * L / n
            if horiz:
                box((0.05, 0.008, 0.004), (cx + u, cy, 0.021), M('line', 0.7), bevel=0)
            else:
                box((0.008, 0.05, 0.004), (cx, cy + u, 0.021), M('line', 0.7), bevel=0)


def windows(x, y, w, d, h, floors, lit=0.6, col='win', z0=0.0):
    """Window bands on the two faces the camera sees (-y and +x)."""
    fh = h / floors
    m = mat(col, 0.25, emit=lit, color=PAL.get(col, col))
    for f in range(floors):
        z = z0 + fh * (f + 0.55)
        box((w * 0.82, 0.006, fh * 0.38), (x, y - d / 2 - 0.002, z), m, bevel=0)
        box((0.006, d * 0.82, fh * 0.38), (x + w / 2 + 0.002, y, z), m, bevel=0)


def building(x, y, w, d, h, col='wall', roof='roofd', floors=None, lit=0.6, wincol='win', details=True, rz=0):
    box((w, d, h), (x, y, h / 2 + 0.012), M(col, 0.7), bevel=0.01)
    box((w + 0.012, d + 0.012, 0.02), (x, y, h + 0.02), M(roof, 0.7), bevel=0.005)
    if floors is None:
        floors = max(1, int(h / 0.1))
    windows(x, y, w, d, h, floors, lit, wincol, z0=0.012)
    if details:
        for k in range(random.randint(1, 3)):
            box((0.04, 0.04, 0.03), (x + random.uniform(-w / 3, w / 3), y + random.uniform(-d / 3, d / 3), h + 0.045),
                M('metal', 0.5, 0.4), bevel=0.005)


def house(x, y, w=0.2, d=0.18, h=0.12, wall='wall', roofc='roof_red', rz=0.0):
    root = empty((x, y, 0.012))
    root.rotation_euler = (0, 0, rz)
    box((w, d, h), (0, 0, h / 2), M(wall, 0.7), bevel=0.008, parent=root)
    r = prism_roof(w, d, h * 0.7, (0, 0, h), M(roofc, 0.6), overhang=0.02)
    r.parent = root
    box((0.035, 0.006, 0.06), (0.03, -d / 2 - 0.002, 0.03), M('wood', 0.6), bevel=0, parent=root)
    box((0.04, 0.006, 0.03), (-0.05, -d / 2 - 0.002, 0.075), M('win', 0.3, emit=0.8), bevel=0, parent=root)
    return root


def solar(x, y, w, d, z=0.012, rot=0.0):
    root = empty((x, y, z))
    root.rotation_euler = (0, 0, rot)
    nx, ny = max(1, int(w / 0.07)), max(1, int(d / 0.06))
    for i in range(nx):
        for j in range(ny):
            box((0.06, 0.05, 0.006), (-w / 2 + (i + 0.5) * w / nx, -d / 2 + (j + 0.5) * d / ny, 0.025),
                M('solar', 0.25, 0.4), bevel=0.002, rot=(math.radians(-25), 0, 0), parent=root)
    return root


def car(x, y, rz, col):
    root = empty((x, y, 0.016))
    root.rotation_euler = (0, 0, rz)
    box((0.07, 0.035, 0.02), (0, 0, 0.014), M(col, 0.35, 0.2), bevel=0.006, parent=root)
    box((0.038, 0.03, 0.016), (-0.004, 0, 0.031), M('glassb', 0.15), bevel=0.005, parent=root)
    return root


def truck(x, y, rz, col='orange', s=1.0):
    root = empty((x, y, 0.016))
    root.rotation_euler = (0, 0, rz)
    box((0.11 * s, 0.055 * s, 0.05 * s), (-0.02 * s, 0, 0.033 * s), M(col, 0.45), bevel=0.008 * s, parent=root)
    box((0.04 * s, 0.052 * s, 0.04 * s), (0.055 * s, 0, 0.028 * s), M('white', 0.45), bevel=0.008 * s, parent=root)
    box((0.004, 0.04 * s, 0.018 * s), (0.076 * s, 0, 0.036 * s), M('glassb', 0.15), bevel=0, parent=root)
    return root


def container(x, y, rz, col, l=0.16, h=0.05):
    root = empty((x, y, 0.016))
    root.rotation_euler = (0, 0, rz)
    box((l, 0.055, h), (0, 0, h / 2), M(col, 0.6, 0.2), bevel=0.004, parent=root)
    for k in range(6):
        box((0.004, 0.057, h * 0.9), (-l / 2 + (k + 0.5) * l / 6, 0, h / 2), M(col, 0.6, 0.2), bevel=0, parent=root)
    return root


def small_tree(x, y, s=1.0):
    cyl(0.008 * s, 0.05 * s, (x, y, 0.035 * s), M('trunk', 0.8), verts=6, bevel=0, smooth=False)
    sphere(0.035 * s, (x, y, 0.08 * s), M(random.choice(['leaf', 'leaf2']), 0.8), ico=True)


def dome(x, y, r, col='white', ring='green'):
    sphere(r, (x, y, 0.012), M(col, 0.4), scale=(1, 1, 0.85))
    cyl(r * 1.02, 0.03, (x, y, 0.027), M(ring, 0.5), verts=48, bevel=0.005)
    for k in range(3):
        torus(r * (0.98 - k * 0.0), 0.006, (x, y, 0.012 + r * 0.85 * math.sin(math.radians(25 + k * 22))) ,
              M(ring, 0.5))
    return None


def silo(x, y, r, h, col='green'):
    cyl(r, h, (x, y, h / 2 + 0.012), M(col, 0.45), verts=24, bevel=0.006)
    sphere(r, (x, y, h + 0.012), M(col, 0.45), scale=(1, 1, 0.45))
    for z in (h * 0.3, h * 0.65):
        cyl(r * 1.03, 0.012, (x, y, z), M('trim', 0.5), verts=24, bevel=0)


def puffs(n, x, y, z, rise=0.35, size=0.035, drift=(0.08, 0.03)):
    objs = [sphere(size, (0, 0, -5), M('white', 0.9), ico=True) for _ in range(n)]

    def upd(t):
        for k, p in enumerate(objs):
            u = (t + k / n) % 1.0
            p.location = (x + drift[0] * u, y + drift[1] * u, z + rise * u)
            s = 0.5 + 1.4 * u
            p.scale = (s, s, s) if u < 0.8 else (s * (1 - u) / 0.2,) * 3
    return upd


def mover(objs, path, phase_step=None):
    """Move objects along a closed polyline path (list of (x,y)); returns update(t)."""
    pts = [Vector((p[0], p[1], 0)) for p in path]
    segs = [(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts))]
    lens = [(b - a).length for a, b in segs]
    tot = sum(lens)
    n = len(objs)

    def pos(u):
        d = (u % 1.0) * tot
        for (a, b), L in zip(segs, lens):
            if d <= L:
                v = a + (b - a) * (d / L)
                ang = math.atan2((b - a).y, (b - a).x)
                return v, ang
            d -= L
        return pts[0], 0.0

    def upd(t):
        for k, o in enumerate(objs):
            v, ang = pos(t + k / n)
            o.location.x, o.location.y = v.x, v.y
            o.rotation_euler = (0, 0, ang)
    return upd


# ------------------------------------------------------------------ 6 districts
def t_naudotojas():
    tile(3)
    road(-HALF + 0.02, -0.05, HALF - 0.02, -0.05)
    road(0.05, -HALF + 0.02, 0.05, HALF - 0.02)
    random.seed(11)
    roofs = ['roof_red', '#7a8fa6', '#b06a45', 'roof_red', '#5f6f7f']
    walls = ['wall', '#e8dcc6', '#f3efe6', '#d9cdb5']
    for k, (x, y) in enumerate([(-0.55, 0.2), (-0.3, 0.2), (-0.55, 0.5), (-0.3, 0.5), (0.32, 0.55), (0.6, 0.55)]):
        house(x, y, roofc=roofs[k % len(roofs)], wall=walls[k % len(walls)], rz=random.choice([0, math.pi / 2]))
    building(0.4, 0.2, 0.28, 0.2, 0.3, col='#e9e2d4', roof='roofl', lit=0.7)
    solar(0.4, 0.2, 0.22, 0.14, z=0.33)
    building(-0.45, -0.45, 0.3, 0.26, 0.22, col='#dfe4e8', roof='roofl', lit=0.7)
    solar(-0.45, -0.45, 0.24, 0.2, z=0.25)
    for k, c in enumerate(['bin_y', 'bin_g', 'bin_b']):
        box((0.04, 0.04, 0.05), (0.22 + k * 0.05, -0.2, 0.037), M(c, 0.5), bevel=0.006)
    for k, (x, y) in enumerate([(0.3, -0.35), (0.55, -0.35), (0.3, -0.62), (0.55, -0.62)]):
        house(x, y, roofc=roofs[(k + 2) % len(roofs)], wall=walls[(k + 1) % len(walls)], rz=random.choice([0, math.pi / 2]))
    building(-0.2, 0.55, 0.16, 0.16, 0.4, col='#d9dfe6', roof='roofl', lit=0.8)
    for (x, y) in [(0.7, -0.2), (-0.15, -0.65), (-0.7, -0.15), (-0.12, 0.33), (-0.18, -0.25)]:
        small_tree(x, y, 1.1)
    cars = [car(0, 0, 0, c) for c in ['red', '#e9e9e9', '#3f6fb5', '#f2c040']]
    u1 = mover(cars[:2], [(-0.75, -0.09), (0.75, -0.09)] + [(0.75, -0.01), (-0.75, -0.01)])
    u2 = mover(cars[2:], [(0.01, -0.75), (0.01, 0.75), (0.09, 0.75), (0.09, -0.75)])
    p = puffs(3, -0.55, 0.5, 0.25, rise=0.25, size=0.025)

    def update(t):
        u1(t); u2(t); p(t)
    return update


def t_surinkimas():
    tile(7)
    road(-HALF + 0.02, -0.5, HALF - 0.02, -0.5)
    random.seed(7)
    # hangar with roller doors
    box((0.9, 0.42, 0.26), (-0.25, 0.4, 0.142), M('#d8d2c4', 0.7), bevel=0.01)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.21, depth=0.92, location=(-0.25, 0.4, 0.27), rotation=(0, math.pi / 2, 0), vertices=32)
    o = bpy.context.active_object; o.scale = (1, 1, 0.45); _finish(o, M('#7a8a99', 0.5, 0.3), 0)
    for k in range(4):
        box((0.15, 0.006, 0.17), (-0.6 + k * 0.23, 0.188, 0.097), M('#8d97a3', 0.5, 0.3), bevel=0.002)
        box((0.05, 0.006, 0.02), (-0.6 + k * 0.23, 0.186, 0.2), M('orange', 0.4, emit=1.5), bevel=0)
    # parked trucks in a row
    for k in range(5):
        truck(-0.62 + k * 0.2, 0.0, math.pi / 2, random.choice(['orange', 'green', 'orange']), 1.25)
    # skip containers
    for k, c in enumerate(['bin_y', 'bin_b', 'bin_g', '#c0583a']):
        container(0.5, 0.15 + k * 0.08, 0, c, l=0.2)
    container(0.5, 0.2, 0, '#5b7a99', l=0.2).location.z = 0.07
    building(0.45, -0.68, 0.3, 0.14, 0.12, col='#e6e1d3', roof='roofd', lit=0.5)
    building(-0.45, -0.68, 0.4, 0.14, 0.16, col='#cfd6dc', roof='roofd', lit=0.5)
    for k in range(3):
        container(0.55, 0.62 - k * 0.0, 0, ['#c0583a', '#5b7a99', 'bin_g'][k], l=0.2).location.z = 0.016 + k * 0.05
    for (x, y) in [(0.72, 0.42), (0.1, -0.68), (-0.75, -0.3)]:
        small_tree(x, y, 1.1)
    movers = [truck(0, 0, 0, 'orange', 1.25), truck(0, 0, 0, 'green', 1.25)]
    u = mover(movers, [(-0.75, -0.54), (0.75, -0.54), (0.75, -0.46), (-0.75, -0.46)])
    beacon = cyl(0.02, 0.02, (-0.25, 0.62, 0.33), mat('#ffb21f', 0.3, emit=0.0), verts=12, bevel=0.004)
    bm = beacon.data.materials[0].copy(); beacon.data.materials[0] = bm

    def update(t):
        u(t)
        on = (int(t * 24) // 3) % 2 == 0
        n = bm.node_tree.nodes['Principled BSDF']
        n.inputs['Emission Color'].default_value = lin('#ffb21f')
        n.inputs['Emission Strength'].default_value = 8.0 if on else 0.2
    return update


def t_rusiavimas():
    tile(11)
    random.seed(12)
    building(-0.3, 0.35, 0.8, 0.5, 0.28, col='#e6e1d3', roof='yellow', floors=2, lit=0.5)
    box((0.2, 0.006, 0.16), (-0.1, 0.098, 0.092), M('dark', 0.7), bevel=0)
    # conveyor out to the bale yard
    L = 0.8
    box((L, 0.08, 0.02), (0.2, -0.02, 0.1), M('#3a3f48', 0.5), bevel=0.004)
    for k in range(5):
        box((0.015, 0.06, 0.09), (-0.15 + k * 0.18, -0.02, 0.055), M('metal', 0.4, 0.5), bevel=0.002)
    items = []
    for k in range(7):
        c = ['bin_y', 'bin_b', 'bin_g'][k % 3]
        items.append(box((0.04, 0.04, 0.03), (0, 0, -5), M(c, 0.5), bevel=0.005))
    # stacked bales by colour
    for gi, c in enumerate(['bin_y', 'bin_b', 'bin_g']):
        for i in range(3):
            for j in range(2):
                for z in range(2 if (i + j) % 2 == 0 else 1):
                    box((0.07, 0.07, 0.06), (-0.55 + gi * 0.27 + i * 0.075, -0.32 - j * 0.075, 0.042 + z * 0.062),
                        M(c, 0.75), bevel=0.008)
    # bin rows
    for k in range(6):
        box((0.045, 0.045, 0.06), (0.35 + (k % 3) * 0.06, -0.45 - (k // 3) * 0.08, 0.042),
            M(['bin_y', 'bin_g', 'bin_b'][k % 3], 0.5), bevel=0.006)
    truck(0.55, 0.45, 0, 'orange', 1.25)
    truck(0.55, 0.3, 0, 'green', 1.25)
    building(0.55, -0.62, 0.36, 0.22, 0.2, col='#d8d2c4', roof='roofd', floors=2, lit=0.5)
    building(0.55, 0.1, 0.25, 0.12, 0.1, col='#cfd6dc', roof='roofd', floors=1, lit=0.4)
    for (x, y) in [(0.7, -0.7), (-0.7, -0.7), (0.68, 0.68)]:
        small_tree(x, y, 1.1)

    def update(t):
        n = len(items)
        for k, o in enumerate(items):
            u = (t + k / n) % 1.0
            o.location = (-0.2 + u * L, -0.02, 0.127)
            s = min(1.0, u / 0.05, (1 - u) / 0.05)
            o.scale = (max(s, 0.01),) * 3
    return update


def t_perdirbimas():
    tile(5)
    random.seed(5)
    road(-HALF + 0.02, -0.55, HALF - 0.02, -0.55)
    dome(-0.32, 0.25, 0.27, 'white', 'green')
    dome(0.3, 0.42, 0.2, '#e8efe9', 'green')
    for k, (x, y) in enumerate([(0.55, 0.0), (0.4, -0.1), (0.62, 0.15)]):
        silo(x, y, 0.06, 0.28, 'green')
    building(0.05, -0.2, 0.3, 0.2, 0.14, col='#e6e1d3', roof='roofd', lit=0.5)
    # pipes
    cyl(0.018, 0.5, (0.15, 0.1, 0.12), M('metal', 0.4, 0.5), verts=12, rot=(0, math.pi / 2, 0.6))
    cyl(0.018, 0.4, (-0.1, 0.0, 0.08), M('metal', 0.4, 0.5), verts=12, rot=(math.pi / 2, 0, 0.3))
    # pellet piles
    for k, (x, y, c) in enumerate([(-0.55, -0.25, 'bin_g'), (-0.4, -0.38, 'white'), (-0.62, -0.42, 'bin_b')]):
        cyl(0.09, 0.07, (x, y, 0.047), M(c, 0.7), verts=16, r2=0.01, bevel=0.01)
    for (x, y) in [(-0.7, 0.68), (0.7, -0.7), (-0.15, -0.7)]:
        small_tree(x, y, 1.1)
    trucks_ = [truck(0, 0, 0, 'green', 1.2), truck(0, 0, 0, 'white', 1.2)]
    u = mover(trucks_, [(-0.75, -0.59), (0.75, -0.59), (0.75, -0.51), (-0.75, -0.51)])
    p = puffs(3, 0.55, 0.0, 0.34, rise=0.25, size=0.025)

    def update(t):
        u(t); p(t)
    return update


def t_gamykla():
    tile(9)
    random.seed(9)
    # sawtooth halls
    for hi, (x, y, w) in enumerate([(-0.3, 0.35, 0.8), (-0.3, -0.05, 0.8)]):
        box((w, 0.3, 0.18), (x, y, 0.102), M('#dfe6ee', 0.7), bevel=0.008)
        box((w + 0.005, 0.305, 0.03), (x, y, 0.03), M('blue', 0.55), bevel=0.003)
        for k in range(5):
            xx = x - w / 2 + (k + 0.5) * w / 5
            prism_roof(0.3, w / 5, 0.07, (xx, y, 0.192), M('blue', 0.5), overhang=0.0, rot_z=math.pi / 2)
        windows(x, y, w, 0.3, 0.18, 2, 0.8, 'win', z0=0.012)
    # chimneys
    for k, (x, y) in enumerate([(0.25, 0.5), (0.38, 0.42)]):
        cyl(0.04, 0.5, (x, y, 0.262), M('#b45a40', 0.8), verts=16, bevel=0.005, r2=0.032)
        cyl(0.036, 0.02, (x, y, 0.4), M('white', 0.6), verts=16, bevel=0)
    # solar field
    solar(0.45, -0.35, 0.5, 0.45)
    # tanks
    for (x, y) in [(0.6, 0.15), (0.45, 0.12)]:
        cyl(0.06, 0.1, (x, y, 0.062), M('#e9e9e9', 0.4, 0.3), verts=24, bevel=0.01)
    building(-0.45, -0.5, 0.45, 0.3, 0.14, col='#cfd6dc', roof='roofd', lit=0.5)
    for k in range(4):
        truck(-0.62 + k * 0.12, -0.25, math.pi / 2, 'blue', 1.1)
    for (x, y) in [(-0.1, -0.7), (0.7, 0.7)]:
        small_tree(x, y, 1.1)
    p1 = puffs(4, 0.25, 0.5, 0.52, rise=0.35, size=0.035)
    p2 = puffs(3, 0.38, 0.42, 0.52, rise=0.3, size=0.03)

    def update(t):
        p1(t); p2((t + 0.37) % 1.0)
    return update


def t_parduotuve():
    tile(13)
    random.seed(13)
    road(-HALF + 0.02, -0.5, HALF - 0.02, -0.5)
    # mall with glass facade
    box((0.7, 0.4, 0.22), (-0.2, 0.35, 0.122), M('#e9e4da', 0.6), bevel=0.01)
    box((0.66, 0.006, 0.12), (-0.2, 0.148, 0.09), M('glassb', 0.15, emit=0.35), bevel=0)
    box((0.006, 0.36, 0.12), (0.152, 0.35, 0.09), M('glassb', 0.15, emit=0.35), bevel=0)
    box((0.3, 0.01, 0.05), (-0.2, 0.145, 0.19), M('purple', 0.5, emit=0.4), bevel=0.004)
    box((0.72, 0.42, 0.02), (-0.2, 0.35, 0.24), M('roofl', 0.7), bevel=0.005)
    # small shops with awnings
    for k, c in enumerate(['purple', 'red', 'bin_g']):
        x = 0.42
        y = 0.55 - k * 0.2
        box((0.22, 0.16, 0.13), (x, y, 0.077), M('#efe8dc', 0.7), bevel=0.008)
        box((0.006, 0.12, 0.06), (x + 0.112, y, 0.055), M('win', 0.3, emit=0.8), bevel=0)
        for s in range(4):
            box((0.05, 0.035, 0.008), (x + 0.135, y - 0.06 + s * 0.04, 0.11), M(c if s % 2 == 0 else 'white', 0.6),
                bevel=0.001, rot=(0, math.radians(25), 0))
    # parking lot
    box((0.7, 0.3, 0.006), (-0.25, -0.12, 0.016), M('asph', 0.8), bevel=0)
    for k in range(7):
        box((0.004, 0.1, 0.004), (-0.58 + k * 0.1, -0.12, 0.02), M('line', 0.7), bevel=0)
    random.seed(4)
    for k in range(5):
        car(-0.53 + k * 0.1 + (0.0 if k != 3 else 0.1), -0.12, math.pi / 2,
            random.choice(['red', '#e9e9e9', '#3f6fb5', '#f2c040', '#2f3542']))
    for k, (x, rc) in enumerate([(-0.55, '#7a8fa6'), (-0.25, 'roof_red'), (0.05, '#5f6f7f'), (0.4, 'roof_red')]):
        house(x, -0.68, w=0.22, d=0.14, h=0.13, roofc=rc)
    building(-0.62, 0.62, 0.2, 0.16, 0.36, col='#d9dfe6', roof='roofl', lit=0.8)
    for (x, y) in [(0.7, -0.68), (-0.75, -0.3)]:
        small_tree(x, y, 1.1)
    cars = [car(0, 0, 0, c) for c in ['red', '#3f6fb5', '#e9e9e9']]
    u = mover(cars, [(-0.75, -0.54), (0.75, -0.54), (0.75, -0.46), (-0.75, -0.46)])
    sign = empty((0.05, 0.05, 0.3))
    cyl(0.07, 0.015, (0, 0, 0), M('#f2c040', 0.3, 0.7), verts=32, bevel=0.004, rot=(math.pi / 2, 0, 0), parent=sign)
    cyl(0.008, 0.29, (0.05, 0.05, 0.155), M('trim', 0.5), verts=8)

    def update(t):
        u(t)
        sign.rotation_euler = (0, 0, math.pi * t)
    return update


def t_savartynas():
    tile(21, ground='#8a7a62')
    random.seed(21)
    for k in range(9):
        a = math.radians(-40 + k * 20)
        box((0.02, 0.02, 0.1), (-0.7 + k * 0.17, 0.72, 0.06), M('wood', 0.8), bevel=0.004)
    box((1.4, 0.008, 0.015), (0, 0.72, 0.09), M('wood', 0.8), bevel=0)
    torus(0.05, 0.02, (-0.6, -0.55, 0.035), M('dark', 0.7))
    cyl(0.05, 0.12, (0.6, -0.5, 0.072), M('#a5583a', 0.7, 0.3), verts=16, bevel=0.008)
    container(0.55, 0.5, 0.3, '#7b8a3a')

    def update(t):
        pass
    return update


TILES = {'1_naudotojas': t_naudotojas, '2_surinkimas': t_surinkimas, '3_rusiavimas': t_rusiavimas,
         '4_perdirbimas': t_perdirbimas, '5_gamykla': t_gamykla, '6_parduotuve': t_parduotuve,
         'savartynas': t_savartynas}

if __name__ == '__main__':
    name, mode = sys.argv[1], sys.argv[2]
    setup(res=384, samples=14, cam_scale=2.75, cam_target=(0, 0, 0.0))
    before = set(bpy.data.objects)
    upd = TILES[name]()
    # make districts taller/denser looking: everything except the tile slab sits under a z-scaled parent
    content = empty((0, 0, 0))
    content.scale = (1, 1, 1.35)
    for o in list(bpy.data.objects):
        if o.parent is None and o not in before and o is not content and not o.get('tile'):
            o.parent = content
    if mode == 'preview':
        upd(0.1)
        bpy.context.scene.render.filepath = f'/home/claude/gen/b3d/prev_t_{name}.png'
        bpy.ops.render.render(write_still=True)
    else:
        render_frames(upd, 24 if name != 'savartynas' else 1, '/home/claude/gen/b3d/frames2', name)
