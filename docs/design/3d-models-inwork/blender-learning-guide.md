# Blender learning guide — two tracks (character artist + director)

*Compiled 2026-07-22 from web research (two agents, sources linked inline) plus
hands-on verification on the Fedora box. Working doc, not canon — lives in
`3d-models-inwork/` on purpose.*

**The plan:** the character artist (Mac mini) learns the full stylized-character
pipeline — model → texture → rig → animate — while the director (Fedora) learns
rougher prop/environment modeling. Both converge on the same export-to-Unity recipe.
Target style: Tarrock's warm painterly storybook look (owned by
`docs/design/art-audio.md`) — stylized, hand-painted, NOT realistic.

---

## Part 1 — Shared foundation (both tracks)

### Version
Current Blender is **5.2 LTS** (July 2026, supported to July 2028). Use it on both
machines. Note: Blender 5.x is **Apple-Silicon-only** on Mac (no Intel Macs).

### The learning spine (in order)
Total to first game-ready character: roughly **8–12 weeks part-time**.

| Stage | Resource | Time |
|---|---|---|
| 0. Interface + first object | [Blender Guru's Donut, 5.0 edition](https://www.blenderguru.com/posts/blender-donut-v5-tutorial) (free, YouTube) — the classic onboarding. Optionally follow with [GameDev.tv "Get Started with Blender"](https://gamedev.tv/courses/get-started-blender) (free, games slant) | ~1 wk |
| 1. Stylized low-poly modeling | **Grant Abbitt** ([@grabbitt on YouTube](https://www.youtube.com/@grabbitt), free) — the single best style match for this project: warm, stylized, game-oriented, beginner-paced. His paid [Blender Pathway](https://www.gabbitt.co.uk/courses) course can serve as the structured spine | 1–2 wk |
| 2. Character modeling | **Box-modeling first, not sculpt+retopo** (see below). Grant Abbitt's [Low Poly Characters](https://www.gamedev.tv/p/low-poly-characters); CG Cookie's [BASEMESH stylized characters](https://cgcookie.com/courses/basemesh-create-stylized-characters-quickly-with-blender) (subscription) | 2–3 wk |
| 3. UV unwrapping | Learned in-context inside the character courses — don't study it in isolation | 3–5 days |
| 4. Hand-painted texturing | Blender's built-in Texture Paint mode (see "no Substance" note). Ryan King Art (YouTube) for stylized texturing; [written game-asset texture-paint guide](https://generalistprogrammer.com/tutorials/blender-texture-painting-complete-game-asset-tutorial) | 1–2 wk |
| 5. Rigging | Mixamo first, Rigify second (see Part 4). Blender Studio's free [Stylized Character Workflow](https://studio.blender.org/training/stylized-character-workflow/) + [Toon Character Workflow](https://studio.blender.org/training/toon-character-workflow/) for depth | ~1 wk |
| 6. Animation | Same Blender Studio courses; then just practice (idle + walk first) | 1–2 wk, ongoing |

**One paid course worth buying** (frequently ~90% off on Udemy):
[GameDev.tv "Blender Character Creator for Video Games"](https://gamedev.tv/courses/blender4-character-creator)
— end-to-end model → UV → bake → hand-paint → rig → pose, exactly this project's goal.

### Key workflow decisions (already researched — don't relitigate)
- **Box-model, don't sculpt+retopo, for the first characters.** Stylized game
  characters live on silhouette and clean animation-friendly topology; box modeling
  produces a usable game mesh directly and skips the retopology step that sinks
  beginners. Sculpting is the most "drawing-like" skill and will come easily later
  (optional rung 6 below) — it's just not the right *first* path.
- **Draw the model sheets first.** Front/side/¾ turnarounds, loaded into Blender as
  reference images. This is where 2D skill becomes the team's superpower — the
  character sheets in `docs/design/3d-model-sheets/` are the input to this step.
- **Texture-paint inside Blender; do not buy Substance Painter.** Substance is for
  PBR/realism. For the storybook style, Blender's Texture Paint (or painting in a 2D
  app over exported UV layouts — Procreate/Krita — and re-importing) is the right
  tool and free.
- **Polycount targets:** stylized hero character **~5–15k tris** (comfortable for
  PC+mobile URP); props/background **~1.3–3k**. A clean 2k-tri character with a good
  hand-painted texture beats a sloppy 50k one.

### Practice-project ladder (each rung adds exactly one skill)
1. **The Donut** — done when it's rendered without pausing the video every 5 seconds.
2. **A stylized prop** (treasure chest, storybook lantern) — done when it imports
   into Unity URP at correct scale with no texture stretching. *(This rung is where
   the two tracks can trade: same prop, compare results.)*
3. **A simple low-poly character** (Abbitt-style) — done at ~3–8k tris, hand-painted,
   no rig.
4. **Rig that character via Mixamo → Unity** — done when it walks in a URP scene as a
   Unity Humanoid at correct scale/orientation.
5. **An original character from her own model sheet**, Rigify-rigged, two hand-made
   clips (idle + walk) — done when it's in Unity ≤~10k tris with one 1–2k texture and
   reads as *this game's* style. **This rung is the audition piece for real Tarrock
   characters.**
6. *(Later, optional)* sculpt→retopo on an organic character (Blender Studio course)
   to unlock higher-detail heroes.

---

## Part 2 — Her track: Mac mini setup

- **Blender 5.2 LTS** from blender.org — Apple-Silicon-native, Metal viewport,
  Cycles-on-Metal all mature. For this project she'll mostly use Eevee/Workbench
  anyway (final look comes from Unity URP, not Blender renders).
- **RAM is the constraint that matters.** 8GB runs Blender but thrashes on
  sculpting (Apple unified memory = GPU shares it). 16GB+ is the comfortable floor.
  Apple RAM is fixed at purchase — if an upgrade is ever on the table, RAM is the
  entire decision.
- **Buy a cheap 3-button scroll-wheel mouse.** Blender navigation is built on
  middle-mouse; the Magic Mouse is genuinely painful. This ~$15 purchase is the
  biggest ergonomics win available. (Fallback: Preferences → Input → "Emulate 3
  Button Mouse", but it conflicts with Alt-based shortcuts.)
- **Enable Emulate Numpad** (Preferences → Input) if her keyboard has no numpad —
  Blender uses numpad 1/3/7 for front/side/top views constantly.
- **Her existing drawing tablet works and is an asset** for sculpt + texture paint
  (pressure sensitivity). Install the vendor's current macOS driver *before*
  launching Blender — that's the usual gotcha.

---

## Part 3 — His track: Fedora setup (this machine)

Verified hands-on 2026-07-22:

- The **Fedora rpm (`blender-5.1.2`) cannot GPU-render**: it ships no precompiled
  CUDA kernels (wants the full CUDA toolkit/nvcc at runtime — tested, fails) and has
  no OptiX support at all. Fine for modeling; wrong build for Cycles GPU.
- The **official blender.org tarball is the right install — INSTALLED &amp; VERIFIED
  2026-07-22**: `~/Apps/blender-5.2.0-linux-x64/blender` (Blender 5.2.0 LTS). Ships
  precompiled CUDA + OptiX kernels and dynamically loads the system's `libcuda` +
  `libnvoptix` (driver 610.43.03). Both OptiX and CUDA detect the 3070 Ti; a test
  OptiX render completed in 1.3s at 58°C/36W. Coexists with the rpm
  (`/usr/bin/blender` stays the modeling-only fallback). **Avoid the Flatpak** —
  sandbox needs a version-matched NVIDIA extension that may not exist for this
  driver.
- **The compute-only GPU config is exactly what Cycles needs.** Cycles is pure
  CUDA/OptiX compute (render farms run it with no display on the card at all);
  it never touches the blocked `nvidia_drm`/`nvidia_modeset` path. Viewport runs on
  Iris Xe (Mesa); F12 / Rendered-preview dispatches to the RTX 3070 Ti. Setup:
  Preferences → System → Cycles Render Devices → **OptiX** (fallback CUDA).
- **Iris Xe viewport** is fine for low/mid-poly stylized work (Solid/Workbench
  rock-solid; EEVEE-Next occasionally glitches on Xe — if it misbehaves, toggle the
  GL↔Vulkan backend in Preferences → System, or just work in Solid mode).
- **Thermals:** this is the *laptop* 3070 Ti — 115W cap (already set), not the
  desktop's 290W. GPU rendering is actually **kinder to the CPU** than CPU rendering
  (the i9 idles), but it's still ~115W of sustained heat through the same weak
  cooling loop. For long/animation renders: `sudo nvidia-smi -pm 1 && sudo
  nvidia-smi -pl 90` (check the legal range with `nvidia-smi -q -d POWER`), and the
  existing GSP watchdog + thermal watchdog stay on. The GSP watchdog will refuse to
  reset while Blender holds the device — a mid-render wedge needs a manual kill.

---

## Part 4 — Shared: the export-to-Unity recipe

- **Rigging path:** first characters via **Mixamo** (free web auto-rig + animation
  library; still works in 2026 but frozen/unmaintained — a shortcut, not a
  foundation). Graduate to **Rigify** (built into Blender) for custom animation.
  Rigify → Unity needs a converter to strip control bones:
  [Toyful Games tutorial](https://www.toyfulgames.com/blog/rigify-to-unity-tutorial),
  [AlexLemminG/Rigify-To-Unity](https://github.com/AlexLemminG/Rigify-To-Unity).
- **Unity Humanoid** auto-maps if the skeleton is humanoid-shaped: minimum bones
  Hips (root) / Spine / Chest / Head + limbs, named by body part
  ([Unity avatar docs](https://docs.unity3d.com/6000.2/Documentation/Manual/ConfiguringtheAvatar.html)).
  Mixamo naming maps cleanly.
- **FBX export settings:** Selected Objects (mesh + armature only) · Scale 1.0,
  Apply Scalings "FBX Units Scale" · Forward −Z, Up Y · Armature → **Only Deform
  Bones ON** · **Add Leaf Bones OFF** · Bake Animation ON (NLA/Actions → multiple
  clips; disable "Resample Curves" in Unity import).
- **The two classic failures** — 100× scale and a 90° X-rotation — both come from
  unapplied transforms. Object at origin, **Ctrl+A → apply rotation & scale** before
  every export.
- **Tarrock-specific:** imported stand-in scale contract lives in
  `docs/design/art-audio.md` §Current build (hex ≈ 4m, player ≈ 0.7m). Anything she
  makes gets tested against that contract in the sandbox scene like any other art.

---

## Part 5 — Streaming & revenue (her option, zero pressure)

**Minimum viable setup:** the Mac mini + OBS (native Apple Silicon, uses the
hardware video encoder — even a base M1 streams 1080p at ~25% CPU while Blender
runs) + **one decent USB mic (~$60–100; the single purchase that matters — viewers
forgive video, not audio)**. Facecam, lights, capture card: all genuinely optional.
Capture the **Blender window only**, not the full desktop (privacy + no notification
leaks; macOS will ask for Screen Recording permission once).

**Platform strategy (2026):** don't pick one — *stream on one, harvest for the rest*.
Live on **Twitch** (loyal art community, but near-zero discovery) or **TikTok Live**
(raw reach); **always record**; cut every session into **timelapse Shorts/TikToks**
and post the VOD to YouTube, where the back-catalog compounds for months. The
timelapse-to-shorts pipeline is the actual growth engine for art creators.

**Honest expectations:** art streaming grows slowly — single-digit concurrent
viewers for months, then a loyal handful. The recorded timelapses routinely
outperform the live numbers.

**Revenue, ranked by realism for a beginner:**
1. **Ko-fi tip jar** — day one, no threshold, ~0% platform cut on tips.
2. **Twitch Affiliate** — thresholds lowered in 2026 (25 followers, 4 stream days,
   3 avg viewers /30 days): reachable in weeks, pays little at first.
   **YouTube** early monetization at 500 subs; full at 1k subs + 4k watch-hours.
3. **Stylized asset packs** (Gumroad/itch.io keep ~90%+; Blender Market/FAB/Unity
   Asset Store have audiences but bigger cuts). What sells: cohesive themed
   modular kits in a consistent style, not one-off models. First packs realistically
   earn hundreds, not thousands — but practice output becomes inventory.
4. **Patreon / commissions** — real money later; both need an audience first.

**Safety basics (non-negotiable, any age):** streaming handle unconnected to real
name/location; dedicated email + separate 2FA number; never show real name, school/
local landmarks, schedules, or the desktop (window capture only, Do Not Disturb
while live); Twitch AutoMod on + a trusted mod early; if chat surfaces personal
info: delete, don't react, don't confirm. Streams get clipped — one second of
exposure is permanent.

---

## Part 6 — How this connects to the art pivot

The 2026-07-20 research priced a commissioned Fool at **$2.5–4k** because no asset
pack has on-pillar rigged characters. An in-house character artist changes that
equation entirely: the ladder above ends (rung 5) at exactly the skill needed, the
FANTASTIC environment packs remain compatible either way, and the KayKit stand-ins
+ swap discipline mean nothing blocks on her timeline. If it works out, she models
to her own drawn character sheets — which is also the strongest possible streaming
content ("designing a character for an actual game").

Royalty/payout terms are a director decision (worth one written page eventually,
even in-family). Not covered here.
