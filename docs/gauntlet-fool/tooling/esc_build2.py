import sys, json, numpy as np
sys.path.insert(0,'/home/betty/tarrock-gauntlet-work/r13/tooling')
import esclib as E, fieldlib as F
W='/home/betty/tarrock-gauntlet-work/r13/work'
V=np.load(f'{W}/v_base.npy'); N=np.load(f'{W}/n_base.npy'); ED=np.load(f'{W}/edges.npy')
n=len(V); AX=np.abs(V[:,0]); Z=V[:,2]
MAXD=int(np.bincount(ED.ravel(),minlength=n).max())
MEL2=float(np.mean(np.sum((V[ED[:,0]]-V[ED[:,1]])**2,axis=1)))
Ns=np.stack([E.graph_gaussian(N[:,k],ED,6,.45,MAXD,MEL2)[0] for k in range(3)],axis=1)
Ns/=np.maximum(1e-12,np.linalg.norm(Ns,axis=1))[:,None]
f=np.zeros(n); REP={}
def facing(d,lo=0.05,hi=0.55): return E.smoothstep((Ns@np.asarray(d,float)-lo)/(hi-lo))
def surf(mask_side, x0, zs, hw=0.006, pct=95):
    m=mask_side&(np.abs(AX-x0)<hw); P=V[m]; ys=np.full(len(zs),np.nan)
    for i,z in enumerate(zs):
        q=P[np.abs(P[:,2]-z)<0.001]
        if len(q)>3: ys[i]=np.percentile(q[:,1],pct)
    g=np.isfinite(ys); return E.gsm(np.interp(np.arange(len(zs)),np.flatnonzero(g),ys[g]),3.0)
def ctrap(y,dx): return np.concatenate([[0.],np.cumsum(.5*(y[1:]+y[:-1]))*dx])

# ======================= T4v2  BELT: differentiate the profile across X =======
# The belt is a 44 deg turn spread over ~90 mm whose position is IDENTICAL at
# every x (1.052-1.072). Horizontality, not sharpness, is the garment cue.
# Fix: redistribute the SAME total turn per x - early+broad at the midline
# (sacral triangle), lower+tighter laterally (gluteal mass behind the crest).
z0,z1=0.995,1.135; dzs=0.001
zg=np.arange(0.94,1.21,dzs); xg=np.arange(0.0,0.125,0.005)
back=(V[:,1]>0)
j0=int(np.argmin(np.abs(zg-z0))); j1=int(np.argmin(np.abs(zg-z1)))
CORR=np.zeros((len(xg),len(zg))); cent_b=[]; cent_a=[]
for i,x in enumerate(xg):
    y=surf(back,x,zg,pct=95)
    kap=E.gsm(np.gradient(np.gradient(y,dzs),dzs),6.0)
    seg=slice(j0,j1+1); zz=zg[seg]; k=kap[seg]
    tot=np.trapezoid(k,zz)
    c=1.040+0.040*E.smoothstep(x/0.095); w=0.090-0.038*E.smoothstep(x/0.095)
    kt=np.exp(-0.5*((zz-c)/(w/4.0))**2); kt*=tot/np.trapezoid(kt,zz)
    dk=kt-k
    ds=ctrap(dk,dzs); ds-=ds[-1]*E.smoothstep((zz-z0)/(z1-z0))
    dy=ctrap(ds,dzs); dy-=dy[-1]*E.smoothstep((zz-z0)/(z1-z0))
    CORR[i,seg]=dy
    cent_b.append(np.trapezoid(k*zz,zz)/tot); cent_a.append(c)
CORR=np.apply_along_axis(lambda c:E.gsm(c,2.0),0,CORR)   # smooth across X: kill station scallops
# Convert the outward-push component into an inward carve: subtract the per-z
# maximum over x. The RELATIVE differentiation across the back (the whole point)
# is preserved, but the back-most x is now the reference and barely moves, so the
# y_max silhouette station stops capping the dose. Physically this deepens the
# spinal furrow / flattens the sacral triangle - the brief's own prescription for
# interrupting the crest line at the spine.
CORR=CORR-np.max(CORR,axis=0,keepdims=True)
RAW=np.abs(CORR).max()
GAIN=min(1.0, 0.0095/max(RAW,1e-9))
CORR*=GAIN
print("T4v2 belt: raw max %.2f mm -> gain %.3f -> applied max %.3f mm"%(1000*RAW,GAIN,1000*np.abs(CORR).max()))
print("   turn centroid  base: %.4f..%.4f   target: %.4f..%.4f  (x=0 -> x=0.12)"%(
    cent_b[0],cent_b[-1],cent_a[0],cent_a[-1]))
