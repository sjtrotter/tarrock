"""True presence-test renders (fixes the R13 '-flat' defect: those files were
byte-identical to the studio renders — no distinct lighting was ever applied).

Renders TWO genuinely different variants per view for a given chain file:
  <tag>-<view>-studio.png : Workbench STUDIO (matches tooling/rms_metric.py
                            settings — continuity with the r13 A/B sets)
  <tag>-<view>-rake.png   : EEVEE, single sun 30 deg off the view axis, no
                            fill — relief must survive this or it does not exist.

Usage (headless, one Blender lane, governor rules apply):
  blender --background <chain.blend> --python presence_render.py -- \
      <out_dir> <tag> [front,back,side,three-quarter]
"""
import bpy, math, os, sys
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT, TAG = argv[0], argv[1]
VIEWS = (argv[2].split(",") if len(argv) > 2 else ["front", "back"])
os.makedirs(OUT, exist_ok=True)

scene = bpy.context.scene
cam = bpy.data.objects["R5_CAM"]
scene.camera = cam
cam.data.type = "ORTHO"
cam.data.ortho_scale = 3.20
scene.render.resolution_x, scene.render.resolution_y = 1400, 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False

AIM = Vector((0, 0, 0.88))
VIEW_DIRS = {  # camera location offsets (character faces -Y)
    "front": Vector((0, -4, 0.88)),
    "back": Vector((0, 4, 0.88)),
    "side": Vector((4, 0, 0.88)),
    "three-quarter": Vector((2.83, -2.83, 0.88)),
}

def place_cam(view):
    cam.location = VIEW_DIRS[view]
    cam.rotation_euler = (AIM - cam.location).to_track_quat("-Z", "Y").to_euler()

def render_to(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("WROTE", path)

# --- variant 1: Workbench studio (rms_metric.py settings, unchanged) ---
scene.render.engine = "BLENDER_WORKBENCH"
d = scene.display.shading
d.light = "STUDIO"
d.show_shadows = True
d.show_cavity = False
d.show_specular_highlight = False
d.color_type = "SINGLE"
d.single_color = (0.62, 0.62, 0.62)
for v in VIEWS:
    place_cam(v)
    render_to(os.path.join(OUT, f"{TAG}-{v}-studio.png"))

# --- variant 2: EEVEE single raking sun, no fill ---
scene.render.engine = "BLENDER_EEVEE"  # Blender 5.2 enum (Eevee Next under the classic name)
# kill all existing lights; add one sun
for ob in [o for o in bpy.data.objects if o.type == "LIGHT"]:
    ob.hide_render = True
sun = bpy.data.objects.new("R13_RakeSun", bpy.data.lights.new("R13_RakeSun", "SUN"))
scene.collection.objects.link(sun)
sun.data.energy = 3.0
scene.world = scene.world or bpy.data.worlds.new("W")
scene.world.use_nodes = False
scene.world.color = (0.02, 0.02, 0.02)  # near-black ambient: sun does the talking
mat = bpy.data.materials.new("R13_Gray")
mat.use_nodes = False
mat.diffuse_color = (0.62, 0.62, 0.62, 1.0)
body = bpy.data.objects["Fool_SculptBase"]
if not body.data.materials:
    body.data.materials.append(mat)
from mathutils import Matrix
for v in VIEWS:
    place_cam(v)
    # Sun travels along the view axis rotated 30 deg in azimuth, dipped 30 deg
    # from above — oblique front lighting, so relief shades but forms stay lit.
    view_dir = (AIM - cam.location).normalized()
    az, el = math.radians(30), math.radians(30)
    d = (Matrix.Rotation(az, 3, "Z") @ view_dir) * math.cos(el)
    d = (d + Vector((0, 0, -math.sin(el)))).normalized()
    sun.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    render_to(os.path.join(OUT, f"{TAG}-{v}-rake.png"))

print("PRESENCE_RENDER_DONE (nothing saved to the blend)")
