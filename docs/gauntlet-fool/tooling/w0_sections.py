"""Cycle-3 instrument run: plan sections at the five named heights.

Usage: blender --background IN.blend --python w0_sections.py -- TAG [P_TARGETS]
TAG names the outputs (sections/TAG-plan.png, sections/TAG.json).
P_TARGETS is an optional comma list of five superellipse exponents to draw as
the dashed twin.
"""
import os
import sys

import bpy
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import seclib as S

argv = sys.argv[sys.argv.index("--") + 1:]
TAG = argv[0]
TGT = ([float(v) for v in argv[1].split(",")]
       if len(argv) > 1 and argv[1] != "-" else None)
OBJ = argv[2] if len(argv) > 2 else "Fool_SculptBase"
WD = "/home/betty/tarrock-gauntlet-work/fool2-r14"
OUTD = os.path.join(WD, "sections")
os.makedirs(OUTD, exist_ok=True)

body = bpy.data.objects[OBJ]
me = body.data
n = len(me.vertices)
co = np.empty(n * 3)
me.vertices.foreach_get("co", co)
co = co.reshape(n, 3)
print("body %s: %d verts" % (body.name, n))

secs = S.measure(co)
S.print_table(secs, label=TAG)
S.print_outlines(secs)
S.dump(secs, os.path.join(OUTD, "%s.json" % TAG))
S.plot(secs, os.path.join(OUTD, "%s-plan.png" % TAG), targets=TGT)
print("SECTIONS_DONE (nothing saved to the blend)")
