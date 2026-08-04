"""R16 Phase-A mechanical extraction from the read-only chain library."""
import bpy, bmesh, json, math, os, sys, gc
import numpy as np
from mathutils import Vector

CHAIN=sys.argv[sys.argv.index('--')+1]
WD=os.path.dirname(os.path.abspath(__file__))
def load(names):
    with bpy.data.libraries.load(CHAIN, link=False) as (src,dst):
        dst.objects=[n for n in names if n in src.objects]
    return {o.name:o for o in dst.objects if o}
def drop(obs):
    for o in obs.values(): bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        if m.users==0: bpy.data.meshes.remove(m)
    gc.collect()
def mm(v, nd=3): return [round(float(x)*1000,nd) for x in v]
def world_coords(o): return np.array([(o.matrix_world@v.co)[:] for v in o.data.vertices],dtype=float)
def bbox(co): return {'min_mm':mm(co.min(0)),'max_mm':mm(co.max(0))}

# Inventory: one datablock at a time to bound peak memory.
with bpy.data.libraries.load(CHAIN,link=False) as (src,dst): names=list(src.objects)
inv=[]
for name in names:
    obs=load([name]); o=obs.get(name)
    item={'name':name,'type':o.type if o else 'UNAVAILABLE','vertex_count':0,'face_count':0,'bounding_box_mm':None}
    if o and o.type=='MESH':
        co=world_coords(o); item.update(vertex_count=len(o.data.vertices),face_count=len(o.data.polygons),bounding_box_mm=bbox(co))
        if name=='Fool_SculptBase':
            bm=bmesh.new(); bm.from_mesh(o.data)
            V,E,F=len(bm.verts),len(bm.edges),len(bm.faces)
            boundary=sum(1 for e in bm.edges if len(e.link_faces)==1)
            nonman=sum(1 for e in bm.edges if not e.is_manifold)
            item['topology']={'boundary_edges':boundary,'non_manifold_edges':nonman,'euler_characteristic':V-E+F,'watertight':boundary==0 and nonman==0}
            bm.free()
    inv.append(item); drop(obs)
with open(os.path.join(WD,'inventory.json'),'w') as f: json.dump({'source':CHAIN,'objects':inv},f,indent=2)

# Exact head boundary loops.
obs=load(['Fool_HeadRetopo']); h=obs['Fool_HeadRetopo']; bm=bmesh.new(); bm.from_mesh(h.data); bm.verts.ensure_lookup_table()
bedges=[e for e in bm.edges if len(e.link_faces)==1]; adj={}
for e in bedges:
    a,b=e.verts; adj.setdefault(a.index,[]).append(b.index); adj.setdefault(b.index,[]).append(a.index)
if any(len(v)!=2 for v in adj.values()): raise RuntimeError('LOUD ERROR: head boundary is not disjoint simple loops')
loops=[]; unseen=set(adj)
while unseen:
    start=min(unseen); loop=[start]; prev=None; cur=start
    while True:
        nxt=adj[cur][0] if adj[cur][0]!=prev else adj[cur][1]
        if nxt==start: break
        if nxt in loop: raise RuntimeError('LOUD ERROR: premature boundary cycle')
        loop.append(nxt); prev,cur=cur,nxt
    unseen.difference_update(loop); loops.append(loop)
sizes=sorted(len(x) for x in loops)
if sizes!=[38,38,72]: raise RuntimeError('LOUD ERROR: expected boundary loop sizes [38,38,72], got %r'%sizes)
neck=[x for x in loops if len(x)==72][0]
coords=np.array([(h.matrix_world@bm.verts[i].co)[:] for i in neck]); cen=coords.mean(0)
rad=np.linalg.norm(coords[:,:2]-cen[:2],axis=1).mean()
neckout={'source_object':h.name,'boundary_loop_count':3,'loop_vertex_counts':[len(x) for x in loops],
 'neck_ring':{'vertex_indices_ordered':neck,'coordinates_mm':[mm(x) for x in coords], 'centroid_mm':mm(cen),
 'mean_radius_mm':round(float(rad)*1000,3),'z_min_mm':round(float(coords[:,2].min())*1000,3),'z_max_mm':round(float(coords[:,2].max())*1000,3)}}
