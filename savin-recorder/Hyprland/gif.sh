#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)"
mkdir -p "$OUTDIR/GIFS"
TEMPFILE="$OUTDIR/GIFS/temp.mp4"

# Detener wf-recorder
if [ -f /tmp/wfrecorder.pid ]; then
    PID=$(cat /tmp/wfrecorder.pid)
    kill -INT "$PID"
    rm /tmp/wfrecorder.pid
    wait "$PID"
fi

STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
GIFFILE="$OUTDIR/GIFS/recording_${STAMP}.gif"

sleep 0.3

ffmpeg -i "$TEMPFILE" \
  -vf "mpdecimate,fps=12,scale=iw*0.8:-1:flags=lanczos,palettegen=max_colors=32:stats_mode=diff" \
  -y "$OUTDIR/GIFS/palette.png"

ffmpeg -i "$TEMPFILE" -i "$OUTDIR/GIFS/palette.png" \
  -lavfi "mpdecimate,fps=12,scale=iw*0.8:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=1:diff_mode=rectangle" \
  -y "$GIFFILE"

# --- SUBIDA Y NOTIFICACIÓN ---
LINK=$(curl -s -F "file=@$GIFFILE" https://tmpfiles.org/api/v1/upload \
  | jq -r '.data.url' \
  | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

if [ "$LINK" != "null" ]; then
    echo -n "$LINK" | wl-copy
    notify-send "Grabación finalizada" "Enlace copiado al portapapeles"
    echo "Enlace directo: $LINK"
else
    notify-send "Error" "No se pudo subir el archivo."
fi