#!/usr/bin/env python3
"""Shared cutting helpers for the animation spike's cutout segmentation.

Deliberately rough. These masks are hand-authored polygons over the painting's
alpha, because the spike judges MOTION, not craft, and a colour-based
segmentation of a painterly figure spends hours to arrive somewhere no better.

Coordinates everywhere are "crop space": the source's alpha bounding box, with
the origin of the rig at some ground point inside it.
"""

from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

INK = np.array([46, 30, 20, 255], dtype=np.float32)


class Cutter:
    """One source facing, cut into parts."""

    def __init__(self, source: str, crop: tuple, origin: tuple, out_dir: str) -> None:
        self.source = source
        self.crop = crop
        self.origin = origin
        self.out_dir = out_dir
        image = Image.open(source).convert("RGBA").crop(crop)
        self.rgba = np.array(image).astype(np.int16)
        self.W = crop[2] - crop[0]
        self.H = crop[3] - crop[1]
        self.alpha = self.rgba[..., 3] > 8
        self.yy, self.xx = np.mgrid[0 : self.H, 0 : self.W]
        self.parts: dict = {}
        os.makedirs(out_dir, exist_ok=True)

    # --- masks -------------------------------------------------------------

    def poly(self, points: list) -> np.ndarray:
        stencil = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(stencil).polygon(points, fill=255)
        return np.array(stencil) > 127

    def ellipse(self, cx: float, cy: float, rx: float, ry: float) -> np.ndarray:
        stencil = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(stencil).ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
        return np.array(stencil) > 127

    def grow(self, mask: np.ndarray, steps: int, limit: np.ndarray) -> np.ndarray:
        out = mask.copy()
        for _ in range(steps):
            grown = out.copy()
            grown[1:, :] |= out[:-1, :]
            grown[:-1, :] |= out[1:, :]
            grown[:, 1:] |= out[:, :-1]
            grown[:, :-1] |= out[:, 1:]
            out = grown & limit
        return out

    # --- repair ------------------------------------------------------------

    def fill_holes(self, keep: np.ndarray, hole: np.ndarray) -> np.ndarray:
        """Row-wise nearest-known-pixel fill, then a soft blur over the patch.

        Averaging four-neighbours (the obvious approach) drags the black ink
        outlines into the patch and turns the tunic into a bruise. Copying the
        nearest *cloth* pixel along the row keeps the colour, at the cost of
        horizontal streaks - fine, since the patch lives behind an arm.
        """
        out = self.rgba.copy()
        todo = hole & ~keep
        luma = (self.rgba[..., 0] * 2 + self.rgba[..., 1] * 3 + self.rgba[..., 2]) // 6
        source = keep & (luma > 70)
        for y in range(self.H):
            known_x = np.nonzero(source[y])[0]
            if len(known_x) == 0:
                continue
            for x in np.nonzero(todo[y])[0]:
                out[y, x] = out[y, known_x[np.argmin(np.abs(known_x - x))]]
        blurred = np.array(
            Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").filter(
                ImageFilter.GaussianBlur(3.5)
            )
        ).astype(np.int16)
        out[todo] = blurred[todo]
        return out

    def ink_cut_edge(
        self, rgba: np.ndarray, mask: np.ndarray, side: str, width: int = 2
    ) -> np.ndarray:
        """Darken a sliced edge so it reads as a contour, not a knife mark."""
        out = rgba.copy()
        stroke = np.zeros_like(mask)
        for row in range(self.H):
            cols = np.nonzero(mask[row])[0]
            if len(cols) == 0:
                continue
            if side == "left":
                stroke[row, cols[0] : cols[0] + width] = True
            else:
                stroke[row, max(cols[-1] - width + 1, 0) : cols[-1] + 1] = True
        out[stroke] = (out[stroke] * 0.3 + INK * 0.7).astype(np.int16)
        return out

    # --- output ------------------------------------------------------------

    def save_part(
        self, name: str, rgba: np.ndarray, mask: np.ndarray, pivot: tuple
    ) -> None:
        ys, xs = np.nonzero(mask)
        if len(xs) == 0:
            raise SystemExit("empty mask for part " + name)
        x0, x1 = int(xs.min()), int(xs.max()) + 1
        y0, y1 = int(ys.min()), int(ys.max()) + 1
        sub = rgba[y0:y1, x0:x1].copy()
        sub[~mask[y0:y1, x0:x1]] = 0
        Image.fromarray(np.clip(sub, 0, 255).astype(np.uint8), "RGBA").save(
            os.path.join(self.out_dir, name + ".png")
        )
        self._record(name, (x1 - x0, y1 - y0), (x0, y0), pivot)

    def save_scaled_variant(
        self, base: str, name: str, scale_x: float, scale_y: float
    ) -> None:
        """A second drawing of an existing part, resampled about its pivot.

        This is the hybrid frame-and-rig cheat the south facing needs: a foot
        that swings towards the camera cannot be a rotated bone, so the rig
        swaps between a small set of drawn foot positions instead.
        """
        part = self.parts[base]
        image = Image.open(os.path.join(self.out_dir, part["file"]))
        width = max(int(round(image.width * scale_x)), 1)
        height = max(int(round(image.height * scale_y)), 1)
        resized = image.resize((width, height), Image.LANCZOS)
        resized.save(os.path.join(self.out_dir, name + ".png"))
        pivot = part["pivot"]
        # Keep the pivot on the same spot of the drawing after the resample.
        origin = (
            pivot[0] + (part["origin"][0] - pivot[0]) * scale_x,
            pivot[1] + (part["origin"][1] - pivot[1]) * scale_y,
        )
        self._record(name, (width, height), origin, tuple(pivot))

    def _record(self, name: str, size: tuple, origin: tuple, pivot: tuple) -> None:
        self.parts[name] = {
            "file": name + ".png",
            "size": [int(size[0]), int(size[1])],
            "origin": [float(origin[0]), float(origin[1])],
            "pivot": [float(pivot[0]), float(pivot[1])],
            # Sprite2D.offset when the node sits on the pivot, centered = false.
            "offset": [float(origin[0] - pivot[0]), float(origin[1] - pivot[1])],
            # Node position in rig space (the origin is the ground point).
            "rig_position": [
                float(pivot[0] - self.origin[0]),
                float(pivot[1] - self.origin[1]),
            ],
        }

    def write(self, note: str, extra: dict | None = None) -> None:
        meta = {
            "source": os.path.relpath(self.source, os.path.dirname(self.out_dir)),
            "crop": list(self.crop),
            "crop_size": [self.W, self.H],
            "origin": list(self.origin),
            "note": note,
            "parts": self.parts,
        }
        if extra:
            meta.update(extra)
        with open(os.path.join(self.out_dir, "parts.json"), "w") as handle:
            json.dump(meta, handle, indent=2)
        for name, part in self.parts.items():
            print(
                "%-16s size=%-11s origin=%-16s pivot=%s"
                % (name, tuple(part["size"]), tuple(part["origin"]), tuple(part["pivot"]))
            )