REP['belt_gain']=float(GAIN); REP['belt_applied_max_mm']=float(1000*np.abs(CORR).max())
REP['belt_centroid_base']=[float(cent_b[0]),float(cent_b[-1])]
REP['belt_centroid_target']=[float(cent_a[0]),float(cent_a[-1])]
dy=E.bilinear(CORR,xg,zg,np.clip(AX,0,xg[-1]-1e-6),np.clip(Z,zg[0],zg[-1]-1e-6))
f+=dy*(1.0-E.smoothstep((AX-0.100)/0.080))*facing((0,1,0),0.10,0.60)*back

# ======================= F1  front horizontal band at z~1.264 (2nd garment line)
front=(V[:,1]<0)
zf=np.arange(1.08,1.34,dzs); xs2=np.arange(0.0,0.135,0.0075)
zb=[]
for x in xs2:
    y=surf(front,x,zf,pct=5)
    kap=E.gsm(np.gradient(np.gradient(y,dzs),dzs),5.0)
    w=(zf>1.230)&(zf<1.300); zb.append(zf[w][int(np.argmax(kap[w]))])
print("F1 front band z(x):"," ".join("%.3f"%q for q in zb))
REP['front_band_z']=[float(q) for q in zb]
fb0,fb1=1.205,1.325; k0=int(np.argmin(np.abs(zf-fb0))); k1=int(np.argmin(np.abs(zf-fb1)))
DEC=np.zeros((len(xs2),len(zf)))
for i,x in enumerate(xs2):
    y=surf(front,x,zf,pct=5)
    kap=E.gsm(np.gradient(np.gradient(y,dzs),dzs),6.0)
    seg=slice(k0,k1+1); zz=zf[seg]; k=kap[seg]; tot=np.trapezoid(k,zz)
    c=1.256+0.022*E.smoothstep(x/0.090); w=0.086-0.026*E.smoothstep(x/0.090)
    kt=np.exp(-0.5*((zz-c)/(w/4.0))**2); kt*=tot/np.trapezoid(kt,zz)
    ds=ctrap(kt-k,dzs); ds-=ds[-1]*E.smoothstep((zz-fb0)/(fb1-fb0))
    dd=ctrap(ds,dzs); dd-=dd[-1]*E.smoothstep((zz-fb0)/(fb1-fb0))
    DEC[i,seg]=dd
DEC=np.apply_along_axis(lambda c:E.gsm(c,2.0),0,DEC)
RAWF=np.abs(DEC).max(); GF=min(1.0,0.0030/max(RAWF,1e-9)); DEC*=GF
print("F1 front band: raw %.2f mm -> gain %.3f -> applied %.3f mm"%(1000*RAWF,GF,1000*np.abs(DEC).max()))
REP['front_band_gain']=float(GF); REP['front_band_applied_mm']=float(1000*np.abs(DEC).max())
# ======================= T1v2  COSTAL chevron: rounded apex, two-panel tilt ===
zA=1.240-0.78*(np.sqrt(np.minimum(AX,0.115)**2+0.030**2)-0.030)
u=Z-zA
segs=[(-0.190,-0.060,-0.0392),(-0.060,0.0,0.0850),(0.0,0.048,-0.0080),(0.048,0.140,0.0042)]
d1,(g,s,_)=E.slope_profile(u,segs,crease=0.045)
print("T1v2 panel  :",E.check_visibility(g,s,label='costal'))
d1=np.where(d1<0,d1*(1.0-0.45*np.exp(-(AX/0.022)**2)),d1)   # linea alba stays proud
xedge=0.088+0.040*E.taper(Z,1.02,1.21)
fT1=d1*(1.0-E.smoothstep((AX-(xedge-0.010))/0.075))*(1.0-E.taper(Z,1.245,1.335))*facing((0,-1,0))
f+=fT1; REP['T1_costal_pp_mm']=float((fT1.max()-fT1.min())*1000)
xf=AX-xedge
d2,_=E.slope_profile(xf,[(0.0,0.040,-0.0520),(0.040,0.135,0.02189)],crease=0.024)
fT2=d2*E.taper(Z,1.010,1.055)*(1.0-E.taper(Z,1.190,1.265))*np.clip(facing((0,-1,0),-0.15,0.45),0,1)
f+=fT2; REP['T2_flank_pp_mm']=float((fT2.max()-fT2.min())*1000)

