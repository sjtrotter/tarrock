import bpy, json, os, sys
from collections import defaultdict
from mathutils import Vector

SRC, OUT, REPORT = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.open_mainfile(filepath=SRC)
mesh = bpy.data.objects['Fool_Mesh']
rig = bpy.data.objects['FoolRig']
backup = bpy.data.objects['backup_BodyRetopo']
digits = ('Thumb', 'Index', 'Middle', 'Ring', 'Pinky')
sides = ('L', 'R')

def mm(v):
    return [round(float(x) * 1000, 6) for x in v]

def segdist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p-a).dot(ab) / max(ab.length_squared, 1e-15)))
    return (p - (a + t*ab)).length

def point_seg(p, a, b):
    ab = b-a
    t = max(0.0, min(1.0, (p-a).dot(ab) / max(ab.length_squared, 1e-15)))
    return a + t*ab

def point_polyline(points, fraction):
    lengths = [(b-a).length for a,b in zip(points, points[1:])]
    target = fraction * sum(lengths)
    run = 0.0
    for a,b,n in zip(points, points[1:], lengths):
        if target <= run+n or b == points[-1]:
            return a + (b-a) * ((target-run)/max(n, 1e-15))
        run += n
    return points[-1].copy()

# Straightened R16-indexed tube centerlines, in world space.
bco = [backup.matrix_world @ v.co for v in backup.data.vertices]
roots = {
 'Index':[1969,1970,1971,1988,1985,1986,1987,1968],
 'Middle':[1971,1972,1973,1989,1983,1984,1985,1988],
 'Ring':[1973,1974,1975,1990,1981,1982,1983,1989],
 'Pinky':[1975,1976,1977,1978,1979,1980,1981,1990],
 'Thumb':[1926,1927,1928,1947,1967,1966,1965,1946]}
specs = {}
for fi,n in enumerate(('Index','Middle','Ring','Pinky')):
    s=1991+73*fi
    specs[n]={'rings':[list(range(s+8*j,s+8*j+8)) for j in range(9)], 'tip':s+72}
specs['Thumb']={'rings':[list(range(2283+8*j,2283+8*j+8)) for j in range(6)], 'tip':2331}
def centroid(ids):
    return sum((bco[i] for i in ids), Vector()) / len(ids)
centerlines = {}
for d in digits:
    centerlines[d] = [centroid(roots[d])] + [centroid(r) for r in specs[d]['rings']] + [bco[specs[d]['tip']]]

old = {}
for d in digits:
    for s in sides:
        for j in range(1,4):
            b=rig.data.bones[f'{d}.{j:02d}.{s}']
            old[b.name]={'head_mm':mm(rig.matrix_world @ b.head_local), 'tail_mm':mm(rig.matrix_world @ b.tail_local)}

# Place +X (.L) from the backup centerline, then create .R by exact world-X negation.
world_stations = {}
for d in digits:
    p=centerlines[d]
    world_stations[d]=[p[0], point_polyline(p,.40), point_polyline(p,.70), p[-1]]
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
inv=rig.matrix_world.inverted()
for d in digits:
    for s in sides:
        pts=[]
        for p in world_stations[d]:
            q=p.copy()
            if s=='R': q.x=-q.x
            pts.append(inv @ q)
        for j in range(1,4):
            eb=rig.data.edit_bones[f'{d}.{j:02d}.{s}']
            eb.head=pts[j-1]; eb.tail=pts[j]; eb.roll=0.0
            eb.use_connect=(j>1)
            eb.parent=rig.data.edit_bones[f'{d}.{j-1:02d}.{s}'] if j>1 else rig.data.edit_bones[f'Hand.{s}']
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()

movement={}
for d in digits:
    for s in sides:
        for j in range(1,4):
            b=rig.data.bones[f'{d}.{j:02d}.{s}']
            movement[b.name]={'old':old[b.name], 'new':{'head_mm':mm(rig.matrix_world @ b.head_local), 'tail_mm':mm(rig.matrix_world @ b.tail_local)}}

# Report a sampled maximum from each bone segment to its digit centroid polyline.
fit={}
for d in digits:
    poly=centerlines[d]
    for s in sides:
        mirrored=[]
        for p in poly:
            q=p.copy()
            if s=='R':q.x=-q.x
            mirrored.append(q)
        for j in range(1,4):
            b=rig.data.bones[f'{d}.{j:02d}.{s}']; a=rig.matrix_world@b.head_local; z=rig.matrix_world@b.tail_local
            samples=[a+(z-a)*(k/100) for k in range(101)]
            worst=max(min(segdist(p,x,y) for x,y in zip(mirrored,mirrored[1:])) for p in samples)
            fit[b.name]={'max_segment_to_centroid_polyline_mm':round(worst*1000,6)}

world=[mesh.matrix_world @ v.co for v in mesh.data.vertices]
deform=[b for b in rig.data.bones if b.use_deform]
segments=[(b.name,rig.matrix_world@b.head_local,rig.matrix_world@b.tail_local) for b in deform]
hand_boxes={}
for s in sides:
    names=[f'Hand.{s}']+[f'{d}.{n:02d}.{s}' for d in digits for n in range(1,4)]
    pts=[]
    for n in names:
        b=rig.data.bones[n]; pts += [rig.matrix_world@b.head_local,rig.matrix_world@b.tail_local]
    hand_boxes[s]=(Vector(tuple(min(p[k] for p in pts)-.025 for k in range(3))), Vector(tuple(max(p[k] for p in pts)+.025 for k in range(3))))
