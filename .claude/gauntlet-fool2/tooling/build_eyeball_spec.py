#!/usr/bin/env python3
"""Combine calibrated sheet cornea and 016 mesh rays into eyeball placement."""
import json
S=.00201523; SIDE_ANCHOR=966; cornea_col=924.5
r=.035; cx=.043; cz=1.571
cornea_y=(cornea_col-SIDE_ANCHOR)*S
center_y=cornea_y+r
mesh=json.load(open("mesh_eye_measurements.json"))
surfaces=[q["surface_y_m"] for q in mesh["face_ray_hits"]]
walls=[abs(q["x_m"]) for q in mesh["axis_outward_hits"]]
clear=[w-(cx+r) for w in walls]
spec={
 "source_sheet":"Fool-Tpose-ModelSheet-v7.png","source_mesh":"Fool-v2-016.blend",
 "sphere_radius_m":r,"centers_m":[[-cx,center_y,cz],[cx,center_y,cz]],
 "drawn_cornea":{"row_px":152.5,"side_col_px":cornea_col,"surface_y_m":cornea_y,"confidence":"HIGH"},
 "current_face_surface_y_m":{"left":surfaces[0],"right":surfaces[1],"method":"ray from (x,-1,z) toward +Y; first hit"},
 "socket_geometry":{
   "sphere_front_y_m":center_y-r,
   "center_recession_behind_current_surface_m":{"left":center_y-surfaces[0],"right":center_y-surfaces[1]},
   "sphere_front_minus_current_surface_m":{"left":cornea_y-surfaces[0],"right":cornea_y-surfaces[1]},
   "interpretation":"negative front-minus-surface means the drawn cornea/sphere projects forward (-Y); center recession is depth from current face surface to eye center"
 },
 "lateral_skull_wall_x_m":{"left":-walls[0],"right":walls[1]},
 "lateral_clearance_m":{"left":clear[0],"right":clear[1]},
 "midline_gap_between_spheres_m":2*cx-2*r,
 "geometrically_impossible":bool(min(clear)<0 or 2*cx-2*r<0),
 "flags":[] if min(clear)>=0 and 2*cx-2*r>=0 else ["sphere overlap or lateral wall collision"]
}
with open("eyeball_spec.json","w") as f: json.dump(spec,f,indent=2)
print(json.dumps(spec,indent=2))
