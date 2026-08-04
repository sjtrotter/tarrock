# R14 Phase A — Head Tooling Report

## Built and executed

- Preserved `scripts/presence_render.py` byte-for-byte from the supplied R13 tool (SHA256 `0b8502e68effa01dc829b3ed86fd3dd315927fca034de336a9456b2499ad5656`). No fix was required under Blender 5.2.
- Built `scripts/head_render.py`: 0.50 m head framing at 1100×1400 for front, +X side, three-quarter, and back, with unchanged Workbench studio settings plus EEVEE 30° rake; also full-front studio context.
- Built and ran `scripts/measure_016.py`, reusing `fieldlib.silhouette_stations` (2.5 mm bins) rather than rewriting it.
- Built PIL line-scan extraction in `scripts/extract_head_measurements.py` and computed placement with `scripts/build_eyeball_spec.py`.
- Rendered all nine `r14base` BEFORE PNGs and four `r14presence` validation PNGs under `renders/`.
- Chain file was only opened with `blender --background`; no blend was saved or modified.

## Presence rig validation

| View | Studio SHA256 | Rake SHA256 | mean abs pixel diff |
|---|---|---|---:|
| front | `b9cc2ecaf5f5a40dbc719a31ab98c4b9682b465e1adeab98fe98e1acf300c481` | `fe166c00860ffd79bc81f29b6bfdac7e26f46ebc6640bf554e5ab3a8c415b0ce` | 0.251596 (64.157/255) |
| three-quarter | `38b2981a9de4f80d0db6b62e7760707c6d5fa377bd255673385db93733c67649` | `7fbb5f676be680ecb0f2ff227fe2cbfe0cc9be34bd33eba1bea9f08f49c9f1e7` | 0.243696 (62.143/255) |

Both genuine-difference gates pass (>2/255 = 0.007843).

## Drawn landmark table (pixels → world mm)

Calibration: 2.01523 mm/px; anchors front (452,932), side (966,932). Full records and reasons are in `head_sheet.json`.

| Landmark | Pixels | World mm | Confidence |
|---|---|---|---|
| brow line | row 135 | Z 1606.138 | HIGH |
| left eye aperture | inner/outer 441/413; top/bottom 143/166 | X −22.168/−78.594; Z 1590.016/1543.666 | HIGH |
| right eye aperture | inner/outer 463/491; top/bottom 143/166 | X +22.168/+78.594; Z 1590.016/1543.666 | HIGH |
| nose bridge/tip/base | rows 177/181/184 | Z 1521.499/1513.438/1507.392 | LOW: tiny disconnected strokes make assignment ambiguous |
| nose side protrusion | tip col 912 minus brow col 922 | ΔY −20.152 | HIGH |
| mouth | row 190; cols 436–468 | Z 1495.301; width 64.487 | HIGH |
| chin | row 212 | Z 1450.966 | HIGH; verifies expected ≈1.451 m |
| jaw corner front L/R | row 194; cols 417/487 | Z 1487.240; X ±70.533 | LOW: broad curved jaw, no discrete corner |
| jaw corner side | row 196; col 975 | Z 1483.209; Y +18.137 | LOW: broad mandible curve |
| ear top/lobe | rows 142/196 | Z 1592.032/1483.209 | HIGH |
| ear side range | cols 979–1005 | Y +26.198 to +78.594 | HIGH |
| ear front max extent | cols 395/510 | X −114.868/+116.883 | HIGH |
| skull back maximum | rows 120–135; col 1026 | Z 1636.367–1606.138; Y +120.914 | HIGH |
| cranium max width | row 126; cols 405/498 | X −94.716/+92.701 | HIGH |
| neck at row 220 | cols front/back 957/1006 | Z 1434.844; Y −18.137/+80.609 | HIGH |
| neck at row 228 | cols front/back 958/1010 | Z 1418.722; Y −16.122/+88.670 | HIGH |
| neck at row 236 | cols front/back 958/1014 | Z 1402.600; Y −16.122/+96.731 | LOW: back approaches shoulder junction |

## Eyeball and socket numbers

- Drawn cornea at pupil row 152.5: side col 924.5, Y = −83.632 mm (HIGH).
- Recommended sphere radius 35.000 mm; centers `(X,Y,Z) = (±43.000, −48.632, 1571.000) mm`.
- 016 first-hit face Y: left −74.395 mm, right −74.348 mm.
- Eye center recession behind current face surface: left 25.762 mm, right 25.716 mm.
- Sphere front minus current surface: left −9.238 mm, right −9.284 mm; negative means the drawn cornea projects forward of the current blank face by that amount.
- Skull side wall at eye Z: X −87.404/+87.413 mm. Clearance beyond sphere outer edge: 9.404/9.413 mm.
- Midline gap between spheres: 16.000 mm. No overlap or lateral-wall impossibility was detected.

## 016 freeze-guard baseline

- `stations_016.json`: 992,787 evaluated world-space vertices; Z 0.000005–1.716998 m; float32 vertex SHA256 `1439c0a6b3fcd89c3c3cf17169bcc9f85fb093aa494d50a21250b6383cfe391b`.
- Reused region table counts: torso 312 stations (Z 0.940–1.7175), arm 47 (1.265–1.380), leg 377 (0.000–0.940).
- This is the immutable comparison baseline. No sculpt candidate exists in Phase A, so the below-1.30 max-|Δ| and 1.30–1.45 ±3 mm candidate gates were not executed or claimed.

## Drawn head contour target

- `head_stations_sheet.json`: 128 stations, 2.5 mm spacing, Z 1.400–1.7175; front left/right and half-width plus side Y min/max.
- Blue guide bands (including antialias fringe) were repaired by linear RGB interpolation, matching the supplied extraction lesson.
- Rows 142–196 are tagged where ear ink extends the front contour; rows 160–183 are tagged where nose ink extends the side-front contour.
- Ten direct crop checks used source rows 100, 112, 124, 136, 148, 160, 172, 184, 196, 208. Each binned record selected the identical nearest source row, so all four stored contour residuals are exactly 0.000 mm. This verifies transcription, not drawing accuracy.

## Deviations and TBDs

- Blender completed every requested output but lingered after completion in the unavailable PipeWire audio shutdown path; the idle processes were interrupted only after their DONE messages and files appeared.
- Blender reported an OpenColorIO 2.5/config versus 2.4.2/library mismatch and used fallback color management consistently for all renders.
- Nose row roles and jaw-corner locations remain explicitly LOW-confidence; Phase B should judge them against the supplied crops/renders rather than treating them as sharp anatomical constraints.
