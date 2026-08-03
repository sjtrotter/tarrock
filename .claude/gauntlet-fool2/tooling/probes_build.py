import bpy, bmesh, json, os, numpy as np
from mathutils.bvhtree import BVHTree
HERE=os.path.dirname(os.path.abspath(__file__)); obj=bpy.data.objects['Fool_SculptBase']
n=len(obj.data.vertices); v=np.empty(n*3,np.float32); obj.data.vertices.foreach_get('co',v); v=v.reshape(-1,3).astype(float)
# LEFT hand (+X). Learn five digit Y centerlines from distal hand vertices; fixed
# k-means is deterministic. Mirroring yields the right-hand probes too.
hand=v[(v[:,0]>.54)&(v[:,2]>1.15)&(v[:,2]<1.36)&(np.abs(v[:,1])<.18)]
ys=hand[:,1]; centers=np.linspace(np.percentile(ys,5),np.percentile(ys,95),5)
for _ in range(30):
    lab=np.argmin(abs(ys[:,None]-centers[None,:]),axis=1); new=np.array([np.median(ys[lab==k]) for k in range(5)])
    if np.max(abs(new-centers))<1e-8: break
    centers=new
centers.sort(); print('digit_y_centers',centers.tolist())
bm=bmesh.new(); bm.from_mesh(obj.data); bvh=BVHTree.FromBMesh(bm,epsilon=0.0)
probes=[]; pair_names=['pinky|ring','ring|middle','middle|index','index|thumb']
# Use span common to the central fingers; thumb overlap is shortened automatically.
for pair,(ya,yb) in zip(pair_names,zip(centers[:-1],centers[1:])):
    candidates=[]
    for x in np.linspace(.55,.86,160):
        slab=v[(abs(v[:,0]-x)<.0025)&(v[:,2]>1.17)&(v[:,2]<1.34)]
        aa=slab[abs(slab[:,1]-ya)<abs(yb-ya)*.42]; bb=slab[abs(slab[:,1]-yb)<abs(yb-ya)*.42]
        if len(aa)<5 or len(bb)<5: continue
        # opposing Y surfaces, then nearest cross-gap pair in Z
        sa=aa[aa[:,1] >= np.percentile(aa[:,1],85)]; sb=bb[bb[:,1] <= np.percentile(bb[:,1],15)]
        if not len(sa) or not len(sb): continue
        dz=(sa[:,2,None]-sb[None,:,2])**2
        best=None
        for flat in np.argpartition(dz.ravel(),min(40,dz.size)-1)[:min(40,dz.size)]:
            ia,ib=np.unravel_index(flat,dz.shape); p=(sa[ia]+sb[ib])/2; p[0]=x
            hit,norm,idx,dist=bvh.find_nearest(p)
            outside=float(np.dot(p-np.array(hit),np.array(norm)))>0
            if outside and (best is None or dist>best[2]): best=(x,p,dist)
        if best is not None: candidates.append(best)
    # evenly retain 20 along the actually shared outside span
    if len(candidates)>=20:
        for j in np.linspace(0,len(candidates)-1,20).round().astype(int):
            x,p,dist=candidates[j]
            for side in (1,-1):
                q=p.copy(); q[0]*=side
                hit,norm,idx,d=bvh.find_nearest(q); outside=float(np.dot(q-np.array(hit),np.array(norm)))>0
                probes.append({'pair':pair,'hand':'left' if side==1 else 'right','point':q.tolist(),'outside':bool(outside),'clearance_m':float(d)})
    print(pair,'outside_candidates',len(candidates))
bm.free(); passed=sum(q['outside'] for q in probes)
out={'source_object':'Fool_SculptBase','method':'midpoint opposing surface vertices; BVH closest-point outward-normal sign','params':{'x_slab_m':.0025,'surface_percentiles':[85,15],'stations_per_pair_per_hand':20,'digit_y_centers_left':centers.tolist()},'probes':probes,'gate':{'passed':passed,'total':len(probes)}}
with open(os.path.join(HERE,'webbing_probes.json'),'w') as f: json.dump(out,f,indent=2)
print('PROBE_GATE %d/%d outside pass=%s'%(passed,len(probes),passed==len(probes) and len(probes)>=80))
assert len(probes)>=80 and passed==len(probes)
