import bpy, json, math, os, sys
from mathutils import Vector, Quaternion
from mathutils.bvhtree import BVHTree

PATH, OUTDIR, OUTJSON = sys.argv[sys.argv.index('--')+1:]
os.makedirs(OUTDIR,exist_ok=True); bpy.ops.wm.open_mainfile(filepath=PATH)
scene=bpy.context.scene; rig=bpy.data.objects['FoolRig']; mesh=bpy.data.objects['Fool_Mesh']
keep={'Fool_Mesh','Fool_Eye_L','Fool_Eye_R'}
for o in scene.objects:o.hide_render=(o.name not in keep)
camdat=bpy.data.cameras.new('R18_Camera'); cam=bpy.data.objects.new('R18_Camera',camdat); scene.collection.objects.link(cam); scene.camera=cam
camdat.type='ORTHO'; scene.render.engine='BLENDER_WORKBENCH'; scene.render.resolution_x=1024; scene.render.resolution_y=1024; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=False
sh=scene.display.shading; sh.light='STUDIO'; sh.show_shadows=True; sh.show_cavity=True; sh.cavity_type='WORLD'; sh.show_specular_highlight=False; sh.color_type='SINGLE'; sh.single_color=(.62,.62,.62)

def reset():
    for p in rig.pose.bones: p.rotation_mode='QUATERNION'; p.rotation_quaternion=(1,0,0,0); p.location=(0,0,0); p.scale=(1,1,1)
    bpy.context.view_layer.update()
def rotate_world(pb,axis,angle):
    qrest=pb.bone.matrix_local.to_quaternion(); pb.rotation_mode='QUATERNION'
    pb.rotation_quaternion=qrest.inverted() @ Quaternion(Vector(axis),angle) @ qrest
def render(name,loc,aim,scale):
    cam.location=loc; cam.rotation_euler=(Vector(aim)-cam.location).to_track_quat('-Z','Y').to_euler(); camdat.ortho_scale=scale
    scene.render.filepath=os.path.join(OUTDIR,name); bpy.ops.render.render(write_still=True); print('WROTE',scene.render.filepath)
def coords():
    dg=bpy.context.evaluated_depsgraph_get(); ev=mesh.evaluated_get(dg); me=ev.to_mesh(); out=[ev.matrix_world@v.co for v in me.vertices]; ev.to_mesh_clear(); return out
def ring_area(ids,points):
    if len(ids)<3:return 0
    c0=sum((base[i] for i in ids),Vector())/len(ids)
    order=sorted(ids,key=lambda i:math.atan2(base[i].z-c0.z,base[i].y-c0.y))
    c=sum((points[i] for i in order),Vector())/len(order); av=Vector()
    for j,i in enumerate(order): av+=(points[i]-c).cross(points[order[(j+1)%len(order)]]-c)
    return .5*av.length
base=[mesh.matrix_world@v.co for v in mesh.data.vertices]
rings={x:{s:[i for i,p in enumerate(base) if abs(p.x-s*x)<.004 and 1.22<p.z<1.46] for s in (1,-1)} for x in (.225,.289)}
rest_area={x:sum(ring_area(ids,base) for ids in rings[x].values())/2 for x in rings}
metrics={'render_whitelist':sorted(keep),'shoulder':{},'fingers':{},'eyes':{},'neck':{},'limbs':{},'smear_guard':{}}
def smear(label,points,mode,joints=(),angle=0,multiplier=1):
    bad=[]
    for i,(p,q) in enumerate(zip(base,points)):
        disp=(q-p).length
        if mode=='static':allowed=.020
        else:
            r=min((p-j).length for j in joints)
            allowed=multiplier*2*r*math.sin(abs(angle)/2)+.020
        if disp>allowed:bad.append({'vertex':i,'displacement_mm':round(disp*1000,3),'allowed_mm':round(allowed*1000,3)})
    metrics['smear_guard'][label]={'flagged_count':len(bad),'worst':bad[:20]}

for ang in (45,80):
    reset(); rotate_world(rig.pose.bones['UpperArm.L'],(0,1,0),math.radians(ang)); rotate_world(rig.pose.bones['UpperArm.R'],(0,1,0),-math.radians(ang)); bpy.context.view_layer.update()
    co=coords(); metrics['shoulder'][str(ang)]={}
    for x in rings:
        area=sum(ring_area(ids,co) for ids in rings[x].values())/2
        metrics['shoulder'][str(ang)][f'x{x:.3f}']={'rest_ring_area_mm2':rest_area[x]*1e6,'posed_ring_area_mm2':area*1e6,'area_loss_percent':100*(rest_area[x]-area)/rest_area[x] if rest_area[x] else None,'ring_vertex_count':sum(map(len,rings[x].values()))}
    joints=[rig.matrix_world@rig.data.bones[f'UpperArm.{s}'].head_local for s in ('L','R')];smear(f'shoulder_{ang}',co,'joint',joints,math.radians(ang))
    render(f'a{ang}-front.png',(0,-4,.95),(0,0,.95),1.95); render(f'a{ang}-back.png',(0,4,.95),(0,0,.95),1.95); render(f'a{ang}-tq.png',(2.8,-2.8,.95),(0,0,.95),1.95);render(f'a{ang}-shoulder-zoom.png',(1.2,-1.6,1.30),(.19,0,1.32),.55)

