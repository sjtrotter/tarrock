# R19 BRIEF — hair + compliant ear rebuild (5th lead, 2026-08-04)

Chain head: Fool-v2-023.blend (rigged, skinned, pose-tested). This round
executes the scheduled compliant ear rebuild (director ruling: ears are NEW
mirrored geometry shaped to the ear's outer dimensions, refined, then
JOINED — never extruded/carved from the head; current ears are banned-method
relief discs, audit in ROUND-STATE) and then the hair stage of the charter
workflow.

## Lead rulings

1. **Order: ears FIRST, then hair** — hair sits over the ears; coverage
   decisions need the real ears in place.
2. **Ears join the head mesh** (ruling says "then joined"): weld/bridge
   into Fool_Mesh at the ear root; old relief discs smoothed away first.
   New ear verts skinned 1.0 to Head bone. Topology change is expected and
   documented (sha before/after); all other instruments must hold (mirror,
   self-int 0, rest identity, digit gates untouched).
3. **Hair is a SEPARATE object `Fool_Hair`** (game standard): stylized
   solid mesh masses per the A-pose sheet silhouette (storybook clumps, no
   cards/strands at this stage), parented/skinned to the Head bone (bone
   parent acceptable if a single rigid mass reads right — builder judges,
   lead validates). Bald crown 1.716964 is FROZEN; hair adds ~3–4 cm
   (sheet scale guide 1.75 m is to hair).
4. Style law: 40% Fable / 20% Kells / 15% Kena — chunky storybook masses;
   restraint rulings apply. Sheets govern the read, not millimetres.
5. Executor Codex throughout; escalation clause unchanged. Workdir
   fool2-r19/; candidates Fool-v2-024a+; promotion target Fool-v2-024.blend
   (may land as two chain steps — 024 ears, 025 hair — lead's call at
   validation).

## Phases

- Phase A (Codex): ear rebuild per TASK-A-EARS.md.
- Phase B (Codex): hair blockout+shape per TASK-B-HAIR.md (written after A
  validates).
- Blind judge at close: head vs the A-pose sheet head region + v7 side
  cutout (ears now shaped; hair silhouette A/B).
