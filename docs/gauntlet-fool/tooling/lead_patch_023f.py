"""Lead patch: bind zero-weight orphan verts to nearest hand-chain bone; full
re-validation; clean battery renders + ear-audit close-ups. 023e -> 023f."""
import bpy, json, math, os, sys
from mathutils import Vector, Quaternion, Matrix
from mathutils.bvhtree import BVHTree

PATH, OUT, OUTDIR, OUTJSON = sys.argv[sys.argv.index('--')+1:]
os.makedirs(OUTDIR, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=PATH)
rig = bpy.data.objects['FoolRig']; mesh = bpy.data.objects['Fool_Mesh']
base = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
rep = {}

# 1) orphan verts
orphans = [v.index for v in mesh.data.vertices
           if not any(g.weight > 0 for g in v.groups)]
rep['orphans'] = {'count': len(orphans),
                  'rest_mm': {i: [round(x * 1e3, 1) for x in base[i]] for i in orphans}}

# 2) nearest deform-bone segment among hand-chain bones on the vert's side
hand_chain = ['Hand', 'Thumb.01', 'Thumb.02', 'Thumb.03', 'Index.01', 'Index.02',
              'Index.03', 'Middle.01', 'Middle.02', 'Middle.03', 'Ring.01',
              'Ring.02', 'Ring.03', 'Pinky.01', 'Pinky.02', 'Pinky.03']
def segdist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-12)))
    return (p - (a + ab * t)).length
assign = {}
for i in orphans:
    side = 'L' if base[i].x > 0 else 'R'
    best, bn = 1e9, None
    for nm in hand_chain:
        b = rig.data.bones[nm + '.' + side]
        d = segdist(base[i], Vector(b.head_local), Vector(b.tail_local))
        if d < best: best, bn = d, b.name
    mesh.vertex_groups[bn].add([i], 1.0, 'REPLACE')
    assign[i] = {'bone': bn, 'dist_mm': round(best * 1e3, 1)}
rep['assigned'] = assign
rep['orphans_after'] = sum(1 for v in mesh.data.vertices
                           if not any(g.weight > 0 for g in v.groups))

# mirror-consistency of the patch: mirrored orphan gets mirrored bone
from mathutils.kdtree import KDTree
kd = KDTree(len(base))
for i, p in enumerate(base): kd.insert(p, i)
kd.balance()
mir_ok = True
for i in orphans:
    j = kd.find(Vector((-base[i].x, base[i].y, base[i].z)))[1]
    if j in assign and assign[j]['bone'].split('.')[:-1] != assign[i]['bone'].split('.')[:-1]:
        mir_ok = False
rep['patch_mirror_consistent'] = mir_ok

# 3) statics
me = mesh.data
import bmesh
bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
bvh = BVHTree.FromBMesh(bm)
adj = set()
for f in bm.faces:
    for e in f.edges:
        for g in e.link_faces:
            if g.index != f.index:
                adj.add((min(f.index, g.index), max(f.index, g.index)))
pairs = {(min(a, b), max(a, b)) for a, b in bvh.overlap(bvh) if a != b} - adj
bm.free()
rep['statics'] = {'verts': len(me.vertices), 'faces': len(me.polygons),
                  'self_intersections': len(pairs),
                  'sole_min_z_mm': round(min(p.z for p in base) * 1e3, 4)}

def reset():
    for p in rig.pose.bones:
        p.rotation_mode = 'QUATERNION'; p.rotation_quaternion = (1, 0, 0, 0)
        p.location = (0, 0, 0); p.scale = (1, 1, 1)
    bpy.context.view_layer.update()

def rotate_world(pb, axis, angle):
    q = pb.bone.matrix_local.to_quaternion()
    pb.rotation_mode = 'QUATERNION'
    pb.rotation_quaternion = q.inverted() @ Quaternion(Vector(axis), angle) @ q

def coords():
    dg = bpy.context.evaluated_depsgraph_get()
    ev = mesh.evaluated_get(dg); m2 = ev.to_mesh()
    out = [ev.matrix_world @ v.co for v in m2.vertices]
    ev.to_mesh_clear(); return out

# rest identity
reset()
co = coords()
rep['rest_max_dev_mm'] = round(max((co[i] - base[i]).length for i in range(len(base))) * 1e3, 6)

