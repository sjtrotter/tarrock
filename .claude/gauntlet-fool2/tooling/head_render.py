"""Head inspection renders: Workbench studio plus a single-sun EEVEE rake.

Usage: blender --background file.blend --python head_render.py -- OUT TAG [views]
"""
import bpy, math, os, sys
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT, TAG = argv[0], argv[1]
VIEWS = argv[2].split(",") if len(argv) > 2 else ["front", "side", "three-quarter", "back"]
os.makedirs(OUT, exist_ok=True)
scene = bpy.context.scene
cam = bpy.data.objects["R5_CAM"]
scene.camera = cam
cam.data.type = "ORTHO"
scene.render.resolution_x, scene.render.resolution_y = 1100, 1400
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
AIM = Vector((0, 0, 1.58))
VIEW_DIRS = {
    "front": Vector((0, -4, 1.58)), "side": Vector((4, 0, 1.58)),
    "three-quarter": Vector((2.83, -2.83, 1.58)), "back": Vector((0, 4, 1.58)),
}

def place_cam(view, full=False):
    aim = Vector((0, 0, .88)) if full else AIM
    loc = VIEW_DIRS[view].copy()
    if full: loc.z = .88
    cam.location = loc
    cam.rotation_euler = (aim - loc).to_track_quat("-Z", "Y").to_euler()
    cam.data.ortho_scale = 3.20 if full else .50

def render(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("WROTE", path)

# Byte-compatible Workbench settings from rms_metric.py / presence_render.py.
scene.render.engine = "BLENDER_WORKBENCH"
d = scene.display.shading
d.light = "STUDIO"; d.show_shadows = True; d.show_cavity = False
d.show_specular_highlight = False; d.color_type = "SINGLE"; d.single_color = (.62, .62, .62)
for view in VIEWS:
    place_cam(view); render(os.path.join(OUT, f"{TAG}-{view}-studio.png"))
place_cam("front", full=True)
render(os.path.join(OUT, f"{TAG}-full-front-studio.png"))

scene.render.engine = "BLENDER_EEVEE"
for ob in [o for o in bpy.data.objects if o.type == "LIGHT"]: ob.hide_render = True
sun = bpy.data.objects.new("R14_HeadRakeSun", bpy.data.lights.new("R14_HeadRakeSun", "SUN"))
scene.collection.objects.link(sun); sun.data.energy = 3.0
scene.world = scene.world or bpy.data.worlds.new("W")
scene.world.use_nodes = False; scene.world.color = (.02, .02, .02)
mat = bpy.data.materials.new("R14_Gray"); mat.use_nodes = False
mat.diffuse_color = (.62, .62, .62, 1)
body = bpy.data.objects["Fool_SculptBase"]
if not body.data.materials: body.data.materials.append(mat)
for view in VIEWS:
    place_cam(view)
    view_dir = (AIM - cam.location).normalized()
    az = el = math.radians(30)
    light_dir = (Matrix.Rotation(az, 3, "Z") @ view_dir) * math.cos(el)
    light_dir = (light_dir + Vector((0, 0, -math.sin(el)))).normalized()
    sun.rotation_euler = light_dir.to_track_quat("-Z", "Y").to_euler()
    render(os.path.join(OUT, f"{TAG}-{view}-rake.png"))
print("HEAD_RENDER_DONE (nothing saved to the blend)")
