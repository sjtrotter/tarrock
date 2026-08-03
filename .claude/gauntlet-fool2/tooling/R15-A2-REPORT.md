# R15 Phase A2 — Registration + Bulk Shrinkwrap

Mechanical projection only; no face-loop judgment. Real headless run values are in `r15-a2-validation.json`.

## Result

- Output: `Fool-v2-019a.blend`; sacred chain `Fool-v2-018.blend` was opened and saved-as, so its objects are preserved (not linked), and the chain file was never written.
- Draft object: `Fool_HeadRetopo_draft` (2660 vertices, 2616 faces).
- Neck cut: source-local Z -0.680000; proposed seam 80 vertices.
- Masks frozen after nearest-surface stage: A2_MASK_EYELID_L (25), A2_MASK_EYELID_R (25), A2_MASK_MOUTH (75).

## Registration

- X affine: scale 0.169890303, translate 0; Y affine: scale 0.097521730, translate 0.002069415 m.
- Z is piecewise affine through donor chin/eye/crown -0.253443/0.187322/0.931489 to 1.451/1.571/1.717 m.
- Brow/back Y targets were measured from sculpt horizontal sections; socket Y then received a topology-local correction to −40.3 mm.

## Validation

- Unmasked deviation: RMS 0.3614 mm; p95 0.1516 mm; max 9.9531 mm.
- Symmetry max: 344.723299 mm before, 0.000000 mm after (1287 pairs).
- Quads: 2599/2616 = 99.350%; non-quads: 17.
- Poles within two rings of masks: 29 among 224 examined vertices.

## Findings

- Gate result: RMS passes the 1.5 mm limit, but max 9.9531 mm FAILS the 3 mm limit (cranium 9.9531 mm; face 6.1862 mm).
- Wire/section evidence shows localized projection artifacts matching those outliers; reported for lead validation, not silently repaired in mechanical A2.
- Eye and mouth neighborhoods are intentionally frozen at stage 1; their known donor topology defects remain Phase B work.
- Exact post-wrap symmetry can slightly move paired vertices off the sculpt; the reported deviation is measured after symmetry and is not hidden.
- Five individual plan-section overlays are under `sections-a2/` (sculpt red, donor cyan); wireframe-over-shaded views are under `renders-a2/`.

## Phase-B context (lead ruling)

- Eye globes stay separate at radius 35 mm; the orbital retopo builds OUT to the drawn width at eye rows.
- The sculpt line near Z 1.51 m is a remesh terrace; the retopo surface should not reproduce it.
