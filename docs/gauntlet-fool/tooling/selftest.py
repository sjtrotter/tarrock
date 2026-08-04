import bpy, os, sys, numpy as np
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
import fieldlib as F
obj=bpy.data.objects['Fool_SculptBase']; n=len(obj.data.vertices)
v=np.empty(n*3,np.float32); obj.data.vertices.foreach_get('co',v); v=v.reshape(-1,3)
e=np.empty(len(obj.data.edges)*2,np.int32); obj.data.edges.foreach_get('vertices',e); e=e.reshape(-1,2)
h0=F.vertex_hash(v); print('SELFTEST loaded verts=%d edges=%d hash=%s'%(n,len(e),h0))
# C1 cutoff from inside and outside
r=0.1; eps=np.array([1e-2,1e-3,1e-4,1e-5])*r
grad=F.c1_falloff(r-eps,r)/eps
print('C1 cutoff numerical_gradients',grad.tolist(),'last',float(grad[-1]))
p=np.array([[-.04,0,0],[.04,0,0]],float); a=F.aradius(p,[0,0,0],[1,0,0],.05,.12,.04)
print('teardrop weights tight=%.8g tail=%.8g ratio=%.8g'%(a[0],a[1],a[1]/a[0]))
# Conservative blur centroid test on coordinate copy; few iterations is enough to prove invariant
sample=np.linspace(-1,1,n,dtype=np.float64); bs,sig=F.graph_gaussian(sample,e,3,.4,v,verbose=True)
print('blur mean_shift=%.12g'%abs(bs.mean()-sample.mean()))
center=np.array([.18,-.10,1.18]); raw=lambda gain: gain*F.symmetric_field(v,center,F.radial,radius=.08,fpow=1.5)
out,cal=F.calibrated_amplitude(raw,e,target_peak=.002,iterations=4,alpha=.4,vertices=v)
print('amplitude converged=%s achieved=%.9g target=.002 error_pct=%.4f'%(cal['converged'],cal['peak'],100*abs(cal['peak']-.002)/.002))
# synthetic terrace test
z=np.linspace(0,1,4096); phi=np.mod(np.arange(4096)*2.399963,2*np.pi); rr=.2+.01*z+.002*np.round(z*24)/24
corr,tm=F.terrace_fix(z,phi,rr,nz=128,nphi=32,sigma_z_bins=2.5)
print('terrace reduced=%s before=%.9g after=%.9g'%(tm['after']<tm['before'],tm['before'],tm['after']))
st=F.silhouette_stations(v); F.save_json(os.path.join(HERE,'stations_base.json'),st)
shoulder=[q for q in st['regions']['torso'] if 1.30<=q['z']<=1.48]
print('silhouette crown=%.9g sole=%.9g shoulder_max_half_width=%.9g'%(st['z_max'],st['z_min'],max(q['x_half'] for q in shoulder)))
v2=np.empty(n*3,np.float32); obj.data.vertices.foreach_get('co',v2); h1=F.vertex_hash(v2.reshape(-1,3))
print('IMMUTABLE hash_after=%s identical=%s'%(h1,h0==h1))
assert h0==h1
