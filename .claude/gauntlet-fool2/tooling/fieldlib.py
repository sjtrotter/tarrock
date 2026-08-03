"""Round-13 deterministic numpy field tools (Blender 5.2 compatible).

All distances are metres.  Functions print their measured/calibrated numbers when
verbose=True.  No function saves a Blender file or mutates an object implicitly.
"""
import hashlib, json, math
import numpy as np


def smoothstep01(t):
    t = np.clip(np.asarray(t, dtype=np.float64), 0.0, 1.0)
    return t*t*(3.0-2.0*t)


def c1_falloff(distance, radius, fpow=1.0):
    """Compact C1 radial falloff. fpow<1 is forbidden (the historical moat bug)."""
    if radius <= 0 or fpow < 1:
        raise ValueError("radius > 0 and fpow >= 1 required")
    return smoothstep01(np.clip(1.0-np.asarray(distance)/radius, 0, 1)) ** fpow


def radial(points, center, radius, fpow=1.0):
    p, c = np.asarray(points), np.asarray(center)
    return c1_falloff(np.linalg.norm(p-c, axis=-1), radius, fpow)


def aradius(points, center, axis, tight_radius, tail_radius, cross_radius,
            fpow=1.0):
    """Oriented asymmetric teardrop: tight at -axis, long tail at +axis."""
    p = np.asarray(points, float)-np.asarray(center, float)
    a = np.asarray(axis, float); a /= np.linalg.norm(a)
    along = p @ a
    rr = np.where(along < 0.0, tight_radius, tail_radius)
    cross = np.linalg.norm(p-along[:, None]*a, axis=1)
    d = np.sqrt((along/rr)**2 + (cross/cross_radius)**2)
    return c1_falloff(d, 1.0, fpow)


def facing(normals, direction, lo=0.0, hi=0.35):
    """C1 weight over normal dot direction; no hard-facing boundary."""
    d = np.asarray(direction, float); d /= np.linalg.norm(d)
    return smoothstep01((np.asarray(normals) @ d-lo)/(hi-lo))


def symmetric_centers(center):
    c = np.asarray(center, float).copy()
    if abs(c[0]) < 1e-12:
        return [c]
    d = c.copy(); d[0] *= -1
    return [c, d]


def symmetric_field(points, center, builder, combine="max", **kwargs):
    vals = [builder(points, c, **kwargs) for c in symmetric_centers(center)]
    return np.maximum.reduce(vals) if combine == "max" else np.sum(vals, axis=0)


def graph_info(vertices, edges):
    v=np.asarray(vertices,float); e=np.asarray(edges,np.int64)
    deg=np.bincount(e.ravel(), minlength=len(v)).astype(np.int32)
    mean_l2=float(np.mean(np.sum((v[e[:,0]]-v[e[:,1]])**2,axis=1)))
    return {"degree":deg, "max_degree":int(deg.max()), "mean_edge_l2":mean_l2}


def graph_gaussian(values, edges, iterations=8, alpha=0.45, vertices=None,
                   info=None, verbose=True):
    """Conservative graph heat diffusion using edge flux (centroid/sum preserving).

    This is repeated neighbour averaging (a lazy random walk), not a box pass.
    Effective spatial sigma is reported when vertices or graph_info is supplied.
    """
    x=np.asarray(values,float).copy(); e=np.asarray(edges,np.int64)
    if info is None:
        if vertices is None:
            deg=np.bincount(e.ravel(), minlength=len(x)); info={"degree":deg,"max_degree":int(deg.max()),"mean_edge_l2":float("nan")}
        else: info=graph_info(vertices,e)
    step=alpha/max(1,info["max_degree"])
    for _ in range(int(iterations)):
        delta=np.zeros_like(x)
        flux=(x[e[:,1]]-x[e[:,0]])*step
        np.add.at(delta,e[:,0],flux); np.add.at(delta,e[:,1],-flux)
        x += delta
    # isotropic per-coordinate heat sigma estimate from mean squared edge length
    sigma=math.sqrt(max(0.0, iterations*2.0*step*info["mean_edge_l2"]/3.0))
    if verbose: print("graph_gaussian iterations=%d alpha=%.4g effective_sigma_m=%.8g"%(iterations,alpha,sigma))
    return x, sigma


