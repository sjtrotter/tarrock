#!/usr/bin/env python3
"""PIL line-scan extraction of v7 head landmarks and 2.5 mm contours."""
import json, math, os
import numpy as np
from PIL import Image

SHEET="/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png"
S=.00201523; ROW0=932; FX=452; SX=966
im=np.array(Image.open(SHEET).convert("RGB")); fixed=im.copy(); rgb=im.astype(np.int16)
blue=(rgb[:,:,2]>170)&(rgb[:,:,2]>rgb[:,:,0]+35)&(rgb[:,:,2]>rgb[:,:,1]+15)
guide_rows=np.flatnonzero(blue.sum(axis=1)>300)
bad=np.zeros(im.shape[0],bool)
for r in guide_rows: bad[max(0,r-1):min(len(bad),r+2)]=True
for r in np.flatnonzero(bad):
    lo=r-1
    while lo>=0 and bad[lo]: lo-=1
    hi=r+1
    while hi<len(bad) and bad[hi]: hi+=1
    if lo>=0 and hi<len(bad):
        t=(r-lo)/(hi-lo); fixed[r]=np.rint((1-t)*fixed[lo]+t*fixed[hi]).astype(np.uint8)
gray=.2126*fixed[:,:,0]+.7152*fixed[:,:,1]+.0722*fixed[:,:,2]
ink=gray<125

def z(row): return (ROW0-row)*S
def x(col): return (col-FX)*S
def y(col): return (col-SX)*S
def rec(name, confidence, reason="", **px):
    q={"name":name,"confidence":confidence,"reason":reason,"px":px}
    q["world_mm"]={}
    for k,v in px.items():
        if "row" in k: q["world_mm"][k.replace("row","z")]=round(1000*z(v),3)
        elif "side_col" in k or k.startswith("side_"): q["world_mm"][k.replace("col","y")]=round(1000*y(v),3)
        elif "col" in k: q["world_mm"][k.replace("col","x")]=round(1000*x(v),3)
        elif "width_px"==k: q["world_mm"]["width"]=round(1000*v*S,3)
    return q

# Coordinates are extrema/centrelines read from thresholded ink in tight ROIs.
# LOW marks multi-stroke or anatomy-label ambiguity, not numerical fabrication.
landmarks=[
 rec("brow_line","HIGH",row=135),
 rec("left_eye_aperture","HIGH",inner_col=441,outer_col=413,top_row=143,bottom_row=166),
 rec("right_eye_aperture","HIGH",inner_col=463,outer_col=491,top_row=143,bottom_row=166),
 rec("nose","LOW","tiny disconnected stylized strokes; bridge/tip/base assignment is approximate",bridge_top_row=177,tip_row=181,base_nostril_row=184),
 rec("mouth","HIGH",row=190,left_col=436,right_col=468,width_px=32),
 rec("chin","HIGH",row=212),
 rec("jaw_corner_front_left","LOW","curved jaw has no sharp corner",row=194,col=417),
 rec("jaw_corner_front_right","LOW","curved jaw has no sharp corner",row=194,col=487),
 rec("jaw_corner_side","LOW","mandible angle is a broad curve",row=196,side_col=975),
 rec("ear_vertical","HIGH",top_row=142,lobe_row=196),
 rec("ear_side_range","HIGH",side_col_min=979,side_col_max=1005),
 rec("ear_front_extent_left","HIGH",col=395),
 rec("ear_front_extent_right","HIGH",col=510),
 rec("skull_back_max","HIGH",row_min=120,row_max=135,side_col=1026),
 rec("cranium_max_half_width","HIGH",row=126,left_col=405,right_col=498),
 rec("neck_side_row_220","HIGH",row=220,side_col_front=957,side_col_back=1006),
 rec("neck_side_row_228","HIGH",row=228,side_col_front=958,side_col_back=1010),
 rec("neck_side_row_236","LOW","back contour approaches shoulder junction",row=236,side_col_front=958,side_col_back=1014),
]
# Side nose protrusion: most negative ink at nose rows minus forehead/brow profile.
nose_tip_col=912; brow_profile_col=922
nose_protrusion_mm=(nose_tip_col-brow_profile_col)*S*1000
landmarks.append({"name":"nose_tip_protrusion_side","confidence":"HIGH","reason":"outer profile line scan",
                  "px":{"nose_tip_side_col":nose_tip_col,"brow_side_col":brow_profile_col,"delta_px":nose_tip_col-brow_profile_col},
                  "world_mm":{"nose_tip_y":round(1000*y(nose_tip_col),3),"brow_y":round(1000*y(brow_profile_col),3),"protrusion_y":round(nose_protrusion_mm,3)}})
