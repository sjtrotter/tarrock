"""Lead validation for R18 Phase A candidate 023d — clean renders + measures."""
import bpy, json, math, os, sys
from mathutils import Vector, Quaternion
from mathutils.bvhtree import BVHTree

PATH, OUTDIR, OUTJSON = sys.argv[sys.argv.index('--')+1:]
os.makedirs(OUTDIR, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=PATH)
scene = bpy.context.scene
rig = bpy.data.objects['FoolRig']
mesh = bpy.data.objects['Fool_Mesh']

# 1) object inventory: what would render?
inv = []
for o in scene.objects:
    inv.append({'name': o.name, 'type': o.type, 'hide_render': o.hide_render,
                'hide_viewport': o.hide_viewport,
                'parent': o.parent.name if o.parent else None,
                'parent_bone': o.parent_bone or None})

# 2) hide EVERYTHING except Fool_Mesh + eyes from renders
keep = {'Fool_Mesh', 'Fool_Eye_L', 'Fool_Eye_R'}
leaked = [o.name for o in scene.objects if o.type == 'MESH'
          and not o.hide_render and o.name not in keep]
for o in scene.objects:
    if o.type in {'MESH', 'ARMATURE', 'EMPTY', 'CURVE', 'SURFACE'}:
        o.hide_render = o.name not in keep

camdat = bpy.data.cameras.new('LeadCam'); cam = bpy.data.objects.new('LeadCam', camdat)
scene.collection.objects.link(cam); scene.camera = cam; cam.hide_render = True
camdat.type = 'ORTHO'
scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1024; scene.render.resolution_y = 1024
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
sh = scene.display.shading
sh.light = 'STUDIO'; sh.show_shadows = True; sh.show_cavity = True
sh.cavity_type = 'WORLD'; sh.show_specular_highlight = False
sh.color_type = 'SINGLE'; sh.single_color = (.62, .62, .62)

def reset():
    for p in rig.pose.bones:
        p.rotation_mode = 'QUATERNION'; p.rotation_quaternion = (1, 0, 0, 0)
        p.location = (0, 0, 0); p.scale = (1, 1, 1)
    bpy.context.view_layer.update()

def rotate_world(pb, axis, angle):
    q = pb.bone.matrix_local.to_quaternion()
    pb.rotation_mode = 'QUATERNION'
    pb.rotation_quaternion = q.inverted() @ Quaternion(Vector(axis), angle) @ q

