"""Headless flat-light renders and high-pass regional RMS metric for R13."""
import bpy, json, math, os
import numpy as np
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
HERE=os.path.dirname(os.path.abspath(__file__)); OUT=os.path.abspath(os.path.join(HERE,'..','renders')); os.makedirs(OUT,exist_ok=True)
scene=bpy.context.scene; obj=bpy.data.objects['Fool_SculptBase']; cam=bpy.data.objects['R5_CAM']; scene.camera=cam
scene.render.engine='BLENDER_WORKBENCH'; scene.render.resolution_x=1400; scene.render.resolution_y=800; scene.render.resolution_percentage=100
cam.data.type='ORTHO'; cam.data.ortho_scale=3.20
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=False
scene.display.shading.light='STUDIO'; scene.display.shading.show_shadows=True; scene.display.shading.show_cavity=False
scene.display.shading.show_specular_highlight=False; scene.display.shading.color_type='SINGLE'; scene.display.shading.single_color=(.62,.62,.62)
try: scene.display.shading.studio_light='paint.sl'
except: pass
SIGMA=6.0
anchors={
 'upper_arm':{'view':'front','p':(.42,-.08,1.315),'radius_m':(.015,.012)},
 'abdomen':{'view':'front','p':(.020,-.11,1.120),'radius_m':(.035,.035)},
 'costal':{'view':'front','p':(.14,-.12,1.140),'radius_m':(.040,.025)},
 'clavicle':{'view':'front','p':(.115,-.13,1.375),'radius_m':(.060,.030)},
 'psis':{'view':'back','p':(.075,.12,.985),'radius_m':(.080,.040)},
 'belt':{'view':'back','p':(.125,.12,1.055),'radius_m':(.040,.040)},
}
def aim_camera(location):
    cam.location=location; cam.rotation_euler=(Vector((0,0,.88))-cam.location).to_track_quat('-Z','Y').to_euler()
def render(view):
    # Preserve R5 framing scale; only put camera on the requested side.
    dist=max(4.0,abs(cam.location.y)); aim_camera(Vector((0,-dist if view=='front' else dist,.88)))
    scene.render.filepath=os.path.join(OUT,'r13base-%s-flat.png'%view)
    if not (os.environ.get('R13_REUSE_RENDER')=='1' and os.path.exists(scene.render.filepath)):
        bpy.ops.render.render(write_still=True)
    rr=bpy.data.images.load(scene.render.filepath,check_existing=False); a=np.empty(len(rr.pixels),np.float32); rr.pixels.foreach_get(a)
    # Blender image buffers are bottom-up; projection coordinates below are top-down.
    return a.reshape(scene.render.resolution_y,scene.render.resolution_x,4)[::-1,:,:3].copy()
def kernel(sig):
    rad=int(math.ceil(4*sig)); x=np.arange(-rad,rad+1); k=np.exp(-.5*(x/sig)**2); return k/k.sum()
def blur(a,sig):
    k=kernel(sig); p=len(k)//2
    x=np.pad(a,((0,0),(p,p)),mode='reflect'); x=np.apply_along_axis(lambda q:np.convolve(q,k,'valid'),1,x)
    x=np.pad(x,((p,p),(0,0)),mode='reflect'); return np.apply_along_axis(lambda q:np.convolve(q,k,'valid'),0,x)
def projected_mask(name,view):
    q=anchors[name]; ndc=world_to_camera_view(scene,cam,Vector(q['p'])); cx=ndc.x*scene.render.resolution_x; cy=(1-ndc.y)*scene.render.resolution_y
    # ortho projection scale: vertical pixels/metre; horizontal is identical.
    # Blender's camera scale spans the horizontal axis for this wide render.
    ppm=scene.render.resolution_x/cam.data.ortho_scale; rx=q['radius_m'][0]*ppm; ry=q['radius_m'][1]*ppm
    yy,xx=np.ogrid[:scene.render.resolution_y,:scene.render.resolution_x]
    m=((xx-cx)/rx)**2+((yy-cy)/ry)**2<=1
    return m,{'center_px':[float(cx),float(cy)],'radius_px':[float(rx),float(ry)],'anchor_world':q['p']}
images={}; metrics={}; masks={}
for view in ('front','back'):
    images[view]=render(view)
    lum=.2126*images[view][:,:,0]+.7152*images[view][:,:,1]+.0722*images[view][:,:,2]
    hp=lum-blur(lum,SIGMA)
    for name,q in anchors.items():
        if q['view']!=view: continue
        m,meta=projected_mask(name,view); val=float(np.sqrt(np.mean(hp[m]**2))*255)
        metrics[name]=val; masks[name]=meta; print('RMS %s %.8g n=%d anchor_px=%s'%(name,val,m.sum(),meta['center_px']))
order=sorted(metrics,key=metrics.get)
expected=['upper_arm','abdomen','psis','clavicle','belt','costal']
result={'settings':{'engine':'BLENDER_WORKBENCH','resolution':[1400,800],'light':'STUDIO/paint.sl single-color, shadows on, cavity/specular off','sigma_px':SIGMA,'camera':'R5_CAM; same ortho_scale, aimed front/back at z=.88'},'anchors':masks,'metrics_rms_8bit':metrics,'ordering':order,'expected_ordering':expected,'ordering_pass':order==expected}
with open(os.path.join(HERE,'rms_base.json'),'w') as f: json.dump(result,f,indent=2)
print('RMS_ORDER '+' < '.join('%s=%.4f'%(x,metrics[x]) for x in order)); print('ORDERING_PASS',order==expected)
