"""Real-Earth planet (three.js Earth maps) rendered in Blender: clean / polluted / burning."""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from lib import *

FRAMES = 48
TEX = '/home/claude/gen/b3d/tex/'


def img_node(nt, path, non_color=False):
    n = nt.nodes.new('ShaderNodeTexImage')
    n.image = bpy.data.images.load(path)
    if non_color:
        n.image.colorspace_settings.name = 'Non-Color'
    n.interpolation = 'Cubic'
    return n


def new_mat(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    return m, nt, nt.nodes.new('ShaderNodeOutputMaterial')


def surface(kind):
    m, nt, out = new_mat('earth_' + kind)
    b = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(b.outputs[0], out.inputs['Surface'])
    c = img_node(nt, TEX + {'ok': 'ok_col.png', 'bad': 'bad_col.png', 'fire': 'fire_col.png'}[kind])
    nt.links.new(c.outputs['Color'], b.inputs['Base Color'])
    w = img_node(nt, TEX + 'water.png', True)
    # water is glossy, land matte
    mr = nt.nodes.new('ShaderNodeMapRange')
    mr.inputs['To Min'].default_value = 0.85
    mr.inputs['To Max'].default_value = {'ok': 0.32, 'bad': 0.55, 'fire': 0.6}[kind]
    nt.links.new(w.outputs['Color'], mr.inputs['Value'])
    nt.links.new(mr.outputs[0], b.inputs['Roughness'])
    b.inputs['Specular IOR Level'].default_value = 0.2
    nb = img_node(nt, '/tmp/claude-0/tex/earth_normal_2048.jpg', True)
    nm = nt.nodes.new('ShaderNodeNormalMap')
    nm.inputs['Strength'].default_value = 0.6
    nt.links.new(nb.outputs['Color'], nm.inputs['Color'])
    nt.links.new(nm.outputs[0], b.inputs['Normal'])
    if kind == 'fire':
        e = img_node(nt, TEX + 'fire_em.png')
        nt.links.new(e.outputs['Color'], b.inputs['Emission Color'])
        b.inputs['Emission Strength'].default_value = 6.0
    return m


def clouds(kind):
    m, nt, out = new_mat('clouds_' + kind)
    a = img_node(nt, TEX + 'clouds.png', True)
    d = nt.nodes.new('ShaderNodeBsdfPrincipled')
    d.inputs['Base Color'].default_value = lin({'ok': '#ffffff', 'bad': '#8d8270', 'fire': '#3a2c26'}[kind])
    d.inputs['Roughness'].default_value = 1.0
    t = nt.nodes.new('ShaderNodeBsdfTransparent')
    mx = nt.nodes.new('ShaderNodeMixShader')
    k = nt.nodes.new('ShaderNodeMath'); k.operation = 'MULTIPLY'
    nt.links.new(a.outputs['Color'], k.inputs[0])
    k.inputs[1].default_value = {'ok': 0.85, 'bad': 1.0, 'fire': 0.9}[kind]
    nt.links.new(k.outputs[0], mx.inputs[0])
    nt.links.new(t.outputs[0], mx.inputs[1])
    nt.links.new(d.outputs[0], mx.inputs[2])
    nt.links.new(mx.outputs[0], out.inputs['Surface'])
    return m


def smooth_sphere(r):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=128, ring_count=64)
    o = bpy.context.active_object
    for p in o.data.polygons:
        p.use_smooth = True
    return o


if __name__ == '__main__':
    kind, mode = sys.argv[1], sys.argv[2]
    setup(res=400, samples=12, cam_scale=2.5, cam_target=(0, 0, 0), elev=90, azim=0)
    sc = bpy.context.scene
    cam = sc.camera
    cam.location = (0, -20, 0)
    cam.rotation_euler = (math.pi / 2, 0, 0)
    sun = bpy.data.objects['sun']
    sun.rotation_euler = Vector((-0.6, -0.75, 0.45)).to_track_quat('Z', 'Y').to_euler()
    bpy.data.lights['sun'].energy = 4.5
    sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.25
    tilt = empty((0, 0, 0))
    tilt.rotation_euler = (math.radians(18), math.radians(-12), 0)
    spin = empty((0, 0, 0), parent=tilt)
    e = smooth_sphere(1.0); e.parent = spin
    e.data.materials.append(surface(kind))
    cspin = empty((0, 0, 0), parent=tilt)
    c = smooth_sphere(1.012); c.parent = cspin
    c.data.materials.append(clouds(kind))
    # longitude offset so Europe/Africa face the camera at frame 0
    base = math.radians(-75)

    def update(t):
        spin.rotation_euler = (0, 0, base + TAU * t)
        cspin.rotation_euler = (0, 0, base + 0.6 + TAU * t * 2)

    if mode == 'preview':
        update(0.0)
        sc.render.filepath = f'/home/claude/gen/b3d/prev_earth_{kind}.png'
        bpy.ops.render.render(write_still=True)
    else:
        render_frames(update, FRAMES, '/home/claude/gen/b3d/frames', f'planet_{kind}')
