# R20 BRIEF — clothes & accessories (6th lead, 2026-08-04)

Chain head: Fool-v2-025.blend (rigged figure + joined free-rim ears +
Fool_Hair). This round dresses the Fool per the charter workflow stage
"clothes & accessories".

## Lead rulings

1. **Clothing = separate mesh objects layered over the body** (game
   standard): each garment its own object, skinned by weight transfer
   from Fool_Mesh (then cleaned), NOT modeled into the body. Body
   geometry under garments stays (no deletion this round — culling is a
   later optimization call).
2. **Governing references:** ~/Downloads/Fool-Orthographic-A-Pose.png
   (newest, governs silhouette/fit) backed by
   ~/Downloads/Fool-Clothing-Layers-Materials-Colors.png (layer
   order/pieces/colors), Fool-Orthographic-Hand-Boot-Ref.png (boots),
   Fool-Orthographic-Arm.png (sleeves). Conflicts: A-pose wins.
3. **Phase A (Codex) = inventory + measurement, NO geometry:** read the
   sheets eyes-on, produce the piece list (garment, layer order, coverage
   z/landmark ranges, attachment/overlap notes, color/material notes for
   the materials stage), calibrated envelope measurements per piece
   (ratio-anchored per the R19 lesson — no bare mm without a ratio
   cross-check), and a build-order proposal with per-piece gates. Lead
   validates before any builder runs.
4. **Build phases:** one garment (or tightly-coupled set) per builder
   invocation, Codex-first with the standard two-fail escalation. Gates
   per piece: body/hair/rig freeze (0.000 + sha), no poke-through of the
   body through the garment at rest AND in the R18 pose battery poses
   (posed self-intersection instrument), silhouette A/B vs the A-pose
   sheet, tri budgets set in Phase A, Head/limb binding via weight
   transfer + zero-weight and rigid-lag guards.
5. Style law as ever: 40% Fable / 20% Kells / 15% Kena; chunky storybook
   read; restraint rulings (#5/#6) apply; sheets govern the read.
6. Workdir: /home/betty/tarrock-gauntlet-work/fool2-r20/ (git init BEFORE
   first Codex launch; launch with -s workspace-write and verify the log
   header says workspace-write). Candidates Fool-v2-026a+; promotion
   target Fool-v2-026.blend (may split into multiple chain steps at
   lead's call).
7. Blind judge at close: dressed figure A/B vs the A-pose sheet, front +
   side — this is the round where the r12-era "presence/mannequin" debt
   class and the issue-#2 belt ruling get their dressed re-judge.

## Phases

- Phase A (Codex): sheet inventory + measurements + build plan
  (TASK-A-CLOTHES.md).
- Phases B+ (Codex, escalation clause live): garment builds per the
  validated plan.
- Close: dressed blind judge, STATUS + renders push, debts ledger update.
