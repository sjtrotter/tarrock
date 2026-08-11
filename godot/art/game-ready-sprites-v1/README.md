# Tarrock MQ00 sprite prototype

Engine-neutral transparent PNG sprite pack for Godot or Unity.

## Contents

- `atlases/`: ready-to-slice transparent atlases.
- `frames/`: every atlas pre-sliced into individually named PNG frames.
- `source/`: original chroma-key generations and normalized intermediates.
- `manifest.json`: atlas dimensions, cell sizes, frame order, and suggested timing.

## Atlas layout

- Direction atlases: 1536×1024, 4 columns × 2 rows, 384×512 cells.
- Action atlases: 1280×1280, 4 columns × 4 rows, 320×320 cells.
- Cliff terrain and prop atlases: 1280×1280, 4 columns × 4 rows, 320×320 cells.
- Direction order is row-major: south, southwest, west, northwest, north, northeast, east, southeast.
- Action order and suggested playback are defined in `manifest.json`.

## Import notes

All final atlas and frame PNGs use straight alpha and have transparent corners. Keep filtering enabled for the painted style. Use the bottom-center of each cell as the logical ground anchor; adjust the visual pivot per character if the engine importer needs an exact foot point.

The directional sheets are static facing references suitable for idle/facing states. The action sheets provide four-frame southeast-facing prototype cycles. Other directional action cycles should be authored from these approved identities once the gameplay camera and target on-screen scale are locked.

These are usable prototype assets, but generative frame-to-frame details should receive an artist consistency pass before final shipping animation.

The Cliff terrain atlas contains organic patch sprites rather than a mathematically seamless Wang/bitmask set. It is ready for hand-placed prototype composition; a final auto-tiling production set should be redrawn after the ground footprint and navigation scale are tested in-engine.