# ======================= ARM =================================================
arm=(AX>0.245)&(Z>1.20)&(Z<1.45)
xa=np.arange(0.25,0.72,0.005); cy=np.full(len(xa),np.nan); cz=np.full(len(xa),np.nan)
for i,x in enumerate(xa):
    q=V[arm&(np.abs(AX-x)<0.004)]
    if len(q)>40: cy[i]=q[:,1].mean(); cz[i]=q[:,2].mean()
for a in (cy,cz):
    g_=np.isfinite(a); a[:]=np.interp(np.arange(len(xa)),np.flatnonzero(g_),a[g_])
cy=E.gsm(cy,4.0); cz=E.gsm(cz,4.0)
t=np.clip(AX,xa[0],xa[-1]); ay=np.interp(t,xa,cy); az=np.interp(t,xa,cz)
dY=V[:,1]-ay; dZ=Z-az; rad=np.hypot(dY,dZ); phi=np.arctan2(dZ,-dY)
pdeg=np.degrees(np.abs(((phi+np.pi)%(2*np.pi))-np.pi))
armw=E.taper(AX,0.250,0.300)*(1.0-E.taper(AX,0.640,0.690))*(rad<0.075)
def gb(cdeg,hwdeg):
    d=np.abs(((phi-np.radians(cdeg)+np.pi)%(2*np.pi))-np.pi)
    return E.smoothstep(1.0-d/np.radians(hwdeg))
def xw(a,b,c,d): return E.taper(AX,a,b)*(1.0-E.taper(AX,c,d))
ridge=np.maximum(1.0-E.smoothstep((pdeg-64.0)/18.0), E.smoothstep((pdeg-116.0)/18.0))
# A biceps/triceps intermuscular grooves (plane breaks, not bulges)
fA=-0.00220*(gb(58,24)+gb(-58,24))*xw(0.275,0.325,0.395,0.440)
# B deltoid insertion V - antero-lateral, converging distally (front-visible)
vp=40.0+20.0*(1.0-E.taper(AX,0.290,0.395))
fB=-0.00300*(E.smoothstep(1.0-np.abs(((phi-np.radians(vp)+np.pi)%(2*np.pi))-np.pi)/np.radians(23))
            +E.smoothstep(1.0-np.abs(((phi+np.radians(vp)+np.pi)%(2*np.pi))-np.pi)/np.radians(19)))*xw(0.278,0.312,0.376,0.404)
# C brachialis flat: distal upper arm recedes -> tone break along the arm
fC2=-0.00190*E.smoothstep(1.0-np.abs(phi)/np.radians(52))*xw(0.352,0.392,0.418,0.452)
# D ulnar line (forearm posterior-superior border, reads in top view)
fD=-0.00180*gb(118,24)*xw(0.480,0.530,0.615,0.660)
# E elbow triad
def blob(x0,p0,rx,rp,amp):
    dx=(AX-x0)/rx; dp=(((phi-np.radians(p0)+np.pi)%(2*np.pi))-np.pi)/np.radians(rp)
    return amp*E.smoothstep(1.0-np.sqrt(dx*dx+dp*dp))
fE=(blob(0.472,-72,0.034,34,0.00215)+blob(0.478,180,0.036,42,-0.00150)+blob(0.470,72,0.030,30,-0.00100))
# F inherited ring "seam" at x~0.40: a KINK in r(x). Spread the slope turn.
rg=np.arange(0.30,0.56,0.001); Rr=np.full(len(rg),np.nan)
for i,x in enumerate(rg):
    q=rad[arm&(np.abs(AX-x)<0.0015)]
    if len(q)>20: Rr[i]=np.median(q)
