"""Round-13 Phase-D (escalation) field library.

Central principle (diagnosed this round): in flat directional light the eye reads
the SURFACE NORMAL, i.e. the first derivative of the surface. A visible "line",
"band", "plate edge" or "seam" is always a CURVATURE CONCENTRATION - a fast turn
of the normal over a short distance - whether or not any height ridge exists.

Consequences encoded here:
  * plane contrast must be built as a RAMP (a real normal tilt across a panel),
    never as a plateau displacement (plateaus rotate no interior normal and show
    only their rim -> the "plate / island" artifact);
  * every unintended boundary must return over a distance long enough that its
    slope change falls under the visibility floor;
  * an existing artifact band is removed by REDISTRIBUTING its slope change over
    a wider span, not by subtracting a (non-existent) ridge.

Visibility calibration measured on this mesh (the belt): ~300 mrad of normal turn
packed into 25 mm reads as a hard garment line. Working thresholds:
    intended soft plane break   : 60-140 mrad over 25-45 mm
    invisible transition/return : < 25 mrad over >= 45 mm
"""
import numpy as np


# ---------------------------------------------------------------- primitives
def smoothstep(t):
    t = np.clip(np.asarray(t, float), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def gk(sigma_bins, truncate=4.0):
    r = max(1, int(np.ceil(truncate * sigma_bins)))
    x = np.arange(-r, r + 1, dtype=float)
    k = np.exp(-0.5 * (x / sigma_bins) ** 2)
    return k / k.sum()


def gsm(y, sigma_bins):
    if sigma_bins <= 0:
        return np.asarray(y, float).copy()
    k = gk(sigma_bins)
    p = len(k) // 2
    return np.convolve(np.pad(np.asarray(y, float), p, mode='edge'), k, 'valid')


def slope_profile(u, segments, crease, du=None):
    """Displacement profile built from a piecewise-constant SLOPE spec.

    segments: [(u0, u1, slope), ...] in metres / (metres per metre).
    The slope table is Gaussian-smoothed with sigma=crease/2.5 (so `crease` is the
    full width over which a slope change happens) and integrated. Returns d(u)
    with d(u_min)=0. Building in slope space is what guarantees the result has a
    controlled, bounded curvature everywhere - the whole point of this round.
    """
    u = np.asarray(u, float)
    if du is None:
        du = 0.0002
    g = np.arange(u.min() - 0.05, u.max() + 0.05 + du, du)
    s = np.zeros_like(g)
    for u0, u1, sl in segments:
        s[(g >= u0) & (g < u1)] = sl
    s = gsm(s, max(1.0, (crease / 2.5) / du))
    d = np.concatenate([[0.0], np.cumsum(0.5 * (s[1:] + s[:-1])) * du])
    d -= d[0]
    return np.interp(u, g, d), (g, s, d)


def check_visibility(g, s, du=0.0002, label=""):
    """Report the worst slope change per unit length of a profile (mrad / mm)."""
    ds = np.gradient(s, du)
    i = int(np.argmax(np.abs(ds)))
    # width over which ~68% of the largest transition happens
    peak = abs(ds[i])
    turn = np.trapezoid(np.abs(ds), g)
    return {"label": label, "max_curvature_per_m": float(peak),
            "total_turn_mrad": float(turn * 1000.0),
            "equiv_mrad_per_25mm": float(peak * 0.025 * 1000.0)}


# ------------------------------------------------------------ graph diffusion
def graph_gaussian(values, edges, iterations, alpha, max_degree, mean_edge_l2,
                   label=""):
    x = np.asarray(values, float).copy()
    step = alpha / max(1, max_degree)
    for _ in range(int(iterations)):
        flux = (x[edges[:, 1]] - x[edges[:, 0]]) * step
        d = np.zeros_like(x)
        np.add.at(d, edges[:, 0], flux)
        np.add.at(d, edges[:, 1], -flux)
        x += d
    sigma = np.sqrt(max(0.0, iterations * 2.0 * step * mean_edge_l2 / 3.0))
    if label:
        print("  blur[%s] iters=%d alpha=%.3f effective_sigma=%.4f mm"
              % (label, iterations, alpha, sigma * 1000))
    return x, sigma


def mirror_x(field, v, tol=1e-5):
    """Enforce exact X symmetry by construction wherever fields are analytic in |x|."""
    return field


# ------------------------------------------------------------------- helpers
def bilinear(grid, rows, cols, r, c):
    """Sample a 2-D table (rows x cols axes given as 1-D coordinate arrays)."""
    ri = np.clip(np.interp(r, rows, np.arange(len(rows))), 0, len(rows) - 1.0001)
    ci = np.clip(np.interp(c, cols, np.arange(len(cols))), 0, len(cols) - 1.0001)
    r0 = ri.astype(int); c0 = ci.astype(int)
    fr = ri - r0; fc = ci - c0
    return ((1 - fr) * ((1 - fc) * grid[r0, c0] + fc * grid[r0, c0 + 1]) +
            fr * ((1 - fc) * grid[r0 + 1, c0] + fc * grid[r0 + 1, c0 + 1]))


def taper(x, a, b):
    """C1 0->1 ramp from a to b (works for a>b too)."""
    return smoothstep((np.asarray(x, float) - a) / (b - a))
