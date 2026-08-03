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

**Usage economy (director order 2026-08-03):** Claude weekly quota is burning far
faster than Codex (Codex sits at ~99% remaining). Codex CLI is now the DEFAULT
executor for grunt work — builder script-writing and iteration, bpy/numpy sculpt
code, render/measure/report loops — via `codex exec`. Codex CAN drive the GUI MCP
socket: configure the blender-mcp stdio server via `-c` overrides (server at
`~/blender_mcp`, launched with `uv run blender-mcp`, which talks to the GUI addon
socket on 9876) instead of the usual `-c 'mcp_servers={}'` kill-switch; headless
`blender --background --python` on the latest chain file also works. Either way the
one-Blender-lane rule holds — a Codex Blender session counts as THE lane. Claude
agents are reserved for: the lead's
planning/validation, stage-close critique, and pieces Codex has genuinely failed
twice. Prefer Codex for blind judging as before. Keep Claude sub-agent count and
round narration lean.

Choose your own approach. Split the work into the smallest pieces that can be improved
and judged independently. For each piece that matters, fan out a builder and a
separate, fresh-context, genuinely harsh critic at least one model tier above the
builder. The critic must inspect real renders, compare them blind against the sheet
(A/B when possible; the Codex CLI — `codex exec` with `-i` images, prompt before the
`-i` flags, `--skip-git-repo-check`, `-c 'mcp_servers={}'` — is a cross-model blind
judge), name the single biggest remaining gap, and send it back. Keep looping until
the piece wins or the director stops the run. An 80–90% solution is acceptable — when
a round's improvement stops being visible, take the win and move on.

**Director channel (async):** when a decision genuinely needs the director — a canon
call, a quality-vs-scope tradeoff the charter doesn't settle, a hard blocker — do NOT
stall and do NOT guess on canon. Open a GitHub issue on this repo (`gh issue create`)
stating the question, the options, and your recommendation, and @-mention `@sjtrotter`
in the body so it emails them. Then keep working on everything not blocked by the
answer, polling the issue for a director comment (`gh issue view <n> --comments`,
poll interval ≥ 5 min). When the director answers: reply on the issue acknowledging
the ruling, apply it, record it in ROUND-STATE.md, and CLOSE the issue once the matter
is actually resolved. Non-canon judgment calls are still yours — take the
industry-standard option and log it; the issue channel is for director-only decisions.

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
