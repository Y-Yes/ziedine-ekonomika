"""Small 3D props: belt tokens, HUD icons, sorting items + bins, investment card icons."""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
from lib import *

OUT = '/home/claude/gen/b3d/frames'


def clear_scene():
    for o in list(bpy.data.objects):
        if o.name not in ('sun', 'cam'):
            bpy.data.objects.remove(o, do_unlink=True)


def shot(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def text_obj(s, loc, size, m, rot=(0, 0, 0), depth=0.02, parent=None):
    bpy.ops.object.text_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.data.body = s
    o.data.size = size
    o.data.extrude = depth
    o.data.align_x = 'CENTER'
    o.data.align_y = 'CENTER'
    try:
        o.data.font = bpy.data.fonts.load('/home/claude/gen/test/art/fonts/Nunito-ExtraBold.ttf')
    except Exception:
        pass
    o.data.materials.append(m)
    if parent:
        o.parent = parent
    return o


# ------------------------------------------------------------------ props
def bottle(loc, colkey='#9fd8f2', cap='blue', s=1.0, rot=(0, 0, 0), parent=None, glass=False):
    root = empty(loc, parent=parent)
    root.rotation_euler = rot
    body = mat(colkey, 0.08 if glass else 0.15, color=colkey)
    cyl(0.1 * s, 0.32 * s, (0, 0, 0.16 * s), body, verts=24, bevel=0.03 * s, parent=root)
    cyl(0.1 * s, 0.12 * s, (0, 0, 0.38 * s), body, verts=24, bevel=0.01 * s, r2=0.04 * s, parent=root)
    cyl(0.04 * s, 0.06 * s, (0, 0, 0.46 * s), body, verts=16, bevel=0.005 * s, parent=root)
    cyl(0.048 * s, 0.05 * s, (0, 0, 0.51 * s), mat(cap, 0.4), verts=16, bevel=0.01 * s, parent=root)
    cyl(0.102 * s, 0.1 * s, (0, 0, 0.18 * s), mat('red', 0.5), verts=24, bevel=0.004 * s, parent=root)
    return root


def coin(loc, r=0.2, parent=None, rot=(0, 0, 0), euro=True):
    root = empty(loc, parent=parent)
    root.rotation_euler = rot
    cyl(r, r * 0.22, (0, 0, 0), mat('#f2c040', 0.28, 0.85), verts=48, bevel=r * 0.06, parent=root)
    cyl(r * 0.78, r * 0.24, (0, 0, 0), mat('#e3a92a', 0.32, 0.85), verts=48, bevel=r * 0.03, parent=root)
    if euro:
        text_obj('€', (0, 0, r * 0.12), r * 1.15, mat('#b8800f', 0.35, 0.8), depth=r * 0.05, parent=root)
    return root


def box_crate(loc, s=1.0, parent=None, rot=(0, 0, 0)):
    root = empty(loc, parent=parent)
    root.rotation_euler = rot
    box((0.4 * s, 0.32 * s, 0.3 * s), (0, 0, 0.15 * s), mat('#c9965a', 0.75), bevel=0.02 * s, parent=root)
    box((0.41 * s, 0.08 * s, 0.305 * s), (0, 0, 0.152 * s), mat('#e8cf9e', 0.6), bevel=0.005 * s, parent=root)
    return root


def puck(colhex, parent=None):
    cyl(0.42, 0.1, (0, 0, -0.05), mat(colhex, 0.45, color=colhex), verts=48, bevel=0.035, parent=parent)
    cyl(0.36, 0.11, (0, 0, -0.05), mat(colhex, 0.45, color=colhex), verts=48, bevel=0.02, parent=parent)


STAGE_HEX = ['#e05a5a', '#e8913a', '#e0c03c', '#55b867', '#4a8fe0', '#9a6ae0']


def token(i):
    root = empty((0, 0, 0))
    puck(STAGE_HEX[i], root)
    if i == 0:   # used bottle lying
        bottle((-0.26, 0.12, 0.13), '#a9dcf2', 'blue', 1.05, rot=(0, math.radians(84), math.radians(-30)), parent=root)
    elif i == 1:  # trash bag
        bm = mat('#5b6b7a', 0.3)
        sphere(0.27, (0, 0, 0.2), bm, parent=root, scale=(1, 0.9, 0.85))
        cyl(0.22, 0.2, (0, 0, 0.36), bm, verts=24, r2=0.05, bevel=0.02, parent=root)
        sphere(0.05, (0, 0, 0.47), mat('#e8913a', 0.5), parent=root)
        sphere(0.07, (-0.07, 0, 0.54), bm, parent=root, scale=(1.3, 0.6, 0.8))
        sphere(0.07, (0.07, 0, 0.54), bm, parent=root, scale=(1.3, 0.6, 0.8))
    elif i == 2:  # bale with straps
        box((0.48, 0.4, 0.34), (0, 0, 0.18), mat('#dfd3a8', 0.8), bevel=0.04, parent=root)
        for x in (-0.1, 0.1):
            box((0.04, 0.42, 0.36), (x, 0, 0.18), mat('#3a6fb3', 0.5), bevel=0.01, parent=root)
    elif i == 3:  # pellets
        random.seed(2)
        for k in range(18):
            a = random.uniform(0, TAU); r = random.uniform(0, 0.24)
            c = random.choice(['#3f9a55', '#f2f2ec', '#3f7fd0', '#3f9a55'])
            sphere(0.08, (r * math.cos(a), r * math.sin(a), 0.05 + (0.24 - r) * 0.7 * random.uniform(0.5, 1)),
                   mat(c, 0.35, color=c), parent=root, ico=True)
    elif i == 4:  # product box
        box_crate((0, 0, 0.0), 1.25, parent=root, rot=(0, 0, 0.3))
    elif i == 5:  # shopping bag
        box((0.44, 0.24, 0.44), (0, 0, 0.22), mat('#f4efe6', 0.6), bevel=0.02, parent=root)
        box((0.442, 0.242, 0.1), (0, 0, 0.36), mat('#7d55c9', 0.5), bevel=0.005, parent=root)
        torus(0.11, 0.02, (0, 0, 0.46), mat('#6d4bb0', 0.5), rot=(math.pi / 2, 0, 0), parent=root)
    return root


def hud_icon(i):
    root = empty((0, 0, 0))
    if i == 0:
        coin((0, 0, 0), 0.42, parent=root, rot=(math.radians(90), 0, 0))
    elif i == 1:  # leaf
        sphere(0.35, (0, 0, 0), mat('#5cb86a', 0.45), parent=root, scale=(0.55, 1.0, 0.12), seg=32)
        cyl(0.018, 0.75, (0, -0.05, 0.02), mat('#3d8a4a', 0.5), verts=8, rot=(math.pi / 2, 0, 0), parent=root)
        root.rotation_euler = (math.radians(70), math.radians(-35), math.radians(10))
    else:  # cycle arrows
        cycle_arrows(root, 0.33, 0.06, '#4a9ee8')
        root.rotation_euler = (math.radians(80), 0, 0)
    return root


def cycle_arrows(root, R, th, col):
    if True:
        for k in range(3):
            g = empty((0, 0, 0), parent=root)
            g.rotation_euler = (0, 0, k * TAU / 3)
            bpy.ops.curve.primitive_bezier_circle_add(radius=R)
            c = bpy.context.active_object
            c.data.bevel_depth = th
            c.data.bevel_resolution = 4
            c.data.bevel_factor_start = 0.03
            c.data.bevel_factor_end = 0.24
            c.data.use_fill_caps = True
            c.data.materials.append(mat(col, 0.4, color=col))
            c.parent = g
            a = 0.25 * TAU + 0.02
            tip = cyl(th * 1.85, th * 3, (R * math.cos(a), R * math.sin(a), 0), mat(col, 0.4, color=col), verts=24,
                      r2=0.0, bevel=0.0, rot=(-math.pi / 2, 0, a), parent=g)


SORT_HEX = {'y': '#efc93f', 'g': '#4fae63', 'b': '#4b86d3'}


def sort_item(i):
    root = empty((0, 0, 0))
    if i == 0:  # PET bottle
        bottle((0, 0, -0.3), '#bfe6f8', 'blue', 1.15, rot=(0, 0.2, 0), parent=root)
    elif i == 1:  # can
        cyl(0.17, 0.48, (0, 0, -0.05), mat('#d9dee4', 0.25, 0.9), verts=40, bevel=0.03, parent=root)
        cyl(0.172, 0.24, (0, 0, -0.05), mat('#e0403a', 0.4), verts=40, bevel=0.005, parent=root)
        cyl(0.13, 0.02, (0, 0, 0.2), mat('#b9c0c8', 0.3, 0.9), verts=40, bevel=0.005, parent=root)
        root.rotation_euler = (0.15, 0.25, 0)
    elif i == 2:  # jar
        cyl(0.2, 0.38, (0, 0, -0.1), mat('#cfeedd', 0.08), verts=40, bevel=0.06, parent=root)
        cyl(0.17, 0.09, (0, 0, 0.14), mat('#d6a23a', 0.35, 0.6), verts=40, bevel=0.02, parent=root)
        cyl(0.202, 0.16, (0, 0, -0.1), mat('#f6f1e6', 0.6), verts=40, bevel=0.003, parent=root)
        sphere(0.05, (0, -0.2, -0.1), mat('red', 0.4), parent=root, scale=(1, 0.3, 1))
    elif i == 3:  # glass bottle
        bottle((0, 0, -0.32), '#3f9e62', 'yellow', 1.2, rot=(0, -0.2, 0), parent=root, glass=True)
    elif i == 4:  # newspaper
        for k in range(3):
            box((0.5, 0.38, 0.025), (0, 0, -0.05 + k * 0.026), mat('#f2f0ea' if k < 2 else '#ecebe6', 0.8),
                bevel=0.006, rot=(0, 0, 0.06 * k), parent=root)
        box((0.4, 0.06, 0.005), (0, 0.11, 0.03), mat('#3a4250', 0.6), bevel=0.0, rot=(0, 0, 0.12), parent=root)
        for k in range(4):
            box((0.18, 0.02, 0.004), (0.08, 0.02 - k * 0.05, 0.03), mat('#9aa3b2', 0.6), bevel=0.0, rot=(0, 0, 0.12),
                parent=root)
        box((0.14, 0.14, 0.004), (-0.12, -0.04, 0.03), mat('#9fb3d1', 0.6), bevel=0.0, rot=(0, 0, 0.12), parent=root)
        root.rotation_euler = (math.radians(35), 0, 0)
    elif i == 5:  # cardboard box
        box_crate((0, 0, -0.18), 1.2, parent=root, rot=(0, 0, 0.5))
        root.rotation_euler = (math.radians(30), 0, 0)
    return root


def wheelie_bin(colkey, open_=0.0):
    root = empty((0, 0, -0.45))
    m = mat(colkey, 0.45, color=colkey)
    cyl(0.36, 0.78, (0, 0, 0.42), m, verts=4, bevel=0.06, r2=0.42, rot=(0, 0, math.pi / 4))
    o = bpy.context.active_object; o.parent = root
    for x in (-0.18, 0.18):
        box((0.035, 0.03, 0.6), (x, -0.31, 0.43), mat(colkey, 0.45, color=colkey), bevel=0.012, parent=root)
    for x in (-0.25, 0.25):
        cyl(0.07, 0.05, (x, 0.3, 0.07), mat('dark', 0.6), verts=20, bevel=0.012, rot=(0, math.pi / 2, 0), parent=root)
    hinge = empty((0, 0.32, 0.83), parent=root)
    hinge.rotation_euler = (-open_ * 1.75, 0, 0)
    box((0.66, 0.66, 0.07), (0, -0.33, 0.03), mat(colkey, 0.5, color=colkey), bevel=0.025, parent=hinge)
    box((0.3, 0.06, 0.04), (0, -0.62, 0.06), mat('dark', 0.5), bevel=0.012, parent=hinge)
    # white recycle badge on the front
    cyl(0.15, 0.02, (0, -0.335, 0.5), mat('white', 0.5), verts=32, bevel=0.005, rot=(math.radians(84), 0, 0),
        parent=root)
    ar = empty((0, -0.355, 0.5), parent=root)
    ar.rotation_euler = (math.radians(84), 0, 0)
    cycle_arrows(ar, 0.085, 0.016, colkey)
    return root


# ------------------------------------------------------------------ perk icons (turntable)
def perk(pid):
    root = empty((0, 0, 0))
    spin = None
    if pid == 'solar':
        cyl(0.03, 0.35, (0, 0, -0.25), mat('metal', 0.4, 0.6), verts=10, parent=root)
        box((0.8, 0.5, 0.04), (0, 0, -0.08), mat('#2f5fa8', 0.25, 0.3), bevel=0.02, rot=(math.radians(-50), 0, 0), parent=root)
        for k in range(3):
            box((0.005, 0.5, 0.045), (-0.2 + k * 0.2, 0, -0.08), mat('#a8c8ef', 0.3), bevel=0.0, rot=(math.radians(-50), 0, 0), parent=root)
        sphere(0.11, (0.3, 0.3, 0.3), mat('#ffc23a', 0.4, emit=1.2), parent=root)
    elif pid == 'repair':
        spin = gear_obj(0.24, 10, 0.08, mat('metal', 0.35, 0.7), root, (0, 0, 0), (math.pi / 2, 0, 0))
        box((0.1, 0.06, 0.65), (0.15, -0.12, 0), mat('red', 0.45), bevel=0.02, rot=(0, math.radians(35), 0), parent=root)
        torus(0.09, 0.035, (0.33, -0.12, 0.27), mat('metal', 0.35, 0.7), rot=(math.pi / 2, 0, 0), parent=root)
    elif pid == 'deposit':
        bottle((-0.15, 0, -0.38), '#a9dcf2', 'blue', 1.3, parent=root)
        coin((0.25, -0.1, -0.05), 0.2, parent=root, rot=(math.radians(80), 0, 0))
    elif pid == 'education':
        for k, c in enumerate(['#d9534a', '#4b86d3', '#5cae68']):
            box((0.62 - k * 0.06, 0.42, 0.12), (0, 0, -0.3 + k * 0.125), mat(c, 0.6, color=c), bevel=0.02,
                rot=(0, 0, 0.15 * (k - 1)), parent=root)
            box((0.6 - k * 0.06, 0.4, 0.1), (0.015, 0, -0.3 + k * 0.125), mat('#f6f1e6', 0.8), bevel=0.0,
                rot=(0, 0, 0.15 * (k - 1)), parent=root)
        box((0.5, 0.5, 0.04), (0, 0, 0.12), mat('dark', 0.6), bevel=0.01, rot=(0, 0, 0.6), parent=root)
        cyl(0.16, 0.12, (0, 0, 0.05), mat('dark', 0.6), verts=24, parent=root)
        cyl(0.012, 0.25, (0.18, 0.1, 0.0), mat('#f2c040', 0.4), verts=6, parent=root)
    elif pid == 'bond':
        box((0.55, 0.04, 0.72), (0, 0, 0), mat('#f6efd9', 0.7), bevel=0.01, parent=root)
        for k in range(4):
            box((0.36, 0.045, 0.025), (0, -0.002, 0.2 - k * 0.09), mat('#9aa3b2', 0.6), bevel=0.0, parent=root)
        cyl(0.1, 0.03, (0.14, -0.03, -0.22), mat('#d9534a', 0.4), verts=24, rot=(math.pi / 2, 0, 0), parent=root)
        cyl(0.045, 0.75, (0, 0, 0.38), mat('#e3d5bb', 0.6), verts=16, rot=(0, math.pi / 2, 0), parent=root)
        cyl(0.045, 0.75, (0, 0, -0.38), mat('#e3d5bb', 0.6), verts=16, rot=(0, math.pi / 2, 0), parent=root)
    elif pid == 'automation':
        root.location = (0, 0, -0.08)
        cyl(0.22, 0.1, (0, 0, -0.4), mat('dark', 0.5), verts=32, parent=root)
        cyl(0.12, 0.15, (0, 0, -0.28), mat('orange', 0.45), verts=24, parent=root)
        box((0.1, 0.1, 0.45), (0.08, 0, -0.03), mat('orange', 0.45), bevel=0.03, rot=(0, 0.35, 0), parent=root)
        sphere(0.08, (0.17, 0, 0.2), mat('dark', 0.5), parent=root)
        box((0.4, 0.09, 0.09), (0.0, 0, 0.3), mat('orange', 0.45), bevel=0.03, rot=(0, 0.5, 0), parent=root)
        box((0.06, 0.14, 0.14), (-0.18, 0, 0.42), mat('metal', 0.4, 0.6), bevel=0.01, parent=root)
    elif pid == 'ecolabel':
        cyl(0.36, 0.08, (0, 0, 0), mat('#5cae68', 0.45), verts=48, bevel=0.03, rot=(math.pi / 2, 0, 0), parent=root)
        torus(0.31, 0.025, (0, -0.045, 0), mat('white', 0.5), rot=(math.pi / 2, 0, 0), parent=root)
        sphere(0.17, (0, -0.05, 0.02), mat('white', 0.5), parent=root, scale=(0.6, 0.15, 1.0))
        cyl(0.012, 0.3, (0, -0.07, -0.05), mat('#5cae68', 0.5), verts=6, rot=(0, 0.3, 0), parent=root)
    elif pid == 'logistics':
        box((0.5, 0.3, 0.32), (-0.1, 0, 0.0), mat('#4b86d3', 0.5), bevel=0.03, parent=root)
        box((0.22, 0.3, 0.24), (0.27, 0, -0.04), mat('white', 0.45), bevel=0.04, parent=root)
        box((0.02, 0.24, 0.1), (0.38, 0, 0.02), mat('glass', 0.15, emit=0.2), bevel=0.01, parent=root)
        for x in (-0.22, 0.25):
            for y in (-0.15, 0.15):
                cyl(0.08, 0.06, (x, y, -0.19), mat('dark', 0.6), verts=20, bevel=0.015, rot=(math.pi / 2, 0, 0), parent=root)
    elif pid == 'cleantech':
        cyl(0.04, 0.85, (0, 0, -0.1), mat('white', 0.5), verts=16, r2=0.025, parent=root)
        box((0.08, 0.14, 0.08), (0, 0.02, 0.33), mat('white', 0.5), bevel=0.02, parent=root)
        spin = empty((0, -0.07, 0.33), parent=root)
        spin.rotation_euler = (0, 0, 0)
        for k in range(3):
            a = k * TAU / 3
            b = box((0.06, 0.02, 0.42), (0.21 * math.sin(a), 0, 0.21 * math.cos(a)), mat('white', 0.5), bevel=0.01,
                    rot=(0, a, 0), parent=spin)
        sphere(0.04, (0, -0.08, 0.33), mat('#5cae68', 0.4), parent=root)
    elif pid == 'tax':
        for k in range(5):
            coin((0.0 + random.uniform(-0.01, 0.01), 0, -0.35 + k * 0.09), 0.2, parent=root, euro=(k == 4))
        box((0.3, 0.02, 0.4), (-0.3, 0.1, -0.15), mat('#f6efd9', 0.7), bevel=0.01, rot=(0, 0, 0.3), parent=root)
        text_obj('%', (-0.3, 0.07, -0.12), 0.25, mat('#d9534a', 0.5), rot=(math.pi / 2, 0, 0.3), parent=root)
    elif pid == 'venture':
        cyl(0.13, 0.5, (0, 0, -0.05), mat('white', 0.4), verts=32, bevel=0.03, parent=root)
        cyl(0.13, 0.25, (0, 0, 0.32), mat('#d9534a', 0.4), verts=32, r2=0.0, bevel=0.0, parent=root)
        cyl(0.06, 0.03, (0, -0.12, 0.05), mat('glass', 0.15, emit=0.3), verts=24, rot=(math.pi / 2, 0, 0), parent=root)
        for k in range(3):
            a = k * TAU / 3
            box((0.03, 0.14, 0.18), (0.14 * math.cos(a), 0.14 * math.sin(a), -0.25), mat('#d9534a', 0.4), bevel=0.01,
                rot=(0, 0, a + math.pi / 2), parent=root)
        cyl(0.08, 0.2, (0, 0, -0.42), mat('#ffb21f', 0.4, emit=4.0), verts=16, r2=0.0, rot=(math.pi, 0, 0), parent=root)
        root.rotation_euler = (0, math.radians(-25), 0)
    elif pid == 'firebrigade':
        cyl(0.15, 0.6, (0, 0, -0.1), mat('#d9443a', 0.35), verts=32, bevel=0.05, parent=root)
        cyl(0.07, 0.08, (0, 0, 0.24), mat('dark', 0.5), verts=16, parent=root)
        box((0.25, 0.05, 0.04), (0.08, 0, 0.3), mat('dark', 0.5), bevel=0.01, rot=(0, -0.2, 0), parent=root)
        cyl(0.02, 0.3, (-0.15, 0, 0.1), mat('dark', 0.5), verts=8, rot=(0, 0.4, 0), parent=root)
        box((0.18, 0.005, 0.15), (0, -0.152, -0.05), mat('white', 0.6), bevel=0.0, parent=root)
    return root, spin


def gear_obj(R, teeth, th, m, parent, loc, rot):
    g = empty(loc, parent=parent)
    g.rotation_euler = rot
    cyl(R, th, (0, 0, 0), m, verts=40, bevel=0.01, parent=g)
    for k in range(teeth):
        a = k * TAU / teeth
        box((R * 0.32, R * 0.3, th), ((R * 1.12) * math.cos(a), (R * 1.12) * math.sin(a), 0), m, bevel=0.008,
            rot=(0, 0, a), parent=g)
    cyl(R * 0.35, th + 0.02, (0, 0, 0), mat('trim', 0.5), verts=20, bevel=0.005, parent=g)
    return g


PERK_IDS = ['solar', 'repair', 'deposit', 'education', 'bond', 'automation', 'ecolabel', 'logistics', 'cleantech',
            'tax', 'venture', 'firebrigade']


def main(what):
    os.makedirs(OUT, exist_ok=True)
    if what == 'tokens':
        setup(res=160, samples=32, cam_scale=1.05, cam_target=(0, 0, 0.14), elev=45, azim=30)
        for i in range(6):
            clear_scene(); token(i); shot(f'{OUT}/tok_{i}.png')
    elif what == 'hud':
        setup(res=160, samples=32, cam_scale=1.05, cam_target=(0, 0, 0), elev=90, azim=0)
        for i in range(3):
            clear_scene(); hud_icon(i); shot(f'{OUT}/hud_{i}.png')
    elif what == 'sort':
        setup(res=200, samples=32, cam_scale=1.0, cam_target=(0, 0, 0), elev=70, azim=20)
        bpy.data.objects['cam'].rotation_euler = Euler((math.radians(70), 0, math.radians(20)), 'XYZ')
        for i in range(6):
            clear_scene(); sort_item(i); shot(f'{OUT}/sort_{i}.png')
        bpy.data.objects['cam'].data.ortho_scale = 1.5
        bpy.data.objects['cam'].location.z += 0.2
        for i, c in enumerate(['y', 'g', 'b']):
            for op in (0, 1):
                clear_scene(); wheelie_bin(SORT_HEX[c], op); shot(f'{OUT}/bin_{i}_{op}.png')
    elif what == 'perks':
        setup(res=192, samples=28, cam_scale=1.25, cam_target=(0, 0, 0), elev=75, azim=0)
        for pid in (sys.argv[2:] or PERK_IDS):
            clear_scene()
            random.seed(1)
            root, spin = perk(pid)
            base_rot = tuple(root.rotation_euler)
            for f in range(16):
                t = f / 16
                if pid == 'cleantech':
                    spin.rotation_euler = (0, TAU / 3 * t, 0)
                    root.rotation_euler = (0, 0, math.radians(-25) + 0.25 * math.sin(TAU * t))
                elif pid == 'repair':
                    spin.rotation_euler = (math.pi / 2, TAU / 10 * t, 0)
                    root.rotation_euler = (0, 0, 0.25 * math.sin(TAU * t))
                else:
                    root.rotation_euler = (base_rot[0], base_rot[1], base_rot[2] + 0.45 * math.sin(TAU * t))
                    root.location = (0, 0, (-0.08 if pid == 'automation' else 0) + 0.03 * math.sin(TAU * t))
                shot(f'{OUT}/perk_{pid}_{f:02d}.png')


if __name__ == '__main__':
    main(sys.argv[1])
