"""Headless shaded and wire-over-shaded body inspection rig.
Usage: blender --background --factory-startup --python render_body.py -- BLEND [OBJECT] [OUTDIR] [TAG]
"""
import bpy,math,os,sys,shutil
from mathutils import Vector
av=sys.argv[sys.argv.index('--')+1:]
path=av[0]; name=av[1] if len(av)>1 else 'Fool_BodyRetopo'; outdir=av[2] if len(av)>2 else os.path.join(os.path.dirname(__file__),'renders');tag=av[3] if len(av)>3 else 'a'; selected=av[4].split(',') if len(av)>4 else None; variants=av[5].split(',') if len(av)>5 else ['shaded','wire']
os.makedirs(outdir,exist_ok=True)
with bpy.data.libraries.load(path,link=False) as (src,dst):dst.objects=[name]
if not dst.objects or not dst.objects[0]:raise RuntimeError('%s absent'%name)
obj=dst.objects[0];bpy.context.scene.collection.objects.link(obj);obj.hide_render=False;obj.hide_viewport=False;obj.hide_set(False)
if len(obj.data.vertices)>300000:
 bpy.context.view_layer.objects.active=obj;obj.select_set(True)
 mod=obj.modifiers.new('R16_RenderOnly_Decimate','DECIMATE');mod.ratio=.06
 bpy.ops.object.modifier_apply(modifier=mod.name)
 print('RENDER_ONLY_DECIMATED',len(obj.data.vertices))
for o in list(bpy.context.scene.objects):
 if o!=obj and o.type=='MESH':o.hide_render=True
scene=bpy.context.scene;cam=bpy.data.cameras.new('R16_CAM');camera=bpy.data.objects.new('R16_CAM',cam);scene.collection.objects.link(camera);scene.camera=camera
cam.type='ORTHO';scene.render.engine='BLENDER_WORKBENCH';scene.render.resolution_x=700;scene.render.resolution_y=630;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
d=scene.display.shading;d.light='STUDIO';d.show_shadows=True;d.show_cavity=True;d.cavity_type='WORLD';d.show_specular_highlight=False;d.color_type='SINGLE';d.single_color=(.62,.62,.62)
views={
 'front':((0,-4,.86),(0,0,.86),2.05),'back':((0,4,.86),(0,0,.86),2.05),'side':((4,0,.86),(0,0,.86),2.05),'three-quarter':((2.83,-2.83,.86),(0,0,.86),2.05),
 'hand-top':((.76,0,2.2),(.76,0,1.28),.42),'foot':((.13,-1.0,.16),(.13,0,.16),.42),'shoulder':((.36,-1.2,1.23),(.36,0,1.23),.42),
 'knee':((.12,-1.2,.50),(.12,0,.50),.42),'neck-seam':((0,-1.0,1.442),(0,0,1.442),.30)}
for vn,(loc,aim,scale) in views.items():
 if selected and vn not in selected:continue
 camera.location=loc;camera.rotation_euler=(Vector(aim)-camera.location).to_track_quat('-Z','Y').to_euler();cam.ortho_scale=scale
 for wire in ([False] if variants==['shaded'] else [True] if variants==['wire'] else [False,True]):
  obj.show_wire=wire;obj.show_all_edges=wire
  scene.render.filepath=os.path.join(outdir,f'{tag}-{vn}-'+('wire' if wire else 'shaded')+'.png')
  bpy.ops.render.render(write_still=True);print('WROTE',scene.render.filepath)
  if vn=='foot' and not wire:
   evidence=os.path.join(outdir,f'{tag}-foot-top.png');shutil.copyfile(scene.render.filepath,evidence);print('WROTE',evidence)
print('RENDER_BODY_DONE')
