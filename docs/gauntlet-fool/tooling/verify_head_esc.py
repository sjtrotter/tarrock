"""Corrected self-intersection / structure check for Fool_HeadRetopo.

verify_body.py loads Fool_HeadRetopo from the CHAIN first and then link-loads the
candidate's object of the same name; Blender renames the second to
'Fool_HeadRetopo.001', so `obs['Fool_HeadRetopo']` is still the CHAIN mesh and the
candidate is never measured. This runner loads exactly one head per invocation and
otherwise reproduces verify_body.py's instrument (BVHTree.FromBMesh self-overlap
minus edge-adjacent face pairs, KDTree mirror residual, quad census, neck ring).

blender --background --factory-startup --python verify_head_esc.py -- BLEND OUT.json
"""
import bpy, bmesh, json, math, os, sys
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

CHAIN = "/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-020.blend"
av = sys.argv[sys.argv.index("--") + 1:]
cand, out_path = av[0], av[1]


def load_head(path, want="Fool_HeadRetopo"):
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.objects = [want]
    return dst.objects[0]


ob = load_head(cand)
bpy.context.scene.collection.objects.link(ob)
M = ob.matrix_world
bm = bmesh.new(); bm.from_mesh(ob.data)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()

cbvh = BVHTree.FromBMesh(bm)
adj = set()
for f in bm.faces:
    for e in f.edges:
        for g in e.link_faces:
            if g.index != f.index:
                adj.add((min(f.index, g.index), max(f.index, g.index)))
pairs = sorted({(min(a, b), max(a, b)) for a, b in cbvh.overlap(cbvh) if a != b} - adj)
sites = []
for a, b in pairs[:60]:
    c = (M @ bm.faces[a].calc_center_median() + M @ bm.faces[b].calc_center_median()) * .5
    sites.append([round(x * 1000, 2) for x in c])

coords = [M @ v.co for v in ob.data.vertices]
kd = KDTree(len(coords))
for i, p in enumerate(coords): kd.insert(p, i)
kd.balance()
worst, offenders = 0.0, []
for p in coords:
    dmm = 1000 * kd.find(Vector((-p.x, p.y, p.z)))[2]
    worst = max(worst, dmm)
    if dmm > 0.01: offenders.append([round(1000 * x, 3) for x in p])

counts = {"quads": 0, "triangles": 0, "ngons": 0}
for f in bm.faces:
    counts["quads" if len(f.verts) == 4 else "triangles" if len(f.verts) == 3 else "ngons"] += 1
counts["face_count"] = len(bm.faces)
counts["tri_equivalent"] = sum(len(f.verts) - 2 for f in bm.faces)
counts["quad_share"] = round(counts["quads"] / max(len(bm.faces), 1), 6)
counts["vertices"] = len(bm.verts)
boundary = [e for e in bm.edges if len(e.link_faces) == 1]
counts["boundary_edge_count"] = len(boundary)
counts["non_manifold_edge_count"] = len([e for e in bm.edges if not e.is_manifold])

# valence census, and degree-3 boundary vertices in the critical mouth/canthus boxes
deg = {v.index: len(v.link_edges) for v in bm.verts}
crit = []
for v in bm.verts:
    p = M @ v.co
    near_mouth = 0.025 <= abs(p.x) <= 0.045 and 1.478 <= p.z <= 1.507
    near_canthus = 0.003 <= abs(p.x) <= 0.030 and 1.535 <= p.z <= 1.605
    if deg[v.index] != 4 and (near_mouth or near_canthus):
        crit.append({"degree": deg[v.index], "boundary": bool([e for e in v.link_edges if len(e.link_faces) == 1]),
                     "co_mm": [round(1000 * x, 2) for x in p]})

# neck ring against the chain (index correspondence for the first N chain vertices)
src = load_head(CHAIN)
sco = [M @ v.co for v in src.data.vertices]
zmin = min(p.z for p in coords)
neck = [i for i, p in enumerate(coords) if abs(p.z - zmin) <= 1e-6]
neck_delta = [1000 * (coords[i] - sco[i]).length for i in neck if i < len(sco)]

# globe clearance for the aperture boundary rings
res_cl = {}
bverts = sorted({v.index for e in boundary for v in e.verts})
for side, C in {"L": Vector((-0.043, -0.0403, 1.571)), "R": Vector((0.043, -0.0403, 1.571))}.items():
    ids = [i for i in bverts if abs(coords[i].x - C.x) < .055 and abs(coords[i].z - C.z) < .055]
    vis = [1000 * ((coords[i] - C).length - .035) for i in ids if coords[i].y <= C.y]
    hid = [1000 * ((coords[i] - C).length - .035) for i in ids if coords[i].y > C.y]
    res_cl[side] = {"rim_vertices": len(ids), "visible_min_mm": min(vis, default=None),
                    "visible_max_mm": max(vis, default=None), "hidden_count": len(hid),
                    "hidden_max_mm": max(hid, default=None)}
pen = sum(1 for p in coords if min((p - Vector((0.043, -0.0403, 1.571))).length,
                                   (p - Vector((-0.043, -0.0403, 1.571))).length) < 0.035)

out = {"candidate": cand, "object": "Fool_HeadRetopo",
       "self_intersections": {"face_pair_count": len(pairs), "sample_sites_mm": sites},
       "mirror_residual": {"max_mm": round(worst, 6), "offender_count": len(offenders),
                           "sample_offenders_mm": offenders[:20]},
       "topology": counts, "critical_region_non_valence4": crit,
       "neck_ring": {"count": len(neck), "max_delta_mm": max(neck_delta, default=None)},
       "lid_globe_clearance": res_cl, "vertices_inside_globes": pen}
with open(out_path, "w") as f: json.dump(out, f, indent=2)
print(json.dumps({k: out[k] for k in ("self_intersections", "mirror_residual", "topology",
                                      "neck_ring", "lid_globe_clearance", "vertices_inside_globes")},
                 indent=1)[:2600])
print("WROTE", out_path)
