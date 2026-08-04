# R17 Head Polish — Cycle 2 Report

Final candidate: `Fool-v2-021f.blend`  
Base: `Fool-v2-021c.blend`

## Corrections made

- **Nose:** rebuilt the cycle-1 nose offsets from the untouched chain coordinates, narrowed the frontal bell, reduced the bridge and alar contributions, and retained a rounded midline tip. The final tip-to-bridge projection is 11.977 mm, preserving the requested 11.6 mm projection class without the cycle-1 broad wedge.
- **Mouth:** removed cycle-1's accumulated upper/lower inflation, recessed the inherited lip shelves, and used one gently rising seam as the only deliberate shadow break. The cupid-bow adjustment is sub-millimetric. This is visibly simpler in front and three-quarter views.
- **Eyes:** replaced the irregular sampled aperture stations with two fitted, smooth branches between shared pointed canthi. The upper curve peaks toward the inner third; the lower curve is shallower. Both 38-vertex rims use identical analytic parameterization and sit at 1.55 mm globe clearance.
- No topology was added or removed. No body, globe, or neck-ring vertices were edited.

## Structural validation

- Neck ring: 72 vertices, maximum chain delta 0.000 mm — pass.
- Eyes and body: 0 changed vertices and unchanged topology — pass.
- Symmetry: 0.133144 mm maximum residual, identical to the chain residual — preserved.
- Topology: 2,058 vertices; 3,970 triangle-equivalent faces; 1,983 quads; 4 triangles; 0 n-gons; 99.799% quad share — pass.
- Poles: degree histogram and topology unchanged; therefore no new mouth-corner or canthus poles.
- Visible lid/globe clearance: 1.550 mm minimum and maximum on both aperture rims — pass.
- Self-intersection: the required standard `verify_body.py` instrument reports exactly 27 face pairs, matching the documented baseline. Its sample sites remain in the occluded lid-band — pass. The obsolete triangle detector is retained only as a labeled diagnostic in the final JSON.
- `r17-validation-final.json` reports `overall_structural_pass: true`.

## Render and reference audit

Candidates E and F were each rendered eyes-on through `gov.sh` in front, side, and three-quarter studio/rake views, plus true wire renders. Candidate F was selected after direct comparison with the head regions of `Fool-Tpose-ModelSheet-v7.png` and `Fool-Orthographic-A-Pose.png`.

The `renders/` directory contains explicitly named `before-c2-*` and `after-c2-*` front/side/three-quarter studio, rake, and wire images, plus shaded and wire face close-ups. The before images are the cycle-1 final (`021c`); the after images are `021f`.

## Honest misses

- The mouth is substantially calmer and has one seam, but a small inherited lower-lip/chin shelf remains visible in strict side view. Flattening it further would begin changing the broader muzzle/chin silhouette beyond the three requested corrections.
- Blank globes make the openings read rounder at a glance than they will with irises; the actual rim wires are clean fitted almonds. No eye datablock was changed.
- The nose remains intentionally shorter than the numeric 20.152 mm sheet-profile landmark. Cycle 2 was explicitly asked to keep the 11.6 mm projection class; the final 11.977 mm follows that ruling.