sets={(d,s):set() for d in digits for s in sides}
digit_names={(d,s):{f'{d}.{n:02d}.{s}' for n in range(1,4)} for d in digits for s in sides}
for i,p in enumerate(world):
    name,dist=min(((n,segdist(p,a,b)) for n,a,b in segments),key=lambda x:x[1])
    for d in digits:
        for s in sides:
            lo,hi=hand_boxes[s]
            if name in digit_names[d,s] and dist < .015 and all(lo[k]<=p[k]<=hi[k] for k in range(3)):
                sets[d,s].add(i)
adj=[set() for _ in mesh.data.vertices]
for e in mesh.data.edges:
    a,b=e.vertices;adj[a].add(b);adj[b].add(a)
def components(ids):
    left=set(ids);out=[]
    while left:
        q=[left.pop()];n=0
        while q:
            u=q.pop();n+=1
            take=adj[u]&left;left-=take;q.extend(take)
        out.append(n)
    return sorted(out,reverse=True)

diag={'source':os.path.basename(SRC),'finger_bone_movement':movement,'finger_bone_centerline_fit':fit,'digit_sets':{},'hand_bboxes_mm':{}}
for s in sides:
    lo,hi=hand_boxes[s];diag['hand_bboxes_mm'][s]={'min':mm(lo),'max':mm(hi)}
for d in digits:
    for s in sides:
        ids=sets[d,s]; vals=[world[i] for i in ids]; lo,hi=hand_boxes[s]
        diag['digit_sets'][f'{d}.{s}']={'count':len(ids),'components':components(ids),'outside_hand_bbox':[i for i in ids if not all(lo[k]<=world[i][k]<=hi[k] for k in range(3))],
          'bbox_mm':None if not vals else {'min':[round(min(p[k] for p in vals)*1000,3) for k in range(3)],'max':[round(max(p[k] for p in vals)*1000,3) for k in range(3)]}}
def expected_count(key, count):
    # The supplied topology defines thumbs as 6x8 rings + one tip (49), while
    # the other digits have 9x8 rings + one tip and include a few root verts.
    return (45 <= count <= 55) if key.startswith('Thumb.') else (65 <= count <= 85)
bad=[k for k,v in diag['digit_sets'].items() if v['outside_hand_bbox'] or not expected_count(k,v['count']) or v['components'] != [v['count']]]
if bad:
    diag['status']='STOP';diag['bad_digit_sets']=bad
    json.dump(diag,open(REPORT,'w'),indent=2)
    raise RuntimeError('Bad geometric digit sets after bone reposition: '+repr(bad))

# Eye anatomical-name swap.
def swap_names(a,b,collection):
    tmp='__R18_SWAP_TMP__';collection[a].name=tmp;collection[b].name=a;collection[tmp].name=b
eye_world={n:bpy.data.objects[n].matrix_world.copy() for n in ('Fool_Eye_L','Fool_Eye_R')}
bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT');swap_names('Eye.L','Eye.R',rig.data.edit_bones);bpy.ops.object.mode_set(mode='OBJECT')
swap_names('Fool_Eye_L','Fool_Eye_R',bpy.data.objects)
for s in sides:
    eye=bpy.data.objects['Fool_Eye_'+s];eye.parent=rig;eye.parent_type='BONE';eye.parent_bone='Eye.'+s;eye.matrix_world=eye_world['Fool_Eye_'+('R' if s=='L' else 'L')]

# Remove matching finger-chain bleed outside each correct tube.
for d in digits:
    for s in sides:
        allowed=sets[d,s]
        for n in range(1,4):
            g=mesh.vertex_groups.get(f'{d}.{n:02d}.{s}')
            if g:
                carried=[v.index for v in mesh.data.vertices if v.index not in allowed and any(x.group==g.index for x in v.groups)]
                if carried:g.remove(carried)

# Rebuild each tube with two-nearest 1/d^4 phalange weights and root Hand blend.
for d in digits:
    for s in sides:
        bones=[rig.data.bones[f'{d}.{n:02d}.{s}'] for n in range(1,4)]; groups=[mesh.vertex_groups[b.name] for b in bones]
        hg=mesh.vertex_groups.get(f'Hand.{s}');root=rig.matrix_world@bones[0].head_local
        for i in sets[d,s]:
            for g in groups:g.remove([i])
            ds=[segdist(world[i],rig.matrix_world@b.head_local,rig.matrix_world@b.tail_local) for b in bones]
            order=sorted(range(3),key=lambda j:ds[j])[:2];raw=[1/max(ds[j],.002)**4 for j in order];total=sum(raw)
            rb=.5 if (world[i]-root).length<=.005 else 0.0
            for j,w in zip(order,raw):groups[j].add([i],(1-rb)*w/total,'REPLACE')
            if hg and rb:hg.add([i],rb,'REPLACE')
for v in mesh.data.vertices:
    entries=[(x.group,x.weight) for x in v.groups if x.weight>0];total=sum(w for _,w in entries)
    if total:
        for gi,w in entries:mesh.vertex_groups[gi].add([v.index],w/total,'REPLACE')
diag['eye_swap']={}
for s in sides:
    b=rig.data.bones['Eye.'+s];eye=bpy.data.objects['Fool_Eye_'+s]
    diag['eye_swap'][s]={'bone_head_mm':mm(rig.matrix_world@b.head_local),'globe_world_mm':mm(eye.matrix_world.translation),'parent_bone':eye.parent_bone,'deform':b.use_deform}
diag['status']='PASS'
bpy.context.scene['r18_weight_fix']='023e: repositioned phalanges; geometric 15mm digit sets; restricted 1/d^4 weights'
json.dump(diag,open(REPORT,'w'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print(json.dumps({'status':diag['status'],'digit_sets':diag['digit_sets'],'fit':fit,'eye_swap':diag['eye_swap']},indent=2));print('SAVED',OUT)
