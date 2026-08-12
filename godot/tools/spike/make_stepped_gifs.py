#!/usr/bin/env python3
"""Assemble the anim-stepped spike's captured frames into looping GIFs.

    python3 tools/spike/make_stepped_gifs.py OUTDIR

OUTDIR is the directory tools/spike/capture_stepped.gd wrote its per-layout
frame folders into (OUTDIR/<layout>/frame-####.png); the GIFs land beside
them, named per the anim-stepped brief's deliverable list:

    compare      -> stepped_compare.gif
    compare_2x   -> stepped_compare_2x.gif
    <mode>       -> <mode>.gif   (smooth, stepped_12, stepped_8, stepped_6,
                                   stepped_8_jitter)

Every captured frame is already fully opaque (the stage paints its own sky/
ground background), and every layout is a uniform 25 fps - the STEPPED
variants "step" by holding a pose across several consecutive frames while
the walker keeps sliding, not by varying the GIF's per-frame delay. So this
assembler only has one job: turn N same-size PNGs into one looping GIF,
sharing a single palette across the whole clip so the ground and background
don't flicker frame to frame (a per-frame adaptive palette does, badly,
right when you're trying to judge whether the JITTER mode reads as noise).
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

FPS = 25.0
DURATION_MS = round(1000.0 / FPS)  # 40ms/frame - matches the capture harness.

NAMES = {
    "compare": "stepped_compare.gif",
    "compare_2x": "stepped_compare_2x.gif",
}


def build_gif(frame_paths: list[Path], out_path: Path) -> None:
    frames = [Image.open(p).convert("RGB") for p in frame_paths]

    # Shared palette: quantise a strip of evenly-sampled frames together, so
    # every frame in the clip is remapped through the SAME 256 colours.
    # Dithering is off on purpose - dither noise would be indistinguishable
    # from the thing the jitter mode is being judged on.
    sample_stride = max(1, len(frames) // 8)
    sample = frames[::sample_stride][:8]
    strip = Image.new("RGB", (sum(im.width for im in sample), max(im.height for im in sample)))
    x = 0
    for im in sample:
        strip.paste(im, (x, 0))
        x += im.width
    palette_source = strip.quantize(colors=255, method=Image.MEDIANCUT)

    quantized = [im.quantize(palette=palette_source, dither=Image.NONE) for im in frames]
    quantized[0].save(
        out_path,
        save_all=True,
        append_images=quantized[1:],
        duration=DURATION_MS,
        loop=0,
        disposal=2,
    )


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("usage: make_stepped_gifs.py OUTDIR")
    out_dir = Path(sys.argv[1])

    for layout_dir in sorted(p for p in out_dir.iterdir() if p.is_dir()):
        frames = sorted(layout_dir.glob("frame-*.png"))
        if not frames:
            continue
        gif_name = NAMES.get(layout_dir.name, f"{layout_dir.name}.gif")
        gif_path = out_dir / gif_name
        build_gif(frames, gif_path)
        size_kb = gif_path.stat().st_size / 1024.0
        print(f"{gif_name:28s} {len(frames):3d} frames  {size_kb:7.1f} KiB")


if __name__ == "__main__":
    main()
