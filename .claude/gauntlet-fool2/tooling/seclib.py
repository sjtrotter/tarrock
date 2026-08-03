"""PLAN-VIEW SECTIONS -- the cycle-3 instrument (TASK-B3).

The station gates measure per-z EXTREMES (x_half, midline y_front/y_back).  A
face can satisfy all three and still be a flat-fronted slab, because the
extremes never see the section's front-lateral CORNERS.  This module cuts
horizontal sections and reports the whole outline, plus one scalar that names
the defect: the superellipse exponent p of the front half.

    |x/a|^p + |v/b|^p = 1,   v = (yc - y)  (forward is +v)

p = 2 is an ellipse; p < 2 is a WEDGE pointed at the face; p > 2 is a squircle
(a slab with rounded corners) -- which is what the judge called "a deep
rectangular muzzle".  a and b are the very quantities the station gates lock,
so p can be changed with the gates left standing: the corner field used by the
build passes is exactly zero at delta = 0 and delta = +-90 deg.
"""
import json
import math

import numpy as np

SECTION_Z = (1.46, 1.49, 1.52, 1.55, 1.58)


def head_centre_y(co, z, half=0.0015, xwin=0.007):
    m = (np.abs(co[:, 2] - z) < half) & (np.abs(co[:, 0]) < xwin)
    if m.sum() < 4:
        return 0.0, float("nan"), float("nan")
    yf, yb = co[m, 1].min(), co[m, 1].max()
    return 0.5 * (yf + yb), yf, yb


def outline(co, z, yc, nbins=72, half=0.0015):
    """Max radius per angular bin about (0, yc).  delta = 0 is the face (-Y),
    +90 deg is +X.  Returns (delta_deg, r_m) with gaps circularly filled."""
    m = np.abs(co[:, 2] - z) < half
    P = co[m][:, :2]
    if len(P) < 20:
        return np.zeros(nbins), np.zeros(nbins)
    x = P[:, 0]
    v = yc - P[:, 1]                       # forward-positive
    r = np.hypot(x, v)
    d = np.degrees(np.arctan2(x, v))       # 0 = front midline
    b = np.mod(np.rint(d / (360.0 / nbins)).astype(int), nbins)
    rr = np.zeros(nbins)
    np.maximum.at(rr, b, r)
    dd = np.arange(nbins) * (360.0 / nbins)
    dd = np.where(dd > 180.0, dd - 360.0, dd)
    ok = rr > 0
    if not ok.all() and ok.sum() > 2:
        idx = np.flatnonzero(ok)
        ext = np.concatenate([idx - nbins, idx, idx + nbins])
        val = np.concatenate([rr[idx]] * 3)
        rr = np.interp(np.arange(nbins), ext, val)
    return dd, rr


def super_r(delta_deg, a, b, p):
    """Radius of |x/a|^p + |v/b|^p = 1 along direction delta."""
    d = np.radians(np.asarray(delta_deg, float))
    s, c = np.abs(np.sin(d)), np.abs(np.cos(d))
    return (np.abs(s / a) ** p + np.abs(c / b) ** p) ** (-1.0 / p)


def fit_p(dd, rr, a, b, lo=15.0, hi=75.0, prange=(1.05, 4.0), n=240):
    """Front-quadrant superellipse exponent, least squares over |delta| in
    [lo, hi] (both sides pooled).  a, b are taken from the extremes, so p is
    the only free parameter -- it measures corner fullness alone."""
    m = (np.abs(dd) >= lo) & (np.abs(dd) <= hi)
    if m.sum() < 4 or not (a > 0 and b > 0):
        return float("nan")
    ps = np.linspace(prange[0], prange[1], n)
    err = [np.sum((rr[m] - super_r(dd[m], a, b, p)) ** 2) for p in ps]
    return float(ps[int(np.argmin(err))])


def measure(co, zlist=SECTION_Z, nbins=72):
    out = []
    for z in zlist:
        yc, yf, yb = head_centre_y(co, z)
        dd, rr = outline(co, z, yc, nbins=nbins)
        b = float(np.interp(0.0, dd[np.argsort(dd)], rr[np.argsort(dd)]))
        i90 = int(np.argmin(np.abs(dd - 90.0)))
        i270 = int(np.argmin(np.abs(dd + 90.0)))
        a = 0.5 * (rr[i90] + rr[i270])
        # front-half max |x| (excludes the ears, which sit behind delta 90)
        mfront = np.abs(dd) <= 90.0
        xh_front = float(np.max(np.abs(rr[mfront] * np.sin(np.radians(dd[mfront])))))
        msec = np.abs(co[:, 2] - z) < 0.0015
        xh_all = float(np.abs(co[msec, 0]).max()) if msec.sum() else float("nan")
        p = fit_p(dd, rr, a, b)
        i45 = int(np.argmin(np.abs(dd - 45.0)))
        i315 = int(np.argmin(np.abs(dd + 45.0)))
        r45 = 0.5 * (rr[i45] + rr[i315])
        # CONCAVITY guard.  r(delta) is not monotone even on a perfect wedge
        # (a superellipse with p < 2 has its minimum radius between the axes),
        # so the honest test is convexity in Cartesian space: how far a point
        # sits BEHIND the chord through its neighbours.  A too-narrow corner
        # bump cuts a groove, and that shows up here and nowhere else.
        o = np.argsort(dd)
        ds, rs_ = dd[o], np.array(rr)[o]
        g = np.arange(-90.0, 90.1, 5.0)
        rg = np.interp(g, ds, rs_)
        px = rg * np.sin(np.radians(g))
        py = -rg * np.cos(np.radians(g))
        conc = 0.0
        for k in range(2, len(g) - 2):
            ax_, ay_ = px[k - 2], py[k - 2]
            bx_, by_ = px[k + 2], py[k + 2]
            ex, ey = bx_ - ax_, by_ - ay_
            ln = math.hypot(ex, ey) or 1.0
            # positive = outward of the chord (convex)
            dv = ((px[k] - ax_) * ey - (py[k] - ay_) * ex) / ln
            conc = min(conc, dv)
        notch = -float(conc)
        out.append(dict(z=z, yc=yc, y_front=yf, y_back=yb, a=a, b=b, p=p,
                        notch=notch,
                        r45=r45, r45_ellipse=float(super_r(45.0, a, b, 2.0)),
                        x_half_front=xh_front, x_half_all=xh_all,
                        delta=dd.tolist(), r=rr.tolist()))
    return out


def print_table(secs, label=""):
    print("  -- PLAN SECTIONS %s --" % label)
    print("     z     y_front  y_back    a(side)  b(front)   p_eff   "
          "r45   r45_ell  d45   notch  xh_front  xh_all")
    for s in secs:
        print("   %.3f  %7.1f %7.1f   %7.1f  %7.1f   %5.2f  %6.1f %6.1f "
              "%+5.1f  %5.2f   %6.1f  %6.1f"
              % (s["z"], 1000 * s["y_front"], 1000 * s["y_back"],
                 1000 * s["a"], 1000 * s["b"], s["p"], 1000 * s["r45"],
                 1000 * s["r45_ellipse"],
                 1000 * (s["r45"] - s["r45_ellipse"]),
                 1000 * s.get("notch", 0.0),
                 1000 * s["x_half_front"], 1000 * s["x_half_all"]))


def print_outlines(secs, step=3):
    """Numeric front-half outline: y (mm, world) at each |x| ring."""
    print("  -- front-half outline, r(delta) in mm --")
    dd = np.array(secs[0]["delta"])
    order = np.argsort(dd)
    keep = [i for i in order if -90.0 <= dd[i] <= 90.0][::step]
    print("     z    " + "".join("%7.0f" % dd[i] for i in keep))
    for s in secs:
        r = np.array(s["r"])
        print("   %.3f  " % s["z"] + "".join("%7.1f" % (1000 * r[i])
                                             for i in keep))


COLS = [(235, 70, 70), (240, 150, 55), (235, 220, 60),
        (90, 220, 110), (90, 200, 245)]


def plot(secs, path, targets=None, ppm=3.4, note=""):
    """Top-down overlay.  Image +x = world +X (right), image UP = world -Y
    (the face).  Colours by height: 1.46 red, 1.49 orange, 1.52 yellow,
    1.55 green, 1.58 cyan.  Dashed pale twin = target superellipse."""
    import pngw
    W = H = 760
    cv = pngw.Canvas(W, H, ppm, W * 0.5, H * 0.62)
    cv.grid(10.0, (30, 30, 36), major=50.0, cmaj=(52, 52, 62))
    cv.line(cv.px(-400, 0), cv.px(400, 0), (70, 70, 84))
    cv.line(cv.px(0, -400), cv.px(0, 400), (70, 70, 84))
    def world(rv, dv, yc):
        """(delta, r) -> plot mm.  Image up = world -Y, so the face is at the
        top of the picture and the occiput at the bottom."""
        return (1000 * rv * math.sin(math.radians(dv)),
                1000 * (yc - rv * math.cos(math.radians(dv))))

    for i, s in enumerate(secs):
        dd = np.array(s["delta"]); rr = np.array(s["r"])
        o = np.argsort(dd)
        cv.polyline([world(rr[k], dd[k], s["yc"]) for k in o],
                    COLS[i % len(COLS)], r=1)
        if targets is not None:
            rt = super_r(dd[o], s["a"], s["b"], targets[i])
            tp = [world(rt[j], dd[o][j], s["yc"]) for j in range(len(rt))
                  if abs(dd[o][j]) <= 90.0]
            c = COLS[i % len(COLS)]
            pale = (min(255, c[0] // 2 + 70), min(255, c[1] // 2 + 70),
                    min(255, c[2] // 2 + 70))
            for j in range(0, len(tp) - 1, 2):
                cv.line(cv.px(*tp[j]), cv.px(*tp[j + 1]), pale)
    cv.save(path)
    print("WROTE", path, note)
    return path


def dump(secs, path):
    with open(path, "w") as f:
        json.dump([{k: v for k, v in s.items()} for s in secs], f)
    print("WROTE", path)
