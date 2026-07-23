# Foliage Wind

Vertex-sway wind for the stand-in KayKit hex-diorama foliage. Realises the art-direction
canon (`docs/design/art-audio.md` §The world-state is the art direction): a **bound** region
holds its breath (no wind); once its Arcana is **unbound**, motion returns to the foliage.

No rigs, no armatures — the motion is pure shader vertex sway, masked by object-space height
(stiff at the base, most motion at the crown). Works on arbitrary static foliage meshes with
no vertex-colour authoring; meshes that later add a sway mask in vertex-colour alpha have it
folded in automatically (absent colour streams read `(1,1,1,1)`, a safe no-op).

## Files

- `FoliageWind.shader` — shader `Tarrock/FoliageWind` (ForwardLit + ShadowCaster + DepthOnly,
  all sharing one sway function so shadows/depth track the sway).
- `../Scripts/Regions/RegionWind.cs` — `Tarrock.Regions.RegionWind`, drives the global scalar.
- `../Scripts/Editor/FoliageWindInstaller.cs` — `Tarrock/Setup/Install Foliage Wind` menu.

## The global

`_TarrockWindStrength` (float) — set **only** via `Shader.SetGlobalFloat`, never per-material.
Every foliage material multiplies all displacement by it, so one write per frame sweeps the
whole region. `0` = bound/still (the shader is then a plain static-foliage shader); `1` = full
unbound wind. `RegionWind` owns this value and lerps it on unbind.

## Per-material properties

| Property | Meaning |
|---|---|
| `_BaseMap`, `_BaseColor` | Surface, copied from the source KayKit material by the installer. |
| `_AlphaClip` (toggle) + `_Cutoff` | Alpha-clip for foliage cards; installer enables it when the source alpha-clips. |
| `_SwayAmplitude`, `_SwayFrequency` | Broad low-frequency lean (world metres at the masked tip). |
| `_FlutterAmplitude`, `_FlutterFrequency` | Small high-frequency leaf shiver layered on top. |
| `_HeightMaskStart` | Object-space Y below which the plant is held rigid (KayKit pivots at the base). |
| `_HeightMaskExponent` | How sharply the sway mask ramps from base to crown. |

Each instance is phase-offset by its world position, so a grove never sways in lockstep.

> **Amplitude note:** the height mask uses raw object-space height, so a mesh with a taller
> native (pre-scale) height sways proportionally more for the same amplitude. Tune amplitudes
> per material if a species reads too strong/weak; the global still scales everything together.

## Usage (two lines)

1. Add a `RegionWind` component to the region scene and set its `Region State Id` to the
   region's `WS_*` flag (a `Tarrock.WorldState.WorldStateIds` value).
2. Run **`Tarrock/Setup/Install Foliage Wind`** — swaps the scene's `tree_*` / `bush_*` /
   `tuft_*` foliage onto `Tarrock/FoliageWind` (wind-variant material copies under
   `Assets/_Project/Materials/Wind/`; the vendored KayKit materials are never edited in place).

`RegionWind` reads world state through `CompositionRoot.Instance.WorldState` — the initial
state on load (order-independent) plus the `StateFired` event for the live unbind. With no
Bootstrap in the scene (a region opened directly), toggle **Editor Override** on the component
to scrub wind by hand. The installer is idempotent; re-running never double-swaps.
