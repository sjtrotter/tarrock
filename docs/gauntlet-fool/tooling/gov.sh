#!/usr/bin/env bash
# Governor-gated single-lane Blender launcher for R15 Phase B.
set -euo pipefail
while grep -q 'PAUSE' /tmp/tarrock-governor/slots 2>/dev/null; do
  echo "[gov] PAUSE -> polling 15s"; sleep 15
done
echo "[gov] slots=$(cat /tmp/tarrock-governor/slots 2>/dev/null || echo n/a)"
load=$(awk '{print $1}' /proc/loadavg)
awk -v x="$load" 'BEGIN { if (x >= 6) { print "loadavg gate failed: " x > "/dev/stderr"; exit 1 } }'
echo "[gov] loadavg=$load"
tmax=$(for f in /sys/class/thermal/thermal_zone*/temp; do [ -r "$f" ] && cat "$f" 2>/dev/null || true; done | sort -nr | head -1)
if [ -n "$tmax" ] && [ "$tmax" -ge 90000 ]; then echo "thermal gate failed: $tmax" >&2; exit 1; fi
echo "[gov] tempmax=${tmax:-n/a}"
if pgrep -x blender >/dev/null; then echo "another blender is running; refusing" >&2; exit 1; fi
exec blender --background "$@"
