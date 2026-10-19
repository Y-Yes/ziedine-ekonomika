import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from lib import *

FRAMES = 48


def node_mat(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    return m, nt, out


def ramp(nt, stops, interp='LINEAR'):
    r = nt.nodes.new('ShaderNodeValToRGB')
    cr = r.color_ramp
    cr.interpolation = interp
    while len(cr.elements) > 1:
        cr.elements.remove(cr.elements[-1])
    cr.elements[0].position = stops[0][0]
    cr.elements[0].color = lin(stops[0][1]) if isinstance(stops[0][1], str) else stops[0][1]
    for pos, c in stops[1:]:
        e = cr.elements.new(pos)
        e.color = lin(c) if isinstance(c, str) else c
    return r


def noise(nt, scale, detail=8, rough=0.55, coord=None, w=0.0):
    tc = coord or nt.nodes.new('ShaderNodeTexCoord')
    n = nt.nodes.new('ShaderNodeTexNoise')
    n.noise_dimensions = '4D'
    n.inputs['Scale'].default_value = scale
    n.inputs['Detail'].default_value = detail
    n.inputs['Roughness'].default_value = rough
    n.inputs['W'].default_value = w
    nt.links.new(tc.outputs['Object'], n.inputs['Vector'])
    return n, tc


def surface_mat(kind):
    m, nt, out = node_mat('surf_' + kind)
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(bsdf.outputs[0], out.inputs['Surface'])
    n, tc = noise(nt, 1.6, 10, 0.58)
    # latitude for ice caps
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    nt.links.new(tc.outputs['Object'], sep.inputs[0])
    absz = nt.nodes.new('ShaderNodeMath'); absz.operation = 'ABSOLUTE'
    nt.links.new(sep.outputs['Z'], absz.inputs[0])
    if kind == 'ok':
        stops = [(0.0, '#1f4f8f'), (0.44, '#2f74b8'), (0.5, '#5aa6d6'), (0.515, '#e8d9a2'), (0.53, '#7fbf5a'),
                 (0.6, '#4f9a45'), (0.68, '#3d7a3a'), (0.74, '#9a8a6a'), (0.8, '#f2f2ee')]
    elif kind == 'bad':
        stops = [(0.0, '#3c4a46'), (0.44, '#566360'), (0.5, '#74786a'), (0.515, '#a89a78'), (0.53, '#9c8a5c'),
                 (0.6, '#857348'), (0.68, '#6d5d3e'), (0.74, '#77695a'), (0.8, '#a39d92')]
    else:
        stops = [(0.0, '#3a1810'), (0.44, '#4a2014'), (0.5, '#55291a'), (0.515, '#3b2a22'), (0.53, '#2e2420'),
                 (0.6, '#261e1a'), (0.68, '#1f1916'), (0.74, '#2c2420'), (0.8, '#4a3f38')]
    r = ramp(nt, stops)
    nt.links.new(n.outputs['Fac'], r.inputs['Fac'])
    # ice caps (only on clean planet)
    mix = nt.nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'
    cap = nt.nodes.new('ShaderNodeMapRange')
    cap.inputs['From Min'].default_value = 0.82
    cap.inputs['From Max'].default_value = 0.9
    nt.links.new(absz.outputs[0], cap.inputs['Value'])
    nt.links.new(cap.outputs[0], mix.inputs['Factor'])
    nt.links.new(r.outputs['Color'], mix.inputs[6])
    mix.inputs[7].default_value = lin({'ok': '#f4f7fa', 'bad': '#9a958a', 'fire': '#3a302a'}[kind])
    nt.links.new(mix.outputs[2], bsdf.inputs['Base Color'])
    # water is glossier
    rr = ramp(nt, [(0.0, (0.25, 0.25, 0.25, 1)), (0.505, (0.25, 0.25, 0.25, 1)), (0.52, (0.85, 0.85, 0.85, 1))])
    nt.links.new(n.outputs['Fac'], rr.inputs['Fac'])
    nt.links.new(rr.outputs['Color'], bsdf.inputs['Roughness'])
    # bump on land
    bump = nt.nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = 0.25
    nt.links.new(n.outputs['Fac'], bump.inputs['Height'])
    nt.links.new(bump.outputs[0], bsdf.inputs['Normal'])
    if kind == 'fire':
        # glowing lava veins
        n2, _ = noise(nt, 4.0, 6, 0.6, coord=tc, w=3.0)
        vr = ramp(nt, [(0.0, (0, 0, 0, 1)), (0.485, (0, 0, 0, 1)), (0.5, (1, 1, 1, 1)), (0.515, (0, 0, 0, 1))])
        nt.links.new(n2.outputs['Fac'], vr.inputs['Fac'])
        # more lava in the 'ocean'
        land = ramp(nt, [(0.0, (1, 1, 1, 1)), (0.5, (0.6, 0.6, 0.6, 1)), (0.52, (0.25, 0.25, 0.25, 1))])
        nt.links.new(n.outputs['Fac'], land.inputs['Fac'])
        add = nt.nodes.new('ShaderNodeMath'); add.operation = 'MAXIMUM'
        nt.links.new(vr.outputs['Color'], add.inputs[0])
        sea = nt.nodes.new('ShaderNodeMath'); sea.operation = 'MULTIPLY'
        nt.links.new(land.outputs['Color'], sea.inputs[0]); sea.inputs[1].default_value = 0.05
        nt.links.new(sea.outputs[0], add.inputs[1])
        bsdf.inputs['Emission Color'].default_value = lin('#ff6a1f')
        em = nt.nodes.new('ShaderNodeMath'); em.operation = 'MULTIPLY'
        nt.links.new(add.outputs[0], em.inputs[0]); em.inputs[1].default_value = 5.0
        nt.links.new(em.outputs[0], bsdf.inputs['Emission Strength'])
    return m


def cloud_mat(kind):
    m, nt, out = node_mat('cloud_' + kind)
    n, tc = noise(nt, 2.6, 8, 0.6, w=7.0)
    thr = {'ok': (0.56, 0.68), 'bad': (0.47, 0.62), 'fire': (0.5, 0.64)}[kind]
    r = ramp(nt, [(0.0, (0, 0, 0, 1)), (thr[0], (0, 0, 0, 1)), (thr[1], (1, 1, 1, 1))])
    nt.links.new(n.outputs['Fac'], r.inputs['Fac'])
    col = {'ok': '#ffffff', 'bad': '#7c7566', 'fire': '#3b302c'}[kind]
    diff = nt.nodes.new('ShaderNodeBsdfPrincipled')
    diff.inputs['Base Color'].default_value = lin(col)
    diff.inputs['Roughness'].default_value = 1.0
    tr = nt.nodes.new('ShaderNodeBsdfTransparent')
    mx = nt.nodes.new('ShaderNodeMixShader')
    op = nt.nodes.new('ShaderNodeMath'); op.operation = 'MULTIPLY'
    nt.links.new(r.outputs['Color'], op.inputs[0])
    op.inputs[1].default_value = {'ok': 0.92, 'bad': 0.95, 'fire': 0.9}[kind]
    nt.links.new(op.outputs[0], mx.inputs[0])
    nt.links.new(tr.outputs[0], mx.inputs[1])
    nt.links.new(diff.outputs[0], mx.inputs[2])
    nt.links.new(mx.outputs[0], out.inputs['Surface'])
    m.blend_method = 'BLEND' if hasattr(m, 'blend_method') else None
    return m


def atmo_mat(kind):
    m, nt, out = node_mat('atmo_' + kind)
    lw = nt.nodes.new('ShaderNodeLayerWeight')
    lw.inputs['Blend'].default_value = 0.35
    pw = nt.nodes.new('ShaderNodeMath'); pw.operation = 'POWER'
    nt.links.new(lw.outputs['Facing'], pw.inputs[0]); pw.inputs[1].default_value = 2.2
    em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Color'].default_value = lin({'ok': '#7fc4ff', 'bad': '#b0a07a', 'fire': '#ff7a2a'}[kind])
    em.inputs['Strength'].default_value = 1.6
    tr = nt.nodes.new('ShaderNodeBsdfTransparent')
    mx = nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(pw.outputs[0], mx.inputs[0])
    nt.links.new(tr.outputs[0], mx.inputs[1])
    nt.links.new(em.outputs[0], mx.inputs[2])
    nt.links.new(mx.outputs[0], out.inputs['Surface'])
    return m


def build():
    setup(res=360, samples=20, cam_scale=2.5, cam_target=(0, 0, 0), elev=90, azim=0)
    sc = bpy.context.scene
    sc.camera.location = (0, 0, 20)
    sc.camera.rotation_euler = (0, 0, 0)
    sun = bpy.data.objects['sun']
    sun.rotation_euler = Vector((-0.55, 0.5, 0.65)).to_track_quat('Z', 'Y').to_euler()
    bpy.data.lights['sun'].energy = 5.0
    sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.22
    tilt = empty((0, 0, 0))
    tilt.rotation_euler = (math.radians(-70), math.radians(18), 0)   # axis tilted toward the viewer
    spin = empty((0, 0, 0), parent=tilt)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=96, ring_count=48)
    planet = bpy.context.active_object
    for p in planet.data.polygons:
        p.use_smooth = True
    planet.parent = spin
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.012, segments=96, ring_count=48)
    clouds = bpy.context.active_object
    for p in clouds.data.polygons:
        p.use_smooth = True
    cspin = empty((0, 0, 0), parent=tilt)
    clouds.parent = cspin
    return spin, cspin, planet, clouds, None


if __name__ == '__main__':
    kind = sys.argv[1]
    mode = sys.argv[2]
    spin, cspin, planet, clouds, atmo = build()
    planet.data.materials.append(surface_mat(kind))
    clouds.data.materials.append(cloud_mat(kind))

    def update(t):
        spin.rotation_euler = (0, 0, TAU * t)
        cspin.rotation_euler = (0, 0, TAU * t * 2 + 0.5)

    if mode == 'preview':
        update(0.15)
        bpy.context.scene.render.filepath = f'/home/claude/gen/b3d/prev_planet_{kind}.png'
        bpy.ops.render.render(write_still=True)
    else:
        render_frames(update, FRAMES, '/home/claude/gen/b3d/frames', f'planet_{kind}')