def render(name, loc, aim, scale):
    cam.location = loc
    cam.rotation_euler = (Vector(aim) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    camdat.ortho_scale = scale
    scene.render.filepath = os.path.join(OUTDIR, name)
    bpy.ops.render.render(write_still=True)

def coords():
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg); me = ev.to_mesh()
    out = [ev.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear(); return out

base = [mesh.matrix_world @ v.co for v in mesh.data.vertices]

# armhole ring: verts near |x|=0.215 (deltoid/armhole), z band of the socket
def ring_ids(s, x0, tol=0.004):
    return [i for i, p in enumerate(base) if abs(p.x - s * x0) < tol and 1.22 < p.z < 1.46]

def ring_area(ids, pts):
    if len(ids) < 3: return 0.0
    c0 = sum((base[i] for i in ids), Vector()) / len(ids)
    order = sorted(ids, key=lambda i: math.atan2(base[i].z - c0.z, base[i].y - c0.y))
    c = sum((pts[i] for i in order), Vector()) / len(order)
    av = Vector()
    for j, i in enumerate(order):
        av += (pts[i] - c).cross(pts[order[(j + 1) % len(order)]] - c)
    return 0.5 * av.length

out = {'leaked_render_visible_helpers': leaked}
arm = {}
for x0 in (0.205, 0.215, 0.225):
    ids = {s: ring_ids(s, x0) for s in (1, -1)}
    rest = sum(ring_area(v, base) for v in ids.values()) / 2
    per = {'rest_mm2': rest * 1e6, 'counts': {str(s): len(v) for s, v in ids.items()}}
    for ang in (45, 80):
        reset()
        rotate_world(rig.pose.bones['UpperArm.L'], (0, 1, 0), math.radians(ang))
        rotate_world(rig.pose.bones['UpperArm.R'], (0, 1, 0), -math.radians(ang))
        bpy.context.view_layer.update()
        co = coords()
        a = sum(ring_area(v, co) for v in ids.values()) / 2
        per[str(ang)] = {'posed_mm2': a * 1e6,
                         'loss_pct': 100 * (rest - a) / rest if rest else None}
    arm['x%.3f' % x0] = per
out['armhole_rings'] = arm

# clean pose renders
for ang in (45, 80):
    reset()
    rotate_world(rig.pose.bones['UpperArm.L'], (0, 1, 0), math.radians(ang))
    rotate_world(rig.pose.bones['UpperArm.R'], (0, 1, 0), -math.radians(ang))
    bpy.context.view_layer.update()
    render(f'lead-a{ang}-front.png', (0, -4, .95), (0, 0, .95), 1.95)
    render(f'lead-a{ang}-tq.png', (2.8, -2.8, .95), (0, 0, .95), 1.95)
    render(f'lead-a{ang}-shoulder-zoom.png', (1.2, -1.6, 1.30), (0.19, 0, 1.32), .55)

reset()
for side in ('L', 'R'):
    sign = 1 if side == 'L' else -1
    for d in ('Thumb', 'Index', 'Middle', 'Ring', 'Pinky'):
        for n in range(1, 4):
            rotate_world(rig.pose.bones[f'{d}.{n:02d}.{side}'], (0, 1, 0),
                         sign * math.radians(60))
bpy.context.view_layer.update()
render('lead-fingers-top.png', (.76, 0, 2.2), (.76, 0, 1.29), .40)
render('lead-fingers-palm-tq.png', (1.25, -1.4, 1.8), (.76, 0, 1.29), .40)
render('lead-fingers-front.png', (.76, -1.5, 1.29), (.76, 0, 1.29), .40)

reset()
rotate_world(rig.pose.bones['LowerArm.L'], (0, 1, 0), math.radians(90))
bpy.context.view_layer.update()
render('lead-elbow90.png', (1.8, -2.6, 1.25), (.48, 0, 1.25), .85)

# 3) eyes: sphericity + static clearance to mesh
reset(); bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
mev = mesh.evaluated_get(dg); mme = mev.to_mesh()
mco = [mev.matrix_world @ v.co for v in mme.vertices]
polys = [list(p.vertices) for p in mme.polygons]
bvh = BVHTree.FromPolygons(mco, polys, all_triangles=False)
eyes = {}
for side in ('L', 'R'):
    ob = bpy.data.objects['Fool_Eye_' + side]
    em = ob.evaluated_get(dg).to_mesh()
    ctr = Vector((-0.043 if side == 'L' else 0.043, -0.0403, 1.571))
    rads = [((ob.matrix_world @ v.co) - ctr).length for v in em.vertices]
    clear = []
    for v in em.vertices:
        p = ob.matrix_world @ v.co
        q = bvh.find_nearest(p)
        if q[0] is not None: clear.append((p - q[0]).length)
    eyes[side] = {'r_min_mm': min(rads) * 1e3, 'r_max_mm': max(rads) * 1e3,
                  'static_min_clearance_mm': min(clear) * 1e3,
                  'parent': ob.parent.name if ob.parent else None,
                  'parent_bone': ob.parent_bone or None}
    ob.evaluated_get(dg).to_mesh_clear()
mev.to_mesh_clear()
out['eyes'] = eyes

# 4) bone-side consistency + independent statics
eb = rig.data.bones
out['side_check'] = {n: list(eb[n].head_local) for n in
                     ('Hand.L', 'Hand.R', 'Foot.L', 'Foot.R', 'Eye.L', 'Eye.R')}
me = mesh.data
out['statics'] = {'verts': len(me.vertices), 'faces': len(me.polygons)}
reset(); bpy.context.view_layer.update()
co = coords()
out['statics']['rest_max_dev_mm'] = max((co[i] - base[i]).length for i in range(len(base))) * 1e3
out['inventory'] = inv
json.dump(out, open(OUTJSON, 'w'), indent=2)
print(json.dumps({k: out[k] for k in ('leaked_render_visible_helpers', 'armhole_rings', 'eyes', 'side_check', 'statics')}, indent=2))
