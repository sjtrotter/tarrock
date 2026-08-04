"""Wire-over-shaded renders that actually draw wires in a background render.

render_body.py sets obj.show_wire / show_all_edges, which are VIEWPORT OVERLAY
flags: bpy.ops.render.render() in --background never draws them, so its
'-wire' images are byte-identical to the '-shaded' ones. This rig builds a real
wireframe shell with a Wireframe modifier and renders it dark over the light
shaded body (Workbench, OBJECT colour).

blender --background --factory-startup --python render_wire.py -- BLEND [OBJ] [OUTDIR] [TAG] [VIEWS]
"""
import bpy, os, sys
from mathutils import Vector

av = sys.argv[sys.argv.index('--') + 1:]
path = av[0]
name = av[1] if len(av) > 1 else 'Fool_BodyRetopo'
outdir = av[2] if len(av) > 2 else '/home/betty/tarrock-gauntlet-work/fool2-r16/renders-b'
tag = av[3] if len(av) > 3 else 'w'
sel = av[4].split(',') if len(av) > 4 and av[4] else None
os.makedirs(outdir, exist_ok=True)

for o in list(bpy.data.objects):        # factory-startup ships a 2 m cube
    bpy.data.objects.remove(o, do_unlink=True)

with bpy.data.libraries.load(path, link=False) as (src, dst):
    dst.objects = [name]
obj = dst.objects[0]
bpy.context.scene.collection.objects.link(obj)
obj.hide_render = False
obj.color = (0.66, 0.66, 0.66, 1.0)

wire = obj.copy()
wire.data = obj.data.copy()
bpy.context.scene.collection.objects.link(wire)
bpy.context.view_layer.objects.active = wire
wire.select_set(True)
m = wire.modifiers.new('WIRE', 'WIREFRAME')
m.thickness = 0.0016
m.use_replace = True
m.use_boundary = True
bpy.ops.object.modifier_apply(modifier=m.name)
wire.color = (0.03, 0.03, 0.05, 1.0)

scene = bpy.context.scene
cam = bpy.data.cameras.new('C')
camera = bpy.data.objects.new('C', cam)
scene.collection.objects.link(camera)
scene.camera = camera
cam.type = 'ORTHO'
scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.image_settings.file_format = 'PNG'
d = scene.display.shading
d.light = 'STUDIO'
d.show_shadows = False
d.show_cavity = True
d.cavity_type = 'WORLD'
d.show_specular_highlight = False
d.color_type = 'OBJECT'

VIEWS = {
    'front': ((0, -4, .86), (0, 0, .86), 1.90),
    'back': ((0, 4, .86), (0, 0, .86), 1.90),
    'side': ((4, 0, .86), (0, 0, .86), 1.90),
    'three-quarter': ((2.83, -2.83, .86), (0, 0, .86), 1.90),
    'torso': ((0, -3, 1.15), (0, 0, 1.15), 0.80),
    'torso-side': ((3, 0, 1.15), (0, 0, 1.15), 0.80),
    'shoulder': ((1.2, -2.0, 1.45), (0.25, 0.03, 1.33), 0.40),
    'shoulder-front': ((0.15, -2.0, 1.34), (0.15, 0, 1.34), 0.40),
    'armpit': ((0.6, -1.5, 1.10), (0.22, 0.02, 1.27), 0.40),
    'hand-top': ((.76, 0, 2.2), (.76, 0, 1.30), .34),
    'hand-front': ((.76, -2.0, 1.30), (.76, 0, 1.30), .34),
    'hand-3q': ((1.2, -1.4, 1.9), (.77, -0.01, 1.30), .30),
    'elbow': ((0.45, -1.5, 1.34), (0.45, 0, 1.34), 0.24),
    'crotch': ((0.0, -1.6, 0.86), (0, 0, 0.86), 0.42),
    'crotch-3q': ((1.1, -1.1, 1.05), (0.02, 0.01, 0.85), 0.42),
    'knee': ((.12, -1.2, .50), (.12, 0, .50), .40),
    'knee-side': ((1.5, 0.0, .50), (.12, 0.02, .50), .40),
    'foot': ((.13, -1.0, .16), (.13, 0, .16), .40),
    'foot-side': ((1.4, -0.02, .10), (.13, -0.02, .08), .34),
    'foot-3q': ((.55, -.45, .38), (.15, -.03, .05), .34),
    'sole': ((.14, -0.03, -1.0), (.14, -0.03, .05), .34),
    'neck-seam': ((0, -1.0, 1.442), (0, 0, 1.442), .30),
    'neck-3q': ((0.9, -0.9, 1.50), (0, 0.02, 1.42), .30),
}
for vn, (loc, aim, s) in VIEWS.items():
    if sel and vn not in sel:
        continue
    camera.location = loc
    camera.rotation_euler = (Vector(aim) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    cam.ortho_scale = s
    scene.render.filepath = os.path.join(outdir, f'{tag}-{vn}.png')
    bpy.ops.render.render(write_still=True)
    print('WROTE', scene.render.filepath)
print('RENDER_WIRE_DONE')