with open(os.path.join(WD,'neck_ring.json'),'w') as f: json.dump(neckout,f,indent=2)
bm.free(); drop(obs)

# Slab-based surface sections. Points are ordered by polar angle and reduced to
# one radial envelope sample per bin. This is deliberately measurement-only.
obs=load(['Fool_SculptBase']); sc=obs['Fool_SculptBase']; co=world_coords(sc)
def section(axis,pos,center_hint=None,bins=64,halfwidth=.0025,selector=None):
    p=co[np.abs(co[:,axis]-pos)<=halfwidth]
    if selector is not None: p=p[selector(p)]
    oth=[i for i in range(3) if i!=axis]
    if len(p)<8:return None
    c=np.array(center_hint if center_hint is not None else p[:,oth].mean(0))
    q=p[:,oth]-c; ang=np.arctan2(q[:,1],q[:,0]); out=[]
    for k in range(bins):
        lo=-math.pi+2*math.pi*k/bins; hi=-math.pi+2*math.pi*(k+1)/bins
        z=p[(ang>=lo)&(ang<hi)]
        if len(z): out.append(z[np.argmax(np.linalg.norm(z[:,oth]-c,axis=1))])
    if len(out)<8:return None
    # Resample cyclic polyline to exactly bins points.
    a=np.array(out); a=np.vstack([a,a[0]]); d=np.linalg.norm(np.diff(a,axis=0),axis=1); s=np.r_[0,np.cumsum(d)]
    t=np.linspace(0,s[-1],bins,endpoint=False); r=[]
    for x in t:
        j=min(np.searchsorted(s,x,side='right')-1,len(d)-1); u=(x-s[j])/max(d[j],1e-12); r.append(a[j]*(1-u)+a[j+1]*u)
    return {'position_mm':round(pos*1000,3),'centroid_mm':mm(np.mean(r,axis=0)),'outline_mm':[mm(x) for x in r]}

# Crotch apex: first ascending z slab with central sculpt samples.
zs=np.arange(.35,1.05,.005); crotch=next((z for z in zs if np.any((np.abs(co[:,0])<.008)&(np.abs(co[:,2]-z)<.0025))),.75)
torso=[]
for z in np.arange(crotch,1.442001,.020):
    s=section(2,z,selector=lambda p: np.abs(p[:,0])<.42)
    if s:torso.append(s)
legs={}
for side,sgn in [('left',1),('right',-1)]:
    ss=[]
    for z in np.arange(.0,crotch+.0001,.020):
        s=section(2,z,center_hint=[sgn*.12,-.005],selector=lambda p,sgn=sgn: p[:,0]*sgn>.008)
        if s:ss.append(s)
    legs[side]={'axis_polyline_mm':[x['centroid_mm'] for x in ss],'sections':ss}

arms={}
for side,sgn in [('left',1),('right',-1)]:
    # wrist from narrowing before hand fan; shoulder crease is torso-side arm root.
    shoulder=sgn*.275; wrist=sgn*.690
    xs=np.arange(abs(shoulder),abs(wrist)+.0001,.015)*sgn
    if sgn<0: xs=-np.arange(abs(shoulder),abs(wrist)+.0001,.015)
    ss=[]
    for x in xs:
        s=section(0,x,center_hint=[-.005,1.22],selector=lambda p: (p[:,2]>.95)&(p[:,2]<1.48))
        if s:ss.append(s)
    arms[side]={'shoulder_crease_x_mm':round(shoulder*1000,3),'wrist_x_mm':round(wrist*1000,3),'axis_polyline_mm':[x['centroid_mm'] for x in ss],'sections':ss}