def calibrated_amplitude(build, edges, target_peak=None, target_rms=None,
                         iterations=8, alpha=.45, vertices=None, tolerance=.05,
                         max_rounds=8, verbose=True):
    """Build -> blur -> measure -> correct gain until selected target is within 5%."""
    gain=1.0; hist=[]; output=None
    for k in range(max_rounds):
        raw=np.asarray(build(gain),float)
        output,sigma=graph_gaussian(raw,edges,iterations,alpha,vertices,verbose=False)
        peak=float(np.max(np.abs(output))); rms=float(np.sqrt(np.mean(output*output)))
        measure=peak if target_peak is not None else rms
        target=float(target_peak if target_peak is not None else target_rms)
        err=abs(measure-target)/max(target,1e-30)
        hist.append({"round":k+1,"gain":gain,"peak":peak,"rms":rms,"error":err})
        if verbose: print("amplitude round=%d gain=%.8g peak=%.8g rms=%.8g error=%.3f%%"%(k+1,gain,peak,rms,100*err))
        if err <= tolerance: break
        gain *= target/max(measure,1e-30)
    return output, {"gain":gain,"peak":peak,"rms":rms,"sigma":sigma,"history":hist,"converged":err<=tolerance}


def gaussian_kernel1d(sigma_bins, truncate=4.0):
    r=max(1,int(math.ceil(truncate*sigma_bins))); q=np.arange(-r,r+1,dtype=float)
    k=np.exp(-.5*(q/sigma_bins)**2); return k/k.sum()


def _conv_axis0(a,k):
    pad=len(k)//2; ap=np.pad(a,((pad,pad),(0,0)),mode="reflect")
    return np.apply_along_axis(lambda x:np.convolve(x,k,mode="valid"),0,ap)


def bilinear_grid(grid, zf, pf):
    nz,np_=grid.shape; zf=np.clip(zf,0,nz-1); pf=np.mod(pf,np_)
    z0=np.floor(zf).astype(int); z1=np.minimum(z0+1,nz-1); p0=np.floor(pf).astype(int); p1=(p0+1)%np_
    az=zf-z0; ap=pf-p0
    return ((1-az)*((1-ap)*grid[z0,p0]+ap*grid[z0,p1]) + az*((1-ap)*grid[z1,p0]+ap*grid[z1,p1]))


def terrace_fix(z, phi, radius, nz=192, nphi=128, sigma_z_bins=3.0,
                fill_gain=1.0, cut_gain=1.0, verbose=True):
    """Remove radius terraces in (z,phi), smoothing the baseline along Z only."""
    z=np.asarray(z,float); phi=np.mod(np.asarray(phi,float),2*np.pi); r=np.asarray(radius,float)
    zmin,zmax=float(z.min()),float(z.max()); zf=(z-zmin)/max(zmax-zmin,1e-12)*(nz-1); pf=phi/(2*np.pi)*nphi
    zi=np.clip(np.rint(zf).astype(int),0,nz-1); pi=np.mod(np.rint(pf).astype(int),nphi)
    sums=np.zeros((nz,nphi)); cnt=np.zeros((nz,nphi)); np.add.at(sums,(zi,pi),r); np.add.at(cnt,(zi,pi),1)
    # fill sparse cells by circular per-row mean, then z interpolation
    grid=np.divide(sums,cnt,out=np.full_like(sums,np.nan),where=cnt>0)
    for j in range(nphi):
        good=np.isfinite(grid[:,j]); grid[:,j]=np.interp(np.arange(nz),np.flatnonzero(good),grid[good,j]) if good.any() else np.nanmean(r)
    base=_conv_axis0(grid,gaussian_kernel1d(sigma_z_bins))
    observed=bilinear_grid(grid,zf,pf); baseline=bilinear_grid(base,zf,pf)
    residual=observed-baseline; corr=np.where(residual>=0,-cut_gain*residual,-fill_gain*residual)
    before=float(np.sqrt(np.mean(residual**2))); after=float(np.sqrt(np.mean((residual+corr)**2)))
    if verbose: print("terrace_fix step_metric_before=%.8g after=%.8g reduction=%.2f%%"%(before,after,100*(1-after/max(before,1e-30))))
    return corr,{"before":before,"after":after,"z_range":[zmin,zmax],"nz":nz,"nphi":nphi,"sigma_z_bins":sigma_z_bins}


