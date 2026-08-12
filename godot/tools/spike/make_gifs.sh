#!/usr/bin/env bash
# Assemble the animation spike's captured frames into looping GIFs.
#
#   tools/spike/make_gifs.sh OUTDIR
#
# OUTDIR is the directory tools/spike/capture_spike.gd wrote its per-layout
# frame folders into; the GIFs land beside them.
#
# 25 fps -> a 4 centisecond frame delay, which GIF can express exactly. Do not
# "improve" this to 30 fps: GIF delays are whole centiseconds, so 30 fps would
# play back 11% fast and this spike is an argument about timing.
set -euo pipefail

OUT="${1:?usage: make_gifs.sh OUTDIR}"
DELAY=4

shopt -s nullglob
for dir in "$OUT"/*/; do
	name="$(basename "$dir")"
	frames=("$dir"frame-*.png)
	[ ${#frames[@]} -gt 0 ] || continue
	magick -delay "$DELAY" -loop 0 "${frames[@]}" \
		-layers OptimizeTransparency "$OUT/$name.gif"
	printf '%-22s %3d frames  %s\n' "$name" "${#frames[@]}" \
		"$(du -h "$OUT/$name.gif" | cut -f1)"
done

# The small-fidelity variants are unreadable at 1:1 in a document, so also
# publish nearest-neighbour blow-ups. Nearest, not smooth: the point is to see
# exactly which pixels survived the downscale.
for name in painted_40 painted_40_post painted_60; do
	dir="$OUT/$name"
	[ -d "$dir" ] || continue
	frames=("$dir"/frame-*.png)
	magick -delay "$DELAY" -loop 0 "${frames[@]}" \
		-filter point -resize 300% -layers OptimizeTransparency \
		"$OUT/${name}-3x-nearest.gif"
	printf '%-22s %s\n' "${name}-3x-nearest" "$(du -h "$OUT/${name}-3x-nearest.gif" | cut -f1)"
done