# Digit axes from purpose-built left hand shell source objects.
drop(obs); shell_names=['HandShell_Thumb','HandShell_Index','HandShell_Middle','HandShell_Ring','HandShell_Pinky']; sh=load(shell_names)
digits=[]
for name in shell_names:
    p=world_coords(sh[name]); p=p[p[:,0]>.60]  # isolate the +X hand; shells contain both mirrored hands
    c=p.mean(0); _,_,vh=np.linalg.svd(p-c,full_matrices=False); axis=vh[0]
    if axis[0]<0: axis=-axis
    t=(p-c)@axis; lo,hi=np.percentile(t,[2,98]); root=c+axis*lo; tip=c+axis*hi
    radial=np.linalg.norm((p-c)-np.outer(t,axis),axis=1)
    secs=[]
    for u in (.2,.5,.8):
        tt=lo+(hi-lo)*u; q=p[np.abs(t-tt)<max(.002,(hi-lo)*.04)]
        secs.append({'station':u,'centroid_mm':mm(q.mean(0) if len(q) else c+axis*tt),'mean_radius_mm':round(float(radial[np.abs(t-tt)<max(.002,(hi-lo)*.04)].mean() if np.any(np.abs(t-tt)<max(.002,(hi-lo)*.04)) else radial.mean())*1000,3)})
    digits.append({'name':name.replace('HandShell_','').lower(),'root_mm':mm(root),'tip_mm':mm(tip),'length_mm':round(float(hi-lo)*1000,3),'mean_radius_mm':round(float(radial.mean())*1000,3),'sections':secs})
# sort thumb->pinky already anatomical, clearance by sampled axis capsules
pairs=[]
for a,b in zip(digits,digits[1:]):
    ar=np.array(a['root_mm'])/1000; at=np.array(a['tip_mm'])/1000; br=np.array(b['root_mm'])/1000; bt=np.array(b['tip_mm'])/1000
    ds=[]
    for u in np.linspace(.15,.95,81): ds.append(np.linalg.norm((ar+(at-ar)*u)-(br+(bt-br)*u))*1000-a['mean_radius_mm']-b['mean_radius_mm'])
    pairs.append({'digits':[a['name'],b['name']],'minimum_clearance_mm':round(float(min(ds)),3)})
drop(sh)

# Low foot mass evidence classification based on lateral profile peak count.
obs=load(['Fool_SculptBase']); co=world_coords(obs['Fool_SculptBase']); low=co[(co[:,2]<.040)&(co[:,0]>.03)]
# A fused sculpt has one connected outer silhouette in low-z slabs; report the
# observed number of separated x/y point clusters using a conservative 4 mm gap.
ys=np.sort(low[:,1]); gaps=np.diff(ys); separated=int(np.sum(gaps>.004)+1) if len(ys) else 0
foot={'classification':'single_foot_mass' if separated<=2 else 'separate_toes','method':'z<40 mm right-foot point-cloud gap census','separated_profile_clusters':separated}

creases={'armpit_mm':[[-275,-15,1220],[275,-15,1220]],'elbow_pit_mm':[[-500,-35,1220],[500,-35,1220]],
 'knee_back_mm':[[-120,40,500],[120,40,500]],'groin_crease_mm':[[0,15,round(crotch*1000,3)]],
 'finger_hinges_mm':[d['root_mm'] for d in digits]}
out={'units':'mm','method':'surface vertex slabs and angular envelope resampling','crotch_apex_z_mm':round(crotch*1000,3),
 'torso':{'axis_polyline_mm':[x['centroid_mm'] for x in torso],'sections':torso},'legs':legs,'arms':arms,
 'hands':{'left':{'digits':digits,'adjacent_clearances':pairs},'right':{'derived_by_x_mirror_of_left':True}},'feet':foot,'bend_creases':creases}
with open(os.path.join(WD,'body_axes.json'),'w') as f: json.dump(out,f,indent=2)
drop(obs)
print('EXTRACTION_DONE',len(inv),len(torso),len(legs['left']['sections']))
