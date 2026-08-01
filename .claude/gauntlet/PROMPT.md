# The Gauntlet — MQ00

Build Tarrock's opening scene — MQ00, "The Leap," on the Cliff — in the Unity project
at this repo root, to the quality of a shipped storybook game. `docs/` is canon:
`docs/quests/main/MQ00-the-leap.md` is the script, the art docs own the look. The scene
is `Assets/_Project/Scenes/Sandbox/TerrainProto.unity`. It should be beautiful: dawn
light, wind in the grass, a dead campfire, old campsites, a world's broken edge — warm,
dry, gently mournful.

The bar is the reference board in `docs/design/reference-board/` — real frames, mostly
Fable's opening regions, cut with Wolfwalkers, Kena, Dishonored, and old fairy-tale
plates. A piece is done only when a screenshot of ours, judged blind beside the board,
holds its own as a frame from the same storybook world.

Choose your own approach. Split the scene into the smallest pieces that can be improved
and judged independently. For each piece that matters, fan out a builder sub-agent and a
separate, fresh-context, genuinely harsh critic. The critic must look at the real
rendered output, compare it side by side with the board — blind whenever possible — name
the single biggest remaining gap, and send it back. Keep looping until the critic
honestly picks our frame, or the director stops the run.

Keep a simple live progress page showing the scene evolving round by round. Fan out
sub-agents and ultracode.

Hard constraints: this machine has thermal limits — one heavy Unity or render operation
at a time, no batch captures, check load first. And the docs win every tie: nothing in
the scene may contradict canon.
