"""Independent R16 body-retopo verifier.

Run headlessly (and through ./gov.sh):
  blender --background --factory-startup --python verify_body.py -- CANDIDATE.blend [OBJECT] [OUTPUT.json]
"""
import bpy,bmesh,json,math,os,sys
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

WD=os.path.dirname(os.path.abspath(__file__))
CHAIN='/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-019.blend'
av=sys.argv[sys.argv.index('--')+1:]; cand_path=av[0] if av else CHAIN
obj_name=av[1] if len(av)>1 else 'Fool_BodyRetopo'; out_path=av[2] if len(av)>2 else os.path.join(WD,'verify-body.json')
def libload(path,names):
 with bpy.data.libraries.load(path,link=False) as (src,dst): dst.objects=[n for n in names if n in src.objects]
 return {o.name:o for o in dst.objects if o}
if os.path.abspath(cand_path)==os.path.abspath(CHAIN): obs=libload(CHAIN,list(dict.fromkeys([obj_name,'Fool_SculptBase','Fool_HeadRetopo'])))
else:
 obs=libload(CHAIN,['Fool_SculptBase','Fool_HeadRetopo']); obs.update(libload(cand_path,[obj_name]))
if obj_name not in obs: raise RuntimeError('candidate object %r not found in %s'%(obj_name,cand_path))
ob,sc,head=obs[obj_name],obs['Fool_SculptBase'],obs['Fool_HeadRetopo']
if ob.type!='MESH':raise RuntimeError('candidate is not a mesh')
def wco(o,v):return o.matrix_world@v.co
def mesh_bvh(o):
 verts=[wco(o,v) for v in o.data.vertices]; polys=[p.vertices[:] for p in o.data.polygons]
 return BVHTree.FromPolygons(verts,polys,all_triangles=False)
sbvh=mesh_bvh(sc)
def stats(vals):
 a=np.array(vals)*1000
 return {'rms_mm':round(float(np.sqrt(np.mean(a*a))),5),'p95_mm':round(float(np.percentile(a,95)),5),'max_mm':round(float(a.max()),5),'sample_count':len(a)}
vdev=[]; inv=[]
normal_matrix=ob.matrix_world.to_3x3().inverted().transposed()
for v in ob.data.vertices:
 p=wco(ob,v); hit,n,_,_=sbvh.find_nearest(p); vdev.append((p-hit).length if hit else math.inf)
 wn=(normal_matrix@v.normal).normalized(); inv.append(bool(n and wn.dot(n)<0))
fdev=[]
for p in ob.data.polygons:
 c=ob.matrix_world@p.center; hit,_,_,_=sbvh.find_nearest(c); fdev.append((c-hit).length if hit else math.inf)

bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table();bm.faces.ensure_lookup_table()
cbvh=BVHTree.FromBMesh(bm); ov=cbvh.overlap(cbvh); adj=set()
for f in bm.faces:
 for e in f.edges:
  for g in e.link_faces:
   if g.index!=f.index:adj.add((min(f.index,g.index),max(f.index,g.index)))
pairs=sorted({(min(a,b),max(a,b)) for a,b in ov if a!=b}-adj)
sites=[]
for a,b in pairs[:50]:
 c=(ob.matrix_world@bm.faces[a].calc_center_median()+ob.matrix_world@bm.faces[b].calc_center_median())*.5;sites.append([round(x*1000,3) for x in c])

# Mirror residual via exact nearest-neighbour lookup.
coords=[wco(ob,v) for v in ob.data.vertices]; kd=KDTree(len(coords))
for i,p in enumerate(coords):kd.insert(p,i)
kd.balance(); worst=0; offenders=[]
for p in coords:
 d=kd.find(Vector((-p.x,p.y,p.z)))[2];worst=max(worst,d)
 if d>1e-5:offenders.append([round(x*1000,3) for x in p])

counts={'quads':0,'triangles':0,'ngons':0}
for f in bm.faces:counts['quads' if len(f.verts)==4 else 'triangles' if len(f.verts)==3 else 'ngons']+=1
counts['quad_share']=round(counts['quads']/max(len(bm.faces),1),6)
boundary=[e for e in bm.edges if len(e.link_faces)==1]; nonman=[e for e in bm.edges if not e.is_manifold]

