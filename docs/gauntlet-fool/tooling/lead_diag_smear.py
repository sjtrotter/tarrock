"""Find smeared vertices in the a80 and finger-curl poses; report their groups."""
import bpy, json, math, sys
from collections import defaultdict
from mathutils import Vector, Quaternion

PATH, OUTJSON = sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.open_mainfile(filepath=PATH)
rig = bpy.data.objects['FoolRig']; mesh = bpy.data.objects['Fool_Mesh']
gnames = [g.name for g in mesh.vertex_groups]

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
    ev = mesh.evaluated_get(dg); me = ev.to_mesh()
    out = [ev.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear(); return out

base = [mesh.matrix_world @ v.co for v in mesh.data.vertices]

def weights_of(i):
    return {gnames[g.group]: round(g.weight, 4) for g in mesh.data.vertices[i].groups
            if g.weight > 1e-4}

def probe(posefn, label, thresh):
    reset(); posefn(); bpy.context.view_layer.update()
    co = coords()
    bad = []
    for i in range(len(base)):
        d = (co[i] - base[i]).length
        if d > thresh:
            bad.append((d, i))
    bad.sort(reverse=True)
    groups = defaultdict(int)
    for d, i in bad:
        for g in weights_of(i): groups[g] += 1
    return {'count': len(bad),
            'worst': [{'i': i, 'disp_mm': round(d * 1e3, 1),
                       'rest_mm': [round(x * 1e3, 1) for x in base[i]],
                       'groups': weights_of(i)} for d, i in bad[:25]],
            'group_histogram': dict(sorted(groups.items(), key=lambda kv: -kv[1]))}

def pose_a80():
    rotate_world(rig.pose.bones['UpperArm.L'], (0, 1, 0), math.radians(80))
    rotate_world(rig.pose.bones['UpperArm.R'], (0, 1, 0), -math.radians(80))

def pose_fingers():
    for side in ('L', 'R'):
        sign = 1 if side == 'L' else -1
        for dg_ in ('Thumb', 'Index', 'Middle', 'Ring', 'Pinky'):
            for n in range(1, 4):
                rotate_world(rig.pose.bones[f'{dg_}.{n:02d}.{side}'], (0, 1, 0),
                             sign * math.radians(60))

out = {}
# a80: legit arm verts move up to ~2*0.5m*sin(40)... arm length ~0.65m from shoulder
# to fingertip -> max legit ~0.85m. Use displacement vs DISTANCE-FROM-SHOULDER instead:
# flag verts whose displacement exceeds 1.4x their distance to nearest shoulder joint.
sh_l = Vector(rig.data.bones['UpperArm.L'].head_local)
sh_r = Vector(rig.data.bones['UpperArm.R'].head_local)
reset(); pose_a80(); bpy.context.view_layer.update()
co = coords()
bad = []
for i in range(len(base)):
    d = (co[i] - base[i]).length
    r = min((base[i] - sh_l).length, (base[i] - sh_r).length)
    legit = 2 * r * math.sin(math.radians(40))  # chord of 80 deg rotation
    if d > legit + 0.02:
        bad.append((d - legit, d, i))
bad.sort(reverse=True)
groups = defaultdict(int)
for e, d, i in bad:
    for g in weights_of(i): groups[g] += 1
out['a80'] = {'count': len(bad),
              'worst': [{'i': i, 'disp_mm': round(d * 1e3, 1), 'excess_mm': round(e * 1e3, 1),
                         'rest_mm': [round(x * 1e3, 1) for x in base[i]],
                         'groups': weights_of(i)} for e, d, i in bad[:25]],
              'group_histogram': dict(sorted(groups.items(), key=lambda kv: -kv[1]))}
# fingers: legit displacement small (digit lengths ~90mm): flag > 0.13m
out['fingers'] = probe(pose_fingers, 'fingers', 0.13)
json.dump(out, open(OUTJSON, 'w'), indent=2)
print(json.dumps(out, indent=2)[:12000])
