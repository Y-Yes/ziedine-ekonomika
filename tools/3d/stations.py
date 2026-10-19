import sys, os, math, random
sys.path.insert(0, os.path.dirname(__file__))
from lib import *


# ---------------------------------------------------------------- 1 household
def st_naudotojas():
    island(1.0, seed=3)
    decor(3, avoid=AVOID.get(3, ()))
    # stone path
    for k, (x, y) in enumerate([(0.15, -0.55), (0.32, -0.7), (0.05, -0.38)]):
        cyl(0.07, 0.02, (x, y, 0.01), mat('path', 0.9), verts=10, bevel=0.005)
    # house
    box((0.62, 0.5, 0.42), (-0.05, 0.12, 0.21), mat('wall', 0.7))
    prism_roof(0.62, 0.5, 0.3, (-0.05, 0.12, 0.42), mat('roof_red', 0.6))
    box((0.09, 0.09, 0.26), (0.13, 0.2, 0.62), mat('#b9573f', 0.8), bevel=0.01)  # chimney
    box((0.11, 0.11, 0.03), (0.13, 0.2, 0.76), mat('trim', 0.7), bevel=0.008)
    # door + windows (front face y = -0.13)
    box((0.12, 0.02, 0.22), (-0.05, -0.135, 0.11), mat('wood', 0.6), bevel=0.008)
    cyl(0.012, 0.01, (-0.01, -0.148, 0.11), mat('yellow', 0.3, 0.6), verts=8, rot=(math.pi / 2, 0, 0))
    for x in (-0.24, 0.14):
        box((0.12, 0.02, 0.11), (x, -0.135, 0.25), mat('#ffd98a', 0.3, emit=1.2), bevel=0.005)
        box((0.15, 0.03, 0.02), (x, -0.14, 0.185), mat('wall2', 0.7), bevel=0.005)
    # side window (x face)
    box((0.02, 0.12, 0.11), (0.265, 0.12, 0.25), mat('#ffd98a', 0.3, emit=1.2), bevel=0.005)
    # fence
    for k in range(5):
        box((0.025, 0.025, 0.12), (-0.62 + k * 0.1, -0.35, 0.06), mat('wood', 0.8), bevel=0.006)
    box((0.42, 0.018, 0.025), (-0.42, -0.35, 0.09), mat('wood', 0.8), bevel=0.005)
    # trees & bushes
    t1 = tree((-0.55, 0.35, 0), 1.25, kind=0)
    t2 = tree((0.55, 0.45, 0), 1.0, kind=1)
    bush((-0.45, -0.15, 0.04), 1.0)
    bush((0.38, -0.25, 0.04), 0.9)
    # three sorting bins in front of the house
    bins = []
    for k, c in enumerate(['bin_y', 'bin_g', 'bin_b']):
        bins.append(bin3((0.42 + k * 0.0, -0.05 + k * 0.17 - 0.17, 0), c, 1.0, rot_z=math.radians(90)))
    lid_hinges = [b.children[1] for b in bins]
    # smoke puffs
    puffs = [sphere(0.05, (0, 0, 0), mat('white', 0.9), ico=True) for _ in range(3)]

    def update(t):
        for k, p in enumerate(puffs):
            u = (t + k / 3) % 1.0
            p.location = (0.13 + 0.12 * u, 0.2 + 0.05 * u, 0.8 + 0.38 * u)
            s = 0.6 + 1.2 * u
            p.scale = (s, s, s) if u < 0.85 else (s * (1 - u) / 0.15,) * 3
        t1.rotation_euler = (0.04 * math.sin(TAU * t), 0.03 * math.cos(TAU * t), 0)
        t2.rotation_euler = (0.03 * math.sin(TAU * t + 1), 0.04 * math.cos(TAU * t + 1), 0)
        # middle bin lid opens and closes
        for k, h in enumerate(lid_hinges):
            ph = (t - k * 0.25) % 1.0
            a = math.sin(math.pi * min(1.0, ph / 0.35)) if ph < 0.35 else 0.0
            h.rotation_euler = (-1.1 * a, 0, 0)
    return update