# Exact 72-vertex head ring, then distance to candidate boundary vertices.
hbm=bmesh.new();hbm.from_mesh(head.data);hbm.verts.ensure_lookup_table(); ringverts={v for e in hbm.edges if len(e.link_faces)==1 for v in e.verts}
hadj={v.index:[] for v in ringverts}
for e in hbm.edges:
 if len(e.link_faces)==1:
  a,b=e.verts;hadj[a.index].append(b.index);hadj[b.index].append(a.index)
seen=set();hloops=[]
for st in hadj:
 if st in seen:continue
 q=[st];seen.add(st);comp=[]
 while q:
  x=q.pop();comp.append(x)
  for y in hadj[x]:
   if y not in seen:seen.add(y);q.append(y)
 hloops.append(comp)
ring=[x for x in hloops if len(x)==72]
if len(ring)!=1:raise RuntimeError('head 72-ring missing')
ckd=KDTree(max(len(boundary),1))
for i,e in enumerate(boundary):pass
bverts=sorted({v for e in boundary for v in e.verts},key=lambda v:v.index)
if bverts:
 ckd=KDTree(len(bverts))
 for i,v in enumerate(bverts):ckd.insert(ob.matrix_world@v.co,i)
 ckd.balance(); seam=[ckd.find(head.matrix_world@hbm.verts[i].co)[2] for i in ring[0]]
else:seam=[math.inf]*72

# Gap rays: trimmed center-to-center segments between adjacent digit axes.
axes=json.load(open(os.path.join(WD,'body_axes.json'))); digs=axes['hands']['left']['digits']; web=[]
if 'Head' in obj_name: webout={'skipped':True,'reason':'head self-test'}
else:
 for a,b in zip(digs,digs[1:]):
  ar=np.array(a['root_mm'])/1000;at=np.array(a['tip_mm'])/1000;br=np.array(b['root_mm'])/1000;bt=np.array(b['tip_mm'])/1000
  for u in np.linspace(.2,.9,8):
   pa=Vector(ar+(at-ar)*u);pb=Vector(br+(bt-br)*u);direction=pb-pa;L=direction.length
   trim=(a['mean_radius_mm']+b['mean_radius_mm'])/2000; start=pa+direction.normalized()*trim; length=max(0,L-2*trim)
   hit=cbvh.ray_cast(ob.matrix_world.inverted()@start,(ob.matrix_world.inverted().to_3x3()@direction).normalized(),length)[0] if length else None
   web.append({'pair':[a['name'],b['name']],'station':round(float(u),3),'pass':hit is None,'midpoint_mm':[round(x*500,3) for x in (pa+pb)]})
 webout={'skipped':False,'pass_count':sum(x['pass'] for x in web),'fail_count':sum(not x['pass'] for x in web),'probes':web}

# Pole census and proximity to recorded creases.
crease=[]
for vals in axes['bend_creases'].values():crease.extend([Vector(np.array(x)/1000) for x in vals])
poles=[];near=[]
for v in bm.verts:
 if len(v.link_edges)!=4:
  p=ob.matrix_world@v.co; poles.append(v)
  d=min(((p-c).length for c in crease),default=math.inf)
  if d<=.015:near.append({'vertex_index':v.index,'coordinate_mm':[round(x*1000,3) for x in p],'valence':len(v.link_edges),'nearest_crease_mm':round(d*1000,3)})
out={'candidate_path':cand_path,'object':obj_name,'vertex_deviation':stats(vdev),'face_centroid_deviation':stats(fdev),
 'inverted_normals':{'count':sum(inv),'vertex_count':len(inv)},'self_intersections':{'face_pair_count':len(pairs),'sample_sites_mm':sites},
 'mirror_residual':{'max_mm':round(worst*1000,6),'offender_count':len(offenders),'threshold_mm':.01,'sample_offenders_mm':offenders[:20]},
 'topology':counts|{'boundary_edge_count':len(boundary),'non_manifold_edge_count':len(nonman)},
 'neck_seam':{'ring_vertex_count':72,'max_mm':round(max(seam)*1000,6),'gate_mm':.01,'pass':max(seam)*1000<=.01,'distances_mm':[round(x*1000,6) for x in seam]},
 'finger_webbing':webout,'pole_census':{'non_valence4_count':len(poles),'within_15mm_of_bend_creases':near}}
with open(out_path,'w') as f:json.dump(out,f,indent=2,allow_nan=True)
print('VERIFY_DONE',json.dumps({k:out[k] for k in ['object','vertex_deviation','face_centroid_deviation','inverted_normals','self_intersections','mirror_residual','topology','neck_seam']},indent=2))
bm.free();hbm.free()
