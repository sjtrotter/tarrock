# TASK — R19 Phase B: hair blockout + shape (Codex)

Workdir: /home/betty/tarrock-gauntlet-work/fool2-r19/ (work ONLY here; you
have workspace write — probe with `touch write-probe-b.txt` before heavy
work; if it fails STOP and report).
Source: /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-024.blend
— READ-ONLY chain head (rigged, skinned, compliant ears joined). Candidates
Fool-v2-025a+ here. Rules: ./gov.sh before every heavy run, ONE Blender
(headless `blender --background --python`), one file per invocation,
whitelist renders, honest report.

## Ruling (lead, from R19-BRIEF ruling 3 — already decided, do not re-open)

- Hair is a SEPARATE object `Fool_Hair` — stylized SOLID MESH masses
  (storybook clumps). NO cards, NO strands, NO particle systems.
- Bound to the Head bone: bone-parent if a single rigid mass reads right,
  else armature-modifier with all verts 1.0 Head — your call, report it.
- Fool_Mesh, eyes, and rig are UNTOUCHED — freeze guard: every Fool_Mesh
  vertex moves 0.000 mm; topology sha unchanged; bone count/rest identical.
- Bald crown Z=1.716964 is FROZEN under the hair; hair adds ~3–4 cm (the
  A-pose sheet's 1.75 m scale guide is to hair, not scalp).

## Style law (charter mix: 40% Fable / 20% Kells-Wolfwalkers / 15% Kena)

Chunky storybook masses — few, large, confident clumps with a clear
silhouette; restraint over detail (director style rulings apply: the sheets
govern the READ, not millimetre exactness). Do a SHORT research pass
(existing knowledge is fine; no downloads, no donor assets — director ban)
on solid-mesh stylized game hair: sculpted-mass + clump-lobe construction
is the expected family. Budget ~800–2,500 tris.

## References (eyes-on, both)

- ~/Downloads/Fool-Orthographic-A-Pose.png — GOVERNING sheet for hair
  silhouette, front and side. Match the drawn hair mass/read.
- /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png
  side-view head cutout (calibration S=0.00201523 m/px) for scalp-line and
  ear relationship. The REAL ears are now on the mesh — coverage decisions
  are made against them (partial ear overlap is fine if the sheet draws it;
  do not bury the ears unless the sheet does).

## Steps

1. MEASURE: hair silhouette envelope from the A-pose sheet (front + side):
   top-of-hair Z, fringe line, side coverage vs ears, nape line.
2. BLOCK: rough mass over the scalp (front+side silhouette match first),
   as one object Fool_Hair. Slight inward overlap into the scalp is
   correct and standard — no visible gap between hair and head at any
   render angle.
3. SHAPE: break the mass into storybook clumps (lobes with a clean
   silhouette rhythm); keep interior simple. Solid/manifold preferred; if
   open-shell is structurally cleaner, the OUTER read must still be
   watertight-looking (no see-through gaps) — report which you chose.
4. BIND: Head bone (method per ruling above).
5. GATES (report all): Fool_Mesh freeze 0.000 mm + sha unchanged; rig
   untouched; hair top Z in [1.747, 1.757]; no hair/head visible gap in
   renders; hair self-intersections tolerated only clump-into-clump (report
   count), none creating shading artifacts in renders; tri budget met.
6. POSE SANITY: neck-turn 45 and nod −30 renders — hair moves rigidly with
   the head, no lag, no separation at the nape.
7. RENDERS (renders-b/, whitelist Fool_Mesh+eyes+Fool_Hair): full head
   front / side L / three-quarter / back, full figure front, plus A/B
   composites against the A-pose sheet head (front and side). EYES-ON:
   state honestly whether the hair reads as the drawn character's hair
   (mass, fringe, nape) and whether any angle shows gaps or a helmet read.

## Deliverables

Fool-v2-025X.blend final, hair-validation.json, REPORT-B-HAIR.md (honest),
renders-b/. If the silhouette cannot match both sheet views without
violating the frozen crown, STOP and document — the lead adjudicates.