AVOID = {3: [(-0.62, -0.35, 0.12), (0.42, -0.05, 0.25), (0.15, -0.6, 0.2)], 7: [(0, -0.18, 0.3), (0.6, -0.18, 0.3), (-0.6, -0.18, 0.3)], 11: [(0.5, -0.47, 0.3), (-0.6, -0.2, 0.2)], 5: [(-0.35, -0.35, 0.2), (0.15, -0.55, 0.15)], 9: [(0.48, -0.3, 0.2)], 13: [(0.32, -0.42, 0.15), (-0.4, -0.38, 0.15), (0.55, -0.3, 0.1)]}

STATIONS = {'1_naudotojas': st_naudotojas}

# ---------------------------------------------------------------- 2 collection
def wheel(loc, r=0.075, parent=None):
    w = cyl(r, 0.06, loc, mat('dark', 0.7), verts=24, bevel=0.015, rot=(math.pi / 2, 0, 0), parent=parent)
    cyl(r * 0.5, 0.065, loc, mat('metal', 0.4, 0.5), verts=16, bevel=0.005, rot=(math.pi / 2, 0, 0), parent=parent)
    return w


def st_surinkimas():
    island(1.0, seed=7)
    decor(7, avoid=AVOID.get(7, ()))
    # road
    box((1.5, 0.42, 0.02), (0.0, -0.18, 0.005), mat('#6c7078', 0.85), bevel=0.01)
    for k in range(4):
        box((0.14, 0.03, 0.022), (-0.55 + k * 0.36, -0.18, 0.008), mat('white', 0.8), bevel=0.003)
    # depot shed behind
    box((0.75, 0.38, 0.36), (-0.1, 0.42, 0.18), mat('wall2', 0.75))
    box((0.8, 0.43, 0.05), (-0.1, 0.42, 0.385), mat('trim', 0.6), bevel=0.012)
    box((0.3, 0.02, 0.25), (-0.12, 0.225, 0.125), mat('#8d97a3', 0.5, 0.3), bevel=0.006)
    for k in range(5):
        box((0.3, 0.025, 0.008), (-0.12, 0.215, 0.03 + k * 0.05), mat('#6f7884', 0.5, 0.3), bevel=0.002)
    box((0.06, 0.02, 0.06), (0.2, 0.225, 0.28), mat('orange', 0.5, emit=0.6), bevel=0.004)
    tree((0.62, 0.35, 0), 1.1, kind=1)
    tree((-0.66, 0.1, 0), 0.9, kind=0)
    bush((0.55, 0.62, 0.04), 1.0)
    # truck (front towards +x)
    truck = empty((0.05, -0.18, 0.0))
    body = empty((0, 0, 0), parent=truck)
    box((0.78, 0.26, 0.05), (0.0, 0, 0.1), mat('dark', 0.6), bevel=0.01, parent=body)
    box((0.48, 0.28, 0.27), (-0.12, 0, 0.27), mat('orange', 0.5), bevel=0.03, parent=body)
    box((0.485, 0.285, 0.04), (-0.12, 0, 0.2), mat('white', 0.6), bevel=0.01, parent=body)
    box((0.2, 0.27, 0.23), (0.25, 0, 0.245), mat('white', 0.45), bevel=0.035, parent=body)
    box((0.02, 0.22, 0.1), (0.35, 0, 0.29), mat('glass', 0.15, emit=0.15), bevel=0.01, parent=body)
    box((0.12, 0.02, 0.09), (0.27, -0.136, 0.29), mat('glass', 0.15, emit=0.15), bevel=0.006, parent=body)
    box((0.03, 0.2, 0.05), (0.36, 0, 0.15), mat('trim', 0.5), bevel=0.01, parent=body)
    for y in (-0.08, 0.08):
        box((0.01, 0.04, 0.025), (0.365, y, 0.19), mat('#fff3c4', 0.3, emit=2.0), bevel=0.004, parent=body)
    beacon = cyl(0.028, 0.035, (0.25, 0, 0.375), mat('#ffb21f', 0.3, emit=0.0), verts=16, bevel=0.008, parent=body)
    bmat = beacon.data.materials[0].copy(); beacon.data.materials[0] = bmat
    for x in (-0.25, 0.22):
        wheel((x, -0.13, 0.075), parent=truck)
        wheel((x, 0.13, 0.075), parent=truck)
    # rear lifter arm with a bin
    arm = empty((-0.38, 0, 0.16), parent=truck)
    box((0.03, 0.2, 0.03), (-0.02, 0, 0), mat('metal', 0.4, 0.6), bevel=0.005, parent=arm)
    lbin = bin3((-0.1, 0, -0.12), 'bin_g', 1.0, rot_z=math.radians(90))
    lbin.parent = arm

    def update(t):
        bob = 0.006 * math.sin(TAU * t * 6)
        body.location = (0, 0, bob)
        ph = t
        a = math.sin(math.pi * ph) ** 2
        arm.rotation_euler = (0, -2.1 * a, 0)
        lbin.location = (-0.1 + 0.02 * a, 0, -0.12 + 0.02 * a)
        on = (int(t * 24) // 3) % 2 == 0
        n = bmat.node_tree.nodes['Principled BSDF']
        n.inputs['Emission Color'].default_value = lin('#ffb21f')
        n.inputs['Emission Strength'].default_value = 6.0 if on else 0.3
    return update


# ---------------------------------------------------------------- 3 sorting
def st_rusiavimas():
    island(1.0, seed=11)
    decor(11, avoid=AVOID.get(11, ()))
    # sorting hall
    box((0.6, 0.48, 0.4), (-0.2, 0.25, 0.2), mat('wall', 0.7))
    box((0.66, 0.54, 0.06), (-0.2, 0.25, 0.43), mat('yellow', 0.55), bevel=0.015)
    box((0.66, 0.08, 0.06), (-0.2, 0.0, 0.47), mat('#c9a63a', 0.55), bevel=0.012)
    box((0.3, 0.02, 0.22), (-0.06, 0.005, 0.11), mat('dark', 0.7), bevel=0.006)  # opening
    box((0.1, 0.02, 0.08), (-0.36, 0.005, 0.28), mat('glass', 0.2, emit=0.2), bevel=0.005)
    # conveyor coming out towards -y then along +x
    L = 0.95
    belt = box((L, 0.16, 0.035), (0.18, -0.2, 0.15), mat('#3a3f48', 0.5), bevel=0.01)
    box((L + 0.02, 0.19, 0.02), (0.18, -0.2, 0.125), mat('metal', 0.4, 0.5), bevel=0.005)
    for k in range(5):
        x = -0.25 + k * 0.22
        for y in (-0.27, -0.13):
            box((0.025, 0.025, 0.12), (x, y, 0.06), mat('metal', 0.4, 0.5), bevel=0.004)
    # bins at the end
    for k, c in enumerate(['bin_y', 'bin_g', 'bin_b']):
        bin3((0.33 + k * 0.17, -0.47, 0), c, 1.15, lid_open=0.9)
    # pile of mixed waste bags
    for k, (x, y, s) in enumerate([(-0.55, -0.15, 1), (-0.62, -0.02, 0.8), (-0.5, -0.32, 0.75), (-0.66, -0.25, 0.7)]):
        sphere(0.08 * s, (x, y, 0.06 * s), mat('#4a4f5a', 0.4), ico=True)
    tree((0.55, 0.45, 0), 1.0, kind=0)
    bush((0.25, 0.55, 0.04), 1.1)
    # items on belt
    cols = ['bin_y', 'bin_b', 'bin_g', 'bin_y', 'bin_b', 'bin_g']
    items = []
    for k, c in enumerate(cols):
        if k % 3 == 0:
            o = cyl(0.03, 0.08, (0, 0, 0), mat(c, 0.35), verts=12, bevel=0.01, rot=(0, math.pi / 2, 0))
        elif k % 3 == 1:
            o = box((0.07, 0.06, 0.05), (0, 0, 0), mat('#c9965a' if c == 'bin_b' else c, 0.7), bevel=0.008)
        else:
            o = cyl(0.03, 0.08, (0, 0, 0), mat(c, 0.15), verts=12, bevel=0.01)
        items.append(o)

    def update(t):
        n = len(items)
        for k, o in enumerate(items):
            u = (t + k / n) % 1.0
            x = -0.27 + u * L
            z = 0.2
            s = min(1.0, u / 0.06, (1 - u) / 0.06)
            o.location = (x, -0.2, z - (1 - s) * 0.03)
            o.scale = (max(s, 0.01),) * 3
    return update


# ---------------------------------------------------------------- 4 recycling
def st_perdirbimas():
    island(1.0, seed=5)
    decor(5, avoid=AVOID.get(5, ()))
    # plant building
    box((0.55, 0.42, 0.34), (-0.25, 0.28, 0.17), mat('wall', 0.7))
    box((0.6, 0.47, 0.05), (-0.25, 0.28, 0.36), mat('trim', 0.6), bevel=0.012)
    box((0.555, 0.425, 0.06), (-0.25, 0.28, 0.07), mat('green', 0.55), bevel=0.004)
    for x in (-0.4, -0.1):
        box((0.1, 0.02, 0.09), (x, 0.065, 0.24), mat('glass', 0.2, emit=0.3), bevel=0.005)
    # silos
    for k, (x, y) in enumerate([(0.35, 0.35), (0.1, 0.55)]):
        cyl(0.13, 0.55, (x, y, 0.275), mat('green', 0.45), verts=32, bevel=0.01)
        sphere(0.13, (x, y, 0.55), mat('green', 0.45), scale=(1, 1, 0.5))
        for z in (0.12, 0.3, 0.46):
            cyl(0.133, 0.02, (x, y, z), mat('#3f8a4c', 0.5), verts=32, bevel=0.003)
    # rotating drum (shredder)
    cyl(0.03, 0.2, (0.15, -0.08, 0.1), mat('metal', 0.4, 0.5), verts=8, bevel=0.005)
    cyl(0.03, 0.2, (0.15, -0.52, 0.1), mat('metal', 0.4, 0.5), verts=8, bevel=0.005)
    drum = empty((0.15, -0.3, 0.22))
    cyl(0.15, 0.4, (0, 0, 0), mat('metal', 0.35, 0.6), verts=40, bevel=0.015, rot=(math.pi / 2, 0, 0), parent=drum)
    for k in range(4):
        a = k * TAU / 4
        box((0.04, 0.42, 0.035), (0.15 * math.cos(a), 0, 0.15 * math.sin(a)), mat('green', 0.5), bevel=0.008,
            rot=(0, -a, 0), parent=drum)
    cyl(0.155, 0.03, (0, -0.2, 0), mat('green', 0.5), verts=40, bevel=0.005, rot=(math.pi / 2, 0, 0), parent=drum)
    cyl(0.155, 0.03, (0, 0.2, 0), mat('green', 0.5), verts=40, bevel=0.005, rot=(math.pi / 2, 0, 0), parent=drum)
    # pellet pile
    random.seed(4)
    for k in range(26):
        a = random.uniform(0, TAU); r = random.uniform(0, 0.13) ** 0.8
        h = 0.11 * (1 - r / 0.2)
        sphere(0.028, (-0.35 + r * math.cos(a), -0.35 + r * math.sin(a), max(0.02, h * random.uniform(0.4, 1.0))),
               mat(random.choice(['bin_g', 'white', 'bin_b']), 0.4), ico=True)
    tree((0.6, -0.05, 0), 0.9, kind=1)
    bush((-0.62, 0.0, 0.04), 1.0)
    falling = [sphere(0.025, (0, 0, 0), mat('bin_g', 0.4), ico=True) for _ in range(3)]

    def update(t):
        drum.rotation_euler = (0, TAU / 4 * t, 0)
        for k, p in enumerate(falling):
            u = (t + k / 3) % 1.0
            p.location = (0.15 - 0.5 * u, -0.3 - 0.05 * u, 0.12 + 0.12 * math.sin(math.pi * u) - 0.1 * u)
    return update


# ---------------------------------------------------------------- 5 factory
def gear(R, teeth, th, m, parent=None, loc=(0, 0, 0), rot=(0, 0, 0)):
    g = empty(loc, parent=parent)
    g.rotation_euler = rot
    cyl(R, th, (0, 0, 0), m, verts=40, bevel=0.008, parent=g)
    for k in range(teeth):
        a = k * TAU / teeth
        box((R * 0.32, R * 0.3, th), ((R + R * 0.12) * math.cos(a), (R + R * 0.12) * math.sin(a), 0), m,
            bevel=0.006, rot=(0, 0, a), parent=g)
    cyl(R * 0.35, th + 0.02, (0, 0, 0), mat('trim', 0.5), verts=20, bevel=0.005, parent=g)
    return g


def st_gamykla():
    island(1.0, seed=9)
    decor(9, avoid=AVOID.get(9, ()))
    # factory hall
    box((0.8, 0.5, 0.32), (-0.08, 0.2, 0.16), mat('#dfe6ee', 0.7))
    box((0.805, 0.505, 0.07), (-0.08, 0.2, 0.05), mat('blue', 0.55), bevel=0.004)
    # sawtooth roof: 3 teeth along x
    for k in range(3):
        x = -0.08 - 0.4 + 0.1333 + k * 0.2667
        prism = prism_roof(0.5, 0.2667, 0.14, (x, 0.2, 0.32), mat('blue', 0.5), overhang=0.0, rot_z=math.pi / 2)
        box((0.02, 0.5, 0.1), (x + 0.12, 0.2, 0.38), mat('glass', 0.2, emit=0.4), bevel=0.004)
    # windows on front
    for k in range(3):
        box((0.14, 0.02, 0.09), (-0.35 + k * 0.27, -0.055, 0.2), mat('#ffd98a', 0.3, emit=0.9), bevel=0.005)
    # chimney
    cyl(0.07, 0.62, (-0.42, 0.42, 0.31), mat('#b45a40', 0.8), verts=20, bevel=0.01, r2=0.055)
    for z in (0.5, 0.57):
        cyl(0.062, 0.025, (-0.42, 0.42, z), mat('white', 0.6), verts=20, bevel=0.004)
    # gear on side wall (x face)
    g = gear(0.13, 10, 0.04, mat('metal', 0.35, 0.6), loc=(0.34, 0.15, 0.2), rot=(0, math.pi / 2, 0))
    g2 = gear(0.07, 8, 0.04, mat('yellow', 0.45), loc=(0.35, -0.05, 0.3), rot=(0, math.pi / 2, 0))
    # crates & pallet
    for k, (x, y, z) in enumerate([(0.42, -0.35, 0.05), (0.54, -0.25, 0.05), (0.48, -0.3, 0.15)]):
        box((0.1, 0.1, 0.1), (x, y, z), mat('#c9965a', 0.7), bevel=0.01)
    box((0.3, 0.22, 0.03), (0.48, -0.3, 0.015), mat('wood', 0.8), bevel=0.005)
    tree((-0.62, -0.2, 0), 1.0, kind=0)
    bush((0.1, -0.5, 0.04), 1.0)
    puffs = [sphere(0.06, (0, 0, 0), mat('white', 0.9), ico=True) for _ in range(4)]
    g_inner = g.children
    g2.rotation_mode = 'XYZ'

    def update(t):
        # gear rotation in the wall plane (local Z after Y rotation)
        g.rotation_euler = (TAU / 10 * t, math.pi / 2, 0)
        g2.rotation_euler = (-TAU / 8 * t * (10 / 8) * 0.8 + 0.3, math.pi / 2, 0)
        for k, p in enumerate(puffs):
            u = (t + k / 4) % 1.0
            p.location = (-0.42 + 0.18 * u, 0.42 + 0.08 * u, 0.66 + 0.42 * u)
            s = 0.6 + 1.3 * u
            p.scale = (s, s, s) if u < 0.85 else (s * (1 - u) / 0.15,) * 3
    return update


# ---------------------------------------------------------------- 6 shop
def st_parduotuve():
    island(1.0, seed=13)
    decor(13, avoid=AVOID.get(13, ()))
    box((0.7, 0.45, 0.4), (-0.05, 0.2, 0.2), mat('wall', 0.7))
    box((0.74, 0.49, 0.05), (-0.05, 0.2, 0.425), mat('trim', 0.6), bevel=0.012)
    # sign board
    box((0.46, 0.04, 0.12), (-0.05, -0.02, 0.5), mat('purple', 0.5), bevel=0.015)
    box((0.36, 0.045, 0.03), (-0.05, -0.025, 0.5), mat('white', 0.5, emit=0.6), bevel=0.006)
    # big windows + door
    box((0.2, 0.02, 0.17), (-0.26, -0.025, 0.14), mat('#ffe2a8', 0.2, emit=0.9), bevel=0.005)
    box((0.2, 0.02, 0.17), (0.17, -0.025, 0.14), mat('#ffe2a8', 0.2, emit=0.9), bevel=0.005)
    box((0.12, 0.022, 0.22), (-0.045, -0.025, 0.11), mat('glass', 0.15, emit=0.3), bevel=0.005)
    # striped awning
    for k in range(8):
        x = -0.05 - 0.35 + 0.0437 + k * 0.0875
        box((0.0875, 0.16, 0.02), (x, -0.09, 0.3), mat('purple' if k % 2 == 0 else 'white', 0.6), bevel=0.004,
            rot=(math.radians(-25), 0, 0))
    # side awning on x face
    for k in range(5):
        y = 0.2 - 0.225 + 0.045 + k * 0.09
        box((0.12, 0.09, 0.02), (0.35, y, 0.3), mat('purple' if k % 2 == 0 else 'white', 0.6), bevel=0.004,
            rot=(0, math.radians(25), 0))
    # pole with spinning coin
    cyl(0.015, 0.55, (0.55, -0.3, 0.275), mat('trim', 0.5), verts=10, bevel=0.003)
    coin = empty((0.55, -0.3, 0.62))
    cyl(0.12, 0.035, (0, 0, 0), mat('#f2c040', 0.3, 0.7), verts=40, bevel=0.012, rot=(math.pi / 2, 0, 0), parent=coin)
    cyl(0.085, 0.04, (0, 0, 0), mat('#e0a82a', 0.35, 0.7), verts=40, bevel=0.006, rot=(math.pi / 2, 0, 0), parent=coin)
    # shopping cart
    cart = empty((0.32, -0.42, 0.0))
    cart.rotation_euler = (0, 0, math.radians(20))
    box((0.16, 0.11, 0.09), (0, 0, 0.1), mat('metal', 0.35, 0.6), bevel=0.008, parent=cart)
    box((0.14, 0.09, 0.02), (0, 0, 0.145), mat('dark', 0.5), bevel=0.004, parent=cart)
    box((0.015, 0.11, 0.015), (-0.1, 0, 0.17), mat('red', 0.5), bevel=0.004, parent=cart)
    for x in (-0.06, 0.06):
        for y in (-0.045, 0.045):
            cyl(0.015, 0.01, (x, y, 0.015), mat('dark', 0.5), verts=10, bevel=0.002, rot=(math.pi / 2, 0, 0), parent=cart)
    box((0.06, 0.05, 0.05), (0.02, 0.0, 0.17), mat('bin_g', 0.5), bevel=0.006, parent=cart)
    # plants & bench
    for x in (-0.48, 0.32):
        cyl(0.04, 0.06, (x, -0.1, 0.03), mat('#c9965a', 0.7), verts=12, bevel=0.005, r2=0.03)
        sphere(0.05, (x, -0.1, 0.1), mat('leaf2', 0.8), ico=True)
    box((0.2, 0.06, 0.02), (-0.4, -0.38, 0.07), mat('wood', 0.7), bevel=0.005)
    for x in (-0.48, -0.32):
        box((0.02, 0.05, 0.06), (x, -0.38, 0.03), mat('trim', 0.6), bevel=0.003)
    tree((-0.62, 0.35, 0), 1.1, kind=1)
    tree((0.5, 0.45, 0), 0.9, kind=0)

    def update(t):
        coin.rotation_euler = (0, 0, math.pi * t + 0.4)
    return update


STATIONS.update({'2_surinkimas': st_surinkimas, '3_rusiavimas': st_rusiavimas, '4_perdirbimas': st_perdirbimas,
                 '5_gamykla': st_gamykla, '6_parduotuve': st_parduotuve})


# ---------------------------------------------------------------- landfill base (static)
def st_savartynas():
    island(1.0, seed=21, grass='#9c8a6c')
    random.seed(5)
    # patchy dirty ground
    for k in range(10):
        a = random.uniform(0, TAU); r = random.uniform(0.3, 0.8)
        sphere(random.uniform(0.03, 0.05), (r * math.cos(a), r * math.sin(a), 0.0), mat('#8a7a60', 0.9), ico=True,
               scale=(1.3, 1, 0.5), smooth=False)
    # fence along the back
    for k in range(9):
        a = math.radians(20 + k * 17)
        x, y = 0.86 * math.cos(a), 0.86 * math.sin(a)
        box((0.03, 0.03, 0.2), (x, y, 0.1), mat('wood', 0.8), bevel=0.006)
    # tyres
    torus(0.07, 0.03, (-0.62, -0.2, 0.03), mat('dark', 0.7))
    torus(0.07, 0.03, (-0.6, -0.22, 0.09), mat('dark', 0.7), rot=(0.2, 0.1, 0))
    # rusty barrels
    cyl(0.07, 0.18, (0.62, -0.25, 0.09), mat('#a5583a', 0.7, 0.3), verts=20, bevel=0.01)
    cyl(0.07, 0.18, (0.5, -0.4, 0.07), mat('#7b8a3a', 0.7, 0.3), verts=20, bevel=0.01, rot=(1.3, 0, 0.5))
    # warning sign
    cyl(0.012, 0.3, (-0.5, -0.55, 0.15), mat('metal', 0.5, 0.5), verts=8)
    box((0.16, 0.02, 0.12), (-0.5, -0.56, 0.3), mat('yellow', 0.5), bevel=0.01)
    box((0.03, 0.025, 0.06), (-0.5, -0.57, 0.31), mat('dark', 0.5), bevel=0.004)

    def update(t):
        pass
    return update


STATIONS['savartynas'] = st_savartynas


if __name__ == '__main__':
    name = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else sys.argv[1]
    mode = sys.argv[-1]
    setup(res=320, samples=40, cam_scale=2.5, cam_target=(0, 0, 0.22))
    upd = STATIONS[name]()
    out = '/home/claude/gen/b3d/frames'
    if mode == 'preview':
        upd(0.1)
        bpy.context.scene.render.filepath = f'/home/claude/gen/b3d/prev_{name}.png'
        bpy.ops.render.render(write_still=True)
    else:
        render_frames(upd, 24, out, name)