def erase(values, edges, iterations=18, alpha=.45, fill_gain=1.0, cut_gain=1.0,
          vertices=None, verbose=True):
    """Gaussian-baseline residual removal; radius is represented by diffusion sigma."""
    x=np.asarray(values,float); base,sigma=graph_gaussian(x,edges,iterations,alpha,vertices,verbose=False)
    res=x-base; corr=np.where(res>=0,-cut_gain*res,-fill_gain*res)
    if verbose: print("erase effective_radius_m=%.8g residual_rms=%.8g corrected_rms=%.8g"%(sigma,np.sqrt(np.mean(res*res)),np.sqrt(np.mean((res+corr)**2))))
    return corr,{"sigma":sigma,"residual_rms":float(np.sqrt(np.mean(res*res)))}


def silhouette_stations(vertices, bin_mm=2.5):
    """Station table with simple disjoint torso/arm/leg geometric masks."""
    v=np.asarray(vertices,float); dz=bin_mm/1000.; z0=math.floor(v[:,2].min()/dz)*dz; z1=math.ceil(v[:,2].max()/dz)*dz
    labels=np.full(len(v),"torso",dtype="U5")
    labels[(v[:,2]<0.94)&(np.abs(v[:,0])<0.30)]="leg"
    # At the welded shoulder, the anatomical split is the medial axillary plane.
    # 0.25 m excludes the deltoid/arm while retaining the certified ~0.244 m torso.
    labels[(v[:,2]>=0.88)&(np.abs(v[:,0])>=0.25)]="arm"
    out={"bin_mm":bin_mm,"z_min":float(v[:,2].min()),"z_max":float(v[:,2].max()),"regions":{q:[] for q in ("torso","arm","leg")}}
    for q in out["regions"]:
        mlabel=labels==q
        for z in np.arange(z0,z1+dz/2,dz):
            m=mlabel & (np.abs(v[:,2]-z)<=dz/2)
            if np.any(m):
                p=v[m]; out["regions"][q].append({"z":round(float(z),7),"x_half":float(np.max(np.abs(p[:,0]))),"y_min":float(p[:,1].min()),"y_max":float(p[:,1].max()),"n":int(m.sum())})
    return out


def moat_check(distance, field, bins=24, tolerance=1e-8):
    d=np.asarray(distance); f=np.asarray(field); edges=np.linspace(0,d.max()+1e-12,bins+1)
    means=np.array([np.mean(f[(d>=edges[i])&(d<edges[i+1])]) if np.any((d>=edges[i])&(d<edges[i+1])) else np.nan for i in range(bins)])
    means=means[np.isfinite(means)]; rises=np.diff(means)>tolerance
    return {"pass":bool(not rises.any()),"max_rise":float(np.max(np.diff(means),initial=0)),"profile":means.tolist()}


def displacement_stats(before, after, region_masks):
    d=np.linalg.norm(np.asarray(after)-np.asarray(before),axis=1); out={}
    for name,m in region_masks.items():
        x=d[np.asarray(m,bool)]; out[name]={"n":int(len(x)),"max":float(x.max(initial=0)),"mean":float(x.mean()) if len(x) else 0.,"rms":float(np.sqrt(np.mean(x*x))) if len(x) else 0.}
    return out


def vertex_hash(vertices):
    return hashlib.sha256(np.asarray(vertices,dtype=np.float32).tobytes()).hexdigest()


def save_json(path,data):
    with open(path,"w") as f: json.dump(data,f,indent=2,sort_keys=True)
