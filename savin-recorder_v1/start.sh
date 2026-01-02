#!/bin/bash
set -euo pipefail

# Selección de región con slurp
rect=$(slurp)

# Directorio de salida universal (independiente del idioma)
OUTDIR="$(xdg-user-dir VIDEOS)"

# Graba en MP4 (H.264 software + AAC 128 kbps, alto bitrate) como archivo temporal
wf-recorder --pixel-format yuv420p -g "$rect" \
    -c libx264 -C aac -a -b:a 128k -b:v 20M -f "$OUTDIR/GIFS/temp.mp4" &

echo $! > /tmp/wfrecorder.pid

# Notificación con las teclas de exportación
notify-send "Grabación iniciada" \
"Pulsa AltGr+G para exportar a GIF\nPulsa AltGr+H para exportar a Mp4"