# 4) a80 lag re-check (both sides)
reset()
rotate_world(rig.pose.bones['UpperArm.L'], (0, 1, 0), math.radians(80))
rotate_world(rig.pose.bones['UpperArm.R'], (0, 1, 0), -math.radians(80))
bpy.context.view_layer.update()
co = coords()
lagmax = 0.0
for s, bone in ((1, 'UpperArm.L'), (-1, 'UpperArm.R')):
    sh = Vector(rig.data.bones[bone].head_local)
    R = Matrix.Rotation(s * math.radians(80), 4, Vector((0, 1, 0)))
    for i in range(len(base)):
        if base[i].x * s > 0.45:
            expected = R @ (base[i] - sh) + sh
            lagmax = max(lagmax, (co[i] - expected).length)
rep['a80_hand_lag_max_mm'] = round(lagmax * 1e3, 2)

# eye swap verification
ev = {}
for s in ('L', 'R'):
    b = rig.data.bones['Eye.' + s]; g = bpy.data.objects['Fool_Eye_' + s]
    ev[s] = {'bone_head_x_mm': round(b.head_local.x * 1e3, 2),
             'globe_x_mm': round(g.matrix_world.translation.x * 1e3, 2),
             'parent_bone': g.parent_bone}
rep['eye_sides'] = ev

# 5) renders: whitelist only
keep = {'Fool_Mesh', 'Fool_Eye_L', 'Fool_Eye_R'}
for o in bpy.context.scene.objects:
    o.hide_render = o.name not in keep
scene = bpy.context.scene
camdat = bpy.data.cameras.new('LeadCam'); cam = bpy.data.objects.new('LeadCam', camdat)
scene.collection.objects.link(cam); scene.camera = cam; cam.hide_render = True
camdat.type = 'ORTHO'
scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1024; scene.render.resolution_y = 1024
scene.render.image_settings.file_format = 'PNG'
sh_ = scene.display.shading
sh_.light = 'STUDIO'; sh_.show_shadows = True; sh_.show_cavity = True
sh_.cavity_type = 'WORLD'; sh_.show_specular_highlight = False
sh_.color_type = 'SINGLE'; sh_.single_color = (.62, .62, .62)

def render(name, loc, aim, scale):
    cam.location = loc
    cam.rotation_euler = (Vector(aim) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    camdat.ortho_scale = scale
    scene.render.filepath = os.path.join(OUTDIR, name)
    bpy.ops.render.render(write_still=True)

for ang in (45, 80):
    reset()
    rotate_world(rig.pose.bones['UpperArm.L'], (0, 1, 0), math.radians(ang))
    rotate_world(rig.pose.bones['UpperArm.R'], (0, 1, 0), -math.radians(ang))
    bpy.context.view_layer.update()
    render(f'f-a{ang}-front.png', (0, -4, .95), (0, 0, .95), 1.95)
    render(f'f-a{ang}-tq.png', (2.8, -2.8, .95), (0, 0, .95), 1.95)
    render(f'f-a{ang}-shoulder-zoom.png', (1.2, -1.6, 1.30), (0.19, 0, 1.32), .55)
reset()
for side in ('L', 'R'):
    sgn = 1 if side == 'L' else -1
    for d in ('Thumb', 'Index', 'Middle', 'Ring', 'Pinky'):
        for n in range(1, 4):
            rotate_world(rig.pose.bones[f'{d}.{n:02d}.{side}'], (0, 1, 0),
                         sgn * math.radians(60))
bpy.context.view_layer.update()
render('f-fingers-top.png', (.76, 0, 2.2), (.76, 0, 1.29), .40)
render('f-fingers-palm-tq.png', (1.25, -1.4, 1.8), (.76, 0, 1.29), .40)

# ear audit close-ups (rest pose)
reset()
render('ear-side-L.png', (2.0, 0, 1.60), (0.0, 0, 1.60), .22)
render('ear-tq-back.png', (1.6, 1.6, 1.62), (0, 0, 1.60), .30)
render('ear-front.png', (0, -2.0, 1.60), (0, 0, 1.60), .28)

reset()
bpy.ops.wm.save_as_mainfile(filepath=OUT)
json.dump(rep, open(OUTJSON, 'w'), indent=2)
print(json.dumps(rep, indent=2)[:9000])
print('SAVED', OUT)