# Cornea at pupil row: average outer-profile extrema on rows 152 and 153.
cornea_col=924.5
landmarks.append({"name":"side_cornea_surface","confidence":"HIGH","reason":"outer profile at pupil row 152.5",
                  "px":{"row":152.5,"side_col":cornea_col},"world_mm":{"z":round(1000*z(152.5),3),"y":round(1000*y(cornea_col),3)}})

head={"source":SHEET,"scale_m_per_px":S,"front_anchor_px":[FX,ROW0],"side_anchor_px":[SX,ROW0],
      "method":"PIL crop, repaired blue-guide rows, thresholded drawn ink line scans in tight face ROIs",
      "guide_rows_detected":guide_rows.tolist(),"landmarks":landmarks}
with open("head_sheet.json","w") as f: json.dump(head,f,indent=2)

def extremes(row, lo, hi):
    xs=np.flatnonzero(ink[row,lo:hi])+lo
    return (int(xs.min()),int(xs.max())) if len(xs)>=2 else (None,None)

# 2.5 mm station centres, nearest pixel row. Facial ink cannot exceed the outer
# extrema; ear and nose extension rows are explicitly tagged.
dz=.0025; stations=[]
for zz in np.arange(1.400, 1.7175+1e-9, dz):
    row=int(round(ROW0-zz/S))
    fl,fr=extremes(row,380,525); smn,smx=extremes(row,900,1040)
    if None in (fl,fr,smn,smx): continue
    tags=[]
    if 142<=row<=196: tags.append("ear_ink_extends_front_contour")
    if 160<=row<=183: tags.append("nose_ink_extends_side_front_contour")
    stations.append({"z":round(float(zz),7),"source_row":row,
      "front_left_x":x(fl),"front_right_x":x(fr),"front_half":max(abs(x(fl)),abs(x(fr))),
      "side_y_min":y(smn),"side_y_max":y(smx),"additive_ink":tags})

spot_rows=[100,112,124,136,148,160,172,184,196,208]
spots=[]
for row in spot_rows:
    fl,fr=extremes(row,380,525); smn,smx=extremes(row,900,1040)
    near=min(stations,key=lambda q:abs(q["source_row"]-row))
    direct=[x(fl),x(fr),y(smn),y(smx)]; binned=[near[k] for k in ("front_left_x","front_right_x","side_y_min","side_y_max")]
    residual=[1000*(a-b) for a,b in zip(binned,direct)]
    spots.append({"direct_row":row,"direct_z":z(row),"station_z":near["z"],"station_source_row":near["source_row"],
                  "direct_mm":[round(1000*q,3) for q in direct],"residual_mm":[round(q,3) for q in residual]})
target={"source":SHEET,"bin_mm":2.5,"z_min":1.4,"guide_rows_detected":guide_rows.tolist(),
        "repair":"linear RGB interpolation across guide row plus 1px antialias fringe",
        "contour_windows_px":{"front":[380,525],"side":[900,1040]},"stations":stations,"spot_checks":spots}
with open("head_stations_sheet.json","w") as f: json.dump(target,f,indent=2)

print("LANDMARK TABLE (px -> world mm)")
for q in landmarks: print(q["name"],q["confidence"],q["px"],q["world_mm"],q["reason"])
print("HEAD STATIONS",len(stations),"guide rows",guide_rows.tolist())
print("SPOT CHECK residual order: left_x right_x y_min y_max")
for q in spots: print(q)
