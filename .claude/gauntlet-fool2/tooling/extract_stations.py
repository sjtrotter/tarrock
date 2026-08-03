#!/usr/bin/env python3
"""Extract calibrated drawn silhouette stations after repairing blue guides."""
import json, os
import numpy as np
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
SHEET='/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png'
S=.00201523; ANCHOR_ROW=932; FRONT_X=452; SIDE_X=966

im=np.array(Image.open(SHEET).convert('RGB')); fixed=im.copy()
rgb=im.astype(np.int16)
blue=(rgb[:,:,2]>170)&(rgb[:,:,2]>rgb[:,:,0]+35)&(rgb[:,:,2]>rgb[:,:,1]+15)
guide_rows=np.flatnonzero(blue.sum(axis=1)>300)
# Include anti-aliased fringe; interpolate each contiguous guide band from clean rows.
bad=np.zeros(im.shape[0],bool)
for r in guide_rows: bad[max(0,r-1):min(len(bad),r+2)]=True
for r in np.flatnonzero(bad):
    lo=r-1
    while lo>=0 and bad[lo]: lo-=1
    hi=r+1
    while hi<len(bad) and bad[hi]: hi+=1
    if lo>=0 and hi<len(bad):
        t=(r-lo)/(hi-lo); fixed[r]=np.rint((1-t)*fixed[lo].astype(float)+t*fixed[hi]).astype(np.uint8)
gray=.2126*fixed[:,:,0]+.7152*fixed[:,:,1]+.0722*fixed[:,:,2]
ink=gray<125

def edge_near(row, center, left_bound, right_bound, expected_half=None):
    xs=np.flatnonzero(ink[row,left_bound:right_bound])+left_bound
    if expected_half:
        # select contour candidates near expected torso/leg window, ignoring facial detail
        l=xs[(xs<center-expected_half[0])&(xs>center-expected_half[1])]
        r=xs[(xs>center+expected_half[0])&(xs<center+expected_half[1])]
        return (int(l.min()) if len(l) else None,int(r.max()) if len(r) else None)
    return (int(xs.min()),int(xs.max())) if len(xs)>=2 else (None,None)

rows=[]
for row in range(80,934):
    z=(ANCHOR_ROW-row)*S
    # Torso/head/legs window changes with height. Arm-height rows deliberately
    # use a medial window so this record can compare to mesh torso stations.
    if z>1.50: win=(5,90)
    elif z>1.18: win=(20,150)
    elif z>.82: win=(10,130)
    else: win=(5,125)
    l,r=edge_near(row,FRONT_X,300,605,win)
    side=np.flatnonzero(ink[row,885:1055])+885
    if l is not None and r is not None:
        rows.append({'row':row,'z':z,'front_left_x':(l-FRONT_X)*S,'front_right_x':(r-FRONT_X)*S,'front_half':max(abs(l-FRONT_X),abs(r-FRONT_X))*S,
                     'side_y_min':float((side.min()-SIDE_X)*S) if len(side)>=2 else None,'side_y_max':float((side.max()-SIDE_X)*S) if len(side)>=2 else None})
out={'source':SHEET,'scale_m_per_px':S,'front_anchor_px':[FRONT_X,ANCHOR_ROW],'side_anchor_px':[SIDE_X,ANCHOR_ROW],
     'guide_rows_detected':guide_rows.tolist(),'repair':'linear RGB interpolation across each guide row plus 1px antialias fringe','rows':rows}
with open(os.path.join(HERE,'sheet_stations.json'),'w') as f: json.dump(out,f,indent=2)
base=json.load(open(os.path.join(HERE,'stations_base.json')))
spots=[]
for z in [.10,.30,.50,.70,.90,1.05,1.18,1.26,1.42,1.62]:
    region='leg' if z<.94 else 'torso'
    b=min(base['regions'][region],key=lambda q:abs(q['z']-z)); s=min(rows,key=lambda q:abs(q['z']-z))
    spots.append({'z_m':z,'mesh_region':region,'mesh_x_half_mm':1000*b['x_half'],'sheet_x_half_mm':1000*s['front_half'],'delta_mm':1000*(b['x_half']-s['front_half'])})
out['spot_checks']=spots
with open(os.path.join(HERE,'sheet_stations.json'),'w') as f: json.dump(out,f,indent=2)
print('guide_rows',guide_rows.tolist()); print('SPOT_CHECKS')
for q in spots: print('z=%.3f region=%s mesh=%.2fmm sheet=%.2fmm delta=%+.2fmm'%(q['z_m'],q['mesh_region'],q['mesh_x_half_mm'],q['sheet_x_half_mm'],q['delta_mm']))