reset()
for side in ('L','R'):
    sign=1 if side=='L' else -1
    for d in ('Thumb','Index','Middle','Ring','Pinky'):
        for n in range(1,4): rotate_world(rig.pose.bones[f'{d}.{n:02d}.{side}'],(0,1,0),sign*math.radians(60))
bpy.context.view_layer.update();finger_joints=[rig.matrix_world@rig.data.bones[f'{d}.01.{s}'].head_local for s in ('L','R') for d in ('Thumb','Index','Middle','Ring','Pinky')];smear('fingers_60x3',coords(),'joint',finger_joints,math.radians(60),3); render('fingers-top.png',(.76,0,2.2),(.76,0,1.29),.40); render('fingers-palm-tq.png',(1.25,-1.4,1.8),(.76,0,1.29),.40);render('fingers-front.png',(.76,-1.5,1.29),(.76,0,1.29),.40)
metrics['fingers']['curl_degrees_each_hinge']=60

def eye_clearance():
    dg=bpy.context.evaluated_depsgraph_get(); mev=mesh.evaluated_get(dg); mme=mev.to_mesh(); mco=[mev.matrix_world@v.co for v in mme.vertices]; polys=[list(p.vertices) for p in mme.polygons]; bvh=BVHTree.FromPolygons(mco,polys,all_triangles=False)
    vals=[]
    for side in ('L','R'):
        ob=bpy.data.objects['Fool_Eye_'+side].evaluated_get(dg); em=ob.to_mesh()
        for v in em.vertices:
            p=ob.matrix_world@v.co; q=bvh.find_nearest(p)
            if q[0] is not None: vals.append((p-q[0]).length)
        ob.to_mesh_clear()
    mev.to_mesh_clear(); return min(vals)*1000 if vals else None
for name,axis,deg in [('left','z',20),('right','z',-20),('up','x',-20),('down','x',20)]:
    reset()
    avec={'x':(1,0,0),'z':(0,0,1)}[axis]
    for side in ('L','R'): rotate_world(rig.pose.bones['Eye.'+side],avec,math.radians(deg))
    bpy.context.view_layer.update(); metrics['eyes'][name]={'minimum_surface_clearance_mm':eye_clearance()};smear('eyes_'+name,coords(),'static')
    render('eyes-'+name+'.png',(0,-2.2,1.57),(0,-.02,1.57),.42)

for name,deg,axis in [('down',-30,'x'),('up',20,'x'),('turn',45,'z')]:
    reset(); avec={'x':(1,0,0),'z':(0,0,1)}[axis]; rotate_world(rig.pose.bones['Neck'],avec,math.radians(deg*.4)); rotate_world(rig.pose.bones['Head'],avec,math.radians(deg*.6)); bpy.context.view_layer.update()
    c=coords();joints=[rig.matrix_world@rig.data.bones[x].head_local for x in ('Neck','Head')];smear('neck_'+name,c,'joint',joints,math.radians(abs(deg)),2);render('neck-'+name+'.png',(1.4,-2.1,1.5),(0,0,1.47),.68); metrics['neck'][name]={'total_degrees':deg}
for name,bn,axis,deg,loc,aim,scale in [
 ('elbow90','LowerArm.L','y',90,(1.8,-2.6,1.25),(.48,0,1.25),.85),
 ('knee90','LowerLeg.L','x',-90,(1.4,-2.2,.48),(.12,0,.48),.85),
 ('hip45','UpperLeg.L','x',-45,(1.5,-2.6,.70),(.1,0,.70),1.25)]:
    reset(); avec={'x':(1,0,0),'y':(0,1,0)}[axis]; rotate_world(rig.pose.bones[bn],avec,math.radians(deg)); bpy.context.view_layer.update();c=coords();joint=rig.matrix_world@rig.data.bones[bn].head_local;smear(name,c,'joint',[joint],math.radians(abs(deg))); render(name+'.png',loc,aim,scale); metrics['limbs'][name]={'bone':bn,'degrees':deg}
reset(); json.dump(metrics,open(OUTJSON,'w'),indent=2); print(json.dumps(metrics,indent=2))