g_=np.isfinite(Rr); Rr=E.gsm(np.interp(np.arange(len(rg)),np.flatnonzero(g_),Rr[g_]),3.0)
sr=np.gradient(Rr,0.001); srt=E.gsm(sr,16.0)
win=E.smoothstep((rg-0.345)/0.030)*(1.0-E.smoothstep((rg-0.455)/0.030))
dsr=(srt-sr)*win; cr=ctrap(dsr,0.001); cr-=cr[-1]*E.smoothstep((rg-0.30)/0.26)
print("T-arm seam: r(x) slope turn %.3f -> spread; correction max %.3f mm"%(
    sr[(rg>0.38)&(rg<0.42)].max()-sr[(rg>0.38)&(rg<0.42)].min(),1000*np.abs(cr).max()))
REP['arm_seam_corr_mm']=float(1000*np.abs(cr).max())
fF=np.interp(np.clip(AX,rg[0],rg[-1]),rg,cr)*((AX>0.33)&(AX<0.47))
fG=0.00175*E.smoothstep(1.0-np.abs(phi)/np.radians(62))*xw(0.268,0.318,0.336,0.396)
fARM=((fA+fB+fC2+fE+fG)*ridge + fD*E.smoothstep((pdeg-100.0)/12.0) + fF)*armw
f+=fARM
REP['arm_pp_mm']=float((fARM.max()-fARM.min())*1000)

# ======================= blur, apply, guards =================================
f=np.nan_to_num(f)
fb,sig=E.graph_gaussian(f,ED,10,.45,MAXD,MEL2,label='final')
print("field: peak=%.3f mm rms=%.4f mm n_moved=%d"%(1000*np.abs(fb).max(),1000*np.sqrt(np.mean(fb**2)),int((np.abs(fb)>1e-7).sum())))
Vn=V+fb[:,None]*Ns
np.save(f'{W}/delta_field.npy',fb); np.save(f'{W}/v_new.npy',Vn)
REP['peak_mm']=float(1000*np.abs(fb).max())
base=json.load(open('/home/betty/tarrock-gauntlet-work/r13/tooling/stations_base.json'))
cur=F.silhouette_stations(Vn,base['bin_mm']); diff=[]
for reg,rows in base['regions'].items():
    now={round(q['z'],7):q for q in cur['regions'][reg]}
    for q in rows:
        r=now.get(round(q['z'],7))
        if not r: continue
        for k in ('x_half','y_min','y_max'): diff.append({'region':reg,'z':q['z'],'axis':k,'delta_mm':1000*(r[k]-q[k])})
worst=sorted(diff,key=lambda q:abs(q['delta_mm']),reverse=True)[:12]
print("\nSILHOUETTE worst 12 (budget 3.000 mm):")
for q in worst: print("   %-5s z=%.4f %-6s %+7.3f"%(q['region'],q['z'],q['axis'],q['delta_mm']))
mx=max(abs(q['delta_mm']) for q in diff)
print("max abs = %.3f mm -> %s"%(mx,'PASS' if mx<=3.0 else 'FAIL'))
def lead(v):
    ch=v[(v[:,2]>1.27)&(v[:,2]<1.36)&(np.abs(v[:,0])<0.09)&(v[:,1]<0)][:,1].min()
    be=v[(v[:,2]>1.08)&(v[:,2]<1.18)&(np.abs(v[:,0])<0.06)&(v[:,1]<0)][:,1].min()
    return 1000*(be-ch)
print("chest lead: base %.2f -> cand %.2f mm ; crown %.5f sole %.5f mm"%(
    lead(V),lead(Vn),1000*(Vn[:,2].max()-base['z_max']),1000*(Vn[:,2].min()-base['z_min'])))
REP['silhouette_max_mm']=float(mx); REP['chest_lead_mm']=[float(lead(V)),float(lead(Vn))]; REP['worst12']=worst
json.dump(REP,open(f'{W}/build_report.json','w'),indent=2)
