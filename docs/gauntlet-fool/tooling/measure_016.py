"""Extract the immutable 016 station baseline and eye-section measurements."""
import bpy, json, os, sys
import numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = argv[0]
sys.path.insert(0, "/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling")
from fieldlib import silhouette_stations, save_json, vertex_hash

ob = bpy.data.objects["Fool_SculptBase"]
deps = bpy.context.evaluated_depsgraph_get(); ev = ob.evaluated_get(deps)
mesh = ev.to_mesh()
mw = ev.matrix_world
verts = np.array([tuple(mw @ v.co) for v in mesh.vertices], dtype=np.float64)
stations = silhouette_stations(verts, bin_mm=2.5)
stations.update({"source_blend":"Fool-v2-016.blend", "object":ob.name,
                 "vertex_count":len(verts), "vertex_hash_float32_world":vertex_hash(verts)})
save_json(os.path.join(OUT, "stations_016.json"), stations)

# BVH ray casts use world coordinates via scene.ray_cast.
eyes = []
for x in (-.043, .043):
    ok, loc, normal, face, hitob, matrix = bpy.context.scene.ray_cast(
        deps, Vector((x, -1.0, 1.571)), Vector((0, 1, 0)), distance=2.0)
    eyes.append({"x_m":x,"z_m":1.571,"hit":bool(ok),"surface_y_m":float(loc.y) if ok else None,
                 "object":hitob.name if ok else None,"face_index":int(face) if ok else None})

# Lateral skull wall: for each eye X, cast outward from axis at eye height.
walls=[]
for sign in (-1, 1):
    ok, loc, normal, face, hitob, matrix = bpy.context.scene.ray_cast(
        deps, Vector((0, 0, 1.571)), Vector((sign, 0, 0)), distance=1.0)
    walls.append({"side":sign,"hit":bool(ok),"x_m":float(loc.x) if ok else None,
                  "y_m":float(loc.y) if ok else None,"z_m":float(loc.z) if ok else None})
save_json(os.path.join(OUT,"mesh_eye_measurements.json"), {"face_ray_hits":eyes,"axis_outward_hits":walls})
ev.to_mesh_clear()
print("STATIONS", len(verts), stations["z_min"], stations["z_max"], stations["vertex_hash_float32_world"])
print("EYE_RAYS", json.dumps(eyes)); print("WALL_RAYS", json.dumps(walls))
