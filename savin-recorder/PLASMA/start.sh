#!/bin/bash
set -euo pipefail

# 1. Selección de región
rect=$(slurp -b "#00000055" -c "#ffffff" -w 2)
[ -z "$rect" ] && exit 0

# 2. Rutas
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder"
mkdir -p "$OUTDIR/GIFS" "$OUTDIR/MP4"
TEMPFILE="$OUTDIR/temp_recording.mp4"

# 3. AQUÍ sí eliminamos el anterior para que la nueva grabación sea limpia
[ -f "$TEMPFILE" ] && rm "$TEMPFILE"

# 4. Graba
wf-recorder --pixel-format yuv420p -g "$rect" \
    -c libx264 -C aac -a -b:a 128k -f "$TEMPFILE" > /dev/null 2>&1 &

echo $! > /tmp/wfrecorder.pid

notify-send "Savin-Recorder" "Grabando área... 🔴\nAltGr+G (GIF) | AltGr+H (MP4)" -i camera-video