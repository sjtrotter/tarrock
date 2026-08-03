"""R14 head-sculpt library: slope-space shell retarget + field primitives.

Distances are metres.  Nothing here saves a blend file.
"""
import math
import numpy as np


# ---------------------------------------------------------------- basics --
def smoothstep01(t):
    t = np.clip(np.asarray(t, float), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def band(z, z0, z1):
    """0 below z0, 1 above z1, C1 in between."""
    return smoothstep01((np.asarray(z, float) - z0) / (z1 - z0))


def bump(z, z0, z1, z2, z3):
    """0 / rise / 1 / fall / 0 — C1 trapezoid."""
    return band(z, z0, z1) * (1.0 - band(z, z2, z3))


def gauss1d(sig_bins, trunc=4.0):
    r = max(1, int(math.ceil(trunc * sig_bins)))
    q = np.arange(-r, r + 1, dtype=float)
    k = np.exp(-0.5 * (q / sig_bins) ** 2)
    return k / k.sum()


def smooth_axis0(a, k):
    pad = len(k) // 2
    ap = np.pad(a, ((pad, pad),) + ((0, 0),) * (a.ndim - 1), mode="edge")
    return np.apply_along_axis(lambda x: np.convolve(x, k, mode="valid"), 0, ap)


def smooth_axis1_wrap(a, k):
    pad = len(k) // 2
    ap = np.concatenate([a[:, -pad:], a, a[:, :pad]], axis=1)
    return np.apply_along_axis(lambda x: np.convolve(x, k, mode="valid"), 1, ap)


def bilinear(grid, zf, pf):
    nz, npv = grid.shape
    zf = np.clip(zf, 0, nz - 1); pf = np.mod(pf, npv)
    z0 = np.floor(zf).astype(int); z1 = np.minimum(z0 + 1, nz - 1)
    p0 = np.floor(pf).astype(int); p1 = (p0 + 1) % npv
    az = zf - z0; ap = pf - p0
    return ((1 - az) * ((1 - ap) * grid[z0, p0] + ap * grid[z0, p1])
            + az * ((1 - ap) * grid[z1, p0] + ap * grid[z1, p1]))


# ------------------------------------------------------- graph diffusion --
def graph_info(edges, nverts):
    deg = np.bincount(edges.ravel(), minlength=nverts).astype(np.int32)
    return int(max(deg.max(), 1))


def graph_gaussian(values, edges, nverts, iterations=48, alpha=0.45,
                   maxdeg=None):
    """Conservative heat diffusion on the edge graph (Gaussian-equivalent)."""
    x = np.asarray(values, float).copy()
    if maxdeg is None:
        maxdeg = graph_info(edges, nverts)
    step = alpha / maxdeg
    e0, e1 = edges[:, 0], edges[:, 1]
    for _ in range(int(iterations)):
        flux = (x[e1] - x[e0]) * step
        np.add.at(x, e0, flux)
        np.add.at(x, e1, -flux)
    return x


def umbrella(x, edges, deg):
    """Uniform-weight Laplacian: mean(neighbours) - x.  x may be (n,) or (n,3)."""
    acc = np.zeros_like(x)
    np.add.at(acc, edges[:, 0], x[edges[:, 1]])
    np.add.at(acc, edges[:, 1], x[edges[:, 0]])
    d = deg if x.ndim == 1 else deg[:, None]
    return acc / np.maximum(d, 1) - x


def taubin(co, edges, weight, passes=8, lam=0.50, mu=-0.53):
    """Band-limited (non-shrinking) surface smoothing, per-vertex strength.

    Removes surface wavelengths below roughly 4x the mean edge length --
    voxel terracing -- while leaving sculpted form untouched.
    """
    n = len(co)
    deg = np.bincount(edges.ravel(), minlength=n).astype(np.float64)
    x = co.copy(); w = np.asarray(weight, float)[:, None]
    for _ in range(int(passes)):
        x += w * lam * umbrella(x, edges, deg)
        x += w * mu * umbrella(x, edges, deg)
    return x


def diffusion_sigma(iterations, alpha, maxdeg, mean_edge_l2):
    step = alpha / maxdeg
    return math.sqrt(max(0.0, iterations * 2.0 * step * mean_edge_l2 / 3.0))


# --------------------------------------------------------- head cylinder --
def head_axis(co, zlo, zhi, dz=0.0025, xwin=0.06, sig_bins=6.0):
    """Per-z head centre in Y (mean of front/back extremes near the midline)."""
    zs = np.arange(zlo, zhi + dz, dz)
    yc = np.full(len(zs), np.nan)
    near = np.abs(co[:, 0]) < xwin
    for i, z in enumerate(zs):
        m = near & (np.abs(co[:, 2] - z) < dz)
        if m.sum() > 8:
            yc[i] = 0.5 * (co[m, 1].min() + co[m, 1].max())
    good = np.isfinite(yc)
    yc[~good] = np.interp(zs[~good], zs[good], yc[good])
    yc = np.convolve(np.pad(yc, len(gauss1d(sig_bins)) // 2, mode="edge"),
                     gauss1d(sig_bins), mode="valid")
    return zs, yc


def shell_grid(z, phi, r, zs_lo, dz, nz, nphi):
    """Mean radius on a (z, phi) grid, holes filled circularly then along z."""
    zf = (z - zs_lo) / dz
    pf = np.mod(phi, 2 * np.pi) / (2 * np.pi) * nphi
    zi = np.clip(np.rint(zf).astype(int), 0, nz - 1)
    pi = np.mod(np.rint(pf).astype(int), nphi)
    s = np.zeros((nz, nphi)); c = np.zeros((nz, nphi))
    np.add.at(s, (zi, pi), r); np.add.at(c, (zi, pi), 1.0)
    g = np.divide(s, c, out=np.full_like(s, np.nan), where=c > 0)
    for i in range(nz):                       # circular fill within a row
        row = g[i]; ok = np.isfinite(row)
        if ok.all():
            continue
        if ok.sum() >= 2:
            idx = np.flatnonzero(ok)
            ext = np.concatenate([idx - nphi, idx, idx + nphi])
            val = np.concatenate([row[idx]] * 3)
            g[i] = np.interp(np.arange(nphi), ext, val)
        elif ok.sum() == 1:
            g[i] = row[ok][0]
    for j in range(nphi):                     # then along z
        col = g[:, j]; ok = np.isfinite(col)
        if ok.any() and not ok.all():
            g[:, j] = np.interp(np.arange(nz), np.flatnonzero(ok), col[ok])
    return g, zf, pf


def cardinal_ratio_field(phi_grid, k_front, k_back, k_side):
    """C-inf blend of three cardinal ratios; weights sum to exactly 1."""
    cp = np.cos(phi_grid); sp = np.sin(phi_grid)
    wf = np.maximum(0.0, -cp) ** 2
    wb = np.maximum(0.0, cp) ** 2
    ws = sp ** 2
    return (wf * k_front[:, None] + wb * k_back[:, None] + ws * k_side[:, None])


# ----------------------------------------------------------- primitives ---
def ellipsoid_q(p, centre, axes, power=2.0):
    """Normalised superellipsoid distance (1.0 on the shell)."""
    d = (np.asarray(p, float) - np.asarray(centre, float)) / np.asarray(axes, float)
    return (np.abs(d) ** power).sum(axis=-1) ** (1.0 / power)


def falloff(q, q_in, q_out):
    """1 inside q_in, 0 outside q_out, C1."""
    return 1.0 - smoothstep01((np.asarray(q, float) - q_in) / (q_out - q_in))


def mirror_x(co):
    m = co.copy(); m[:, 0] *= -1.0
    return m
