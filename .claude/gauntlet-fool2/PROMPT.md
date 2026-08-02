# The Gauntlet v2 — The Fool, from scratch

Build the Fool's character model in Blender **from scratch**. Disregard every previous
mesh — the `Fool-my-edits*` and `Fool-claude-edits*` chains and the old `Fool.blend`
are dead ends; do not open them for geometry (you may glance at them only to learn what
already failed). Follow the industry-standard character workflow — references &
blockout → merge & sculpt → head sculpt → head retopo → body retopo → rigging → hair →
clothes & accessories → materials (the Bran Sculpts order) — researching online at each
step as needed. You may install any Blender add-ons that help.

Block out with cubes subsurfed to level 3; place loop cuts on the initial blocks in
anticipation of retopology; err toward extra mesh around joints and future sculpt
zones.

The base mesh comes from `docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png`
(also in `~/Downloads`) — eyeball registration circles sit directly above the pupils,
and all limb cutouts are LEFT limbs sharing the sheet's guidelines. The moment the mesh
stands as a clean generic young-adult man, save that exact version as
`docs/design/3d-models-inwork/YoungAdultMale-base.blend`. Then customize it into the
Fool per `~/Downloads/Fool-Orthographic-A-Pose.png`, backed by the other sheets there
(`Fool-Orthographic-Hand-Boot-Ref.png`, `Fool-Orthographic-Arm.png`,
`Fool-Expressions.png`, `Fool-Clothing-Layers-Materials-Colors.png`) — that sheet is
older, so interpret where it conflicts with the new one. Eyes are rig-ready by director
ruling: open sockets with separate rotatable eyeball spheres on their own bones.

Final output: `docs/design/3d-models-inwork/Fool.blend`, posed/animation-ready, and
proven to survive the Blender→Unity trip — research the export path (FBX, scale,
orientation, rig) and verify it mechanically before calling the run done. The Unity
project is this repo's root, but do NOT open or touch the Unity editor; verify the
export by inspection of the FBX instead.

**The bar:** a matched-camera orthographic render of the real mesh, overlaid and judged
blind beside the governing sheet — `Fool-Tpose-ModelSheet-v7.png` for the base body,
`Fool-Orthographic-A-Pose.png` for the dressed Fool — reads as the same character drawn
by the same hand: 40% Fable (original trilogy), 20% Kells/Wolfwalkers, 15% Kena,
10% Dishonored, 10% illustrated fairy tales, 5% Ghibli. Stylized-simple beats
anatomical-correct — a prior run died of "gnarled and gross" over-detailed hands.

Choose your own approach. Split the work into the smallest pieces that can be improved
and judged independently. For each piece that matters, fan out a builder and a
separate, fresh-context, genuinely harsh critic at least one model tier above the
builder. The critic must inspect real renders, compare them blind against the sheet
(A/B when possible; the Codex CLI — `codex exec` with `-i` images, prompt before the
`-i` flags, `--skip-git-repo-check`, `-c 'mcp_servers={}'` — is a cross-model blind
judge), name the single biggest remaining gap, and send it back. Keep looping until
the piece wins or the director stops the run. An 80–90% solution is acceptable — when
a round's improvement stops being visible, take the win and move on.

Keep a simple live progress page showing the work evolving round by round — NOT a
local/claude.ai artifact: maintain `.claude/gauntlet-fool2/STATUS.md` (with round
renders as small PNGs under `.claude/gauntlet-fool2/renders/`) and commit + push it to
origin at every round close (`docs:` commits, master), so the director can watch
remotely on GitHub. Blend files stay uncommitted as ever — only the status page and
render images get pushed. Fan out sub-agents and ultracode.

Hard constraints (machine-stability, director-ordered): batch width comes from the
gauntlet governor — ensure `~/.local/bin/gauntlet-governor.sh` is running (pgrep first,
one instance only) and read `/tmp/tarrock-governor/slots` before each batch; every
fanned brief carries the throttle protocol (if PAUSE, poll every 15s before heavy
commands). Never more than 3 concurrent agents; exactly ONE Blender-driving agent at a
time (single MCP socket if the GUI is up — otherwise headless `blender --background
--python` works and still counts as the one Blender lane); at most one sustained
full-core process at a time; check `/proc/loadavg` and `x86_pkg_temp` before anything
heavy. Save every iteration to a NEW numbered file (`Fool-v2-001.blend` onward) in
`docs/design/3d-models-inwork/`; blends stay uncommitted. Method authorities:
`docs/design/character-modeling-pipeline.md` and
`docs/design/character-sculpt-reference.md` — read them before touching a vertex; their
lessons (INFLATE trap, view-gated strokes, integration-as-acceptance-test) were paid
for.
