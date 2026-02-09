#!/bin/bash
set -euo pipefail

# 1. Selección de región (X11 Style)
# xrectsel devuelve el formato WxH+X+Y
rect=$(xrectsel "%wx%h+%x+%y")
[ -z "$rect" ] && exit 0

# 2. Rutas
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder"
mkdir -p "$OUTDIR/GIFS" "$OUTDIR/MP4"
TEMPFILE="$OUTDIR/temp_recording.mp4"

# 3. Limpiar previo
[ -f "$TEMPFILE" ] && rm "$TEMPFILE"

# 4. Graba usando x11grab
# Parseamos el rect para FFmpeg
W=$(echo $rect | cut -d'x' -f1)
H=$(echo $rect | cut -d'x' -f2 | cut -d'+' -f1)
X=$(echo $rect | cut -d'+' -f2)
Y=$(echo $rect | cut -d'+' -f3)

ffmpeg -f x11grab -video_size "${W}x${H}" -i "${DISPLAY}+${X},${Y}" \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
    -f mp4 "$TEMPFILE" > /dev/null 2>&1 &

echo $! > /tmp/ffmpeg_rec.pid

notify-send "Savin-Recorder (X11)" "Grabando... 🔴\nAltGr+G (GIF) | AltGr+H (MP4)" -i camera-video