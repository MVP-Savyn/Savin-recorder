#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder"
TEMPFILE="$OUTDIR/temp_recording.mp4"

# 1. Detener wf-recorder si está corriendo
if [ -f /tmp/wfrecorder.pid ]; then
    PID=$(cat /tmp/wfrecorder.pid)
    kill -INT "$PID"
    rm /tmp/wfrecorder.pid
    wait "$PID"
fi

[ ! -f "$TEMPFILE" ] && notify-send "Error" "No hay grabación temporal" && exit 1

STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
GIFFILE="$OUTDIR/GIFS/recording_${STAMP}.gif"

sleep 0.5

# 2. Generar GIF (Usa el TEMPFILE pero no lo toca)
ffmpeg -i "$TEMPFILE" -vf "fps=15,scale=800:-1:flags=lanczos,palettegen" -y /tmp/palette.png
ffmpeg -i "$TEMPFILE" -i /tmp/palette.png -lavfi "fps=15,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=sierra2_4a" -y "$GIFFILE"

# 3. Subida
LINK=$(curl -s -F "file=@$GIFFILE" https://tmpfiles.org/api/v1/upload | jq -r '.data.url' | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

if [ "$LINK" != "null" ]; then
    echo -n "$LINK" | wl-copy
    notify-send "Savin-Recorder" "GIF Creado y Link copiado" -i camera-video
else
    notify-send "Savin-Recorder" "GIF Guardado localmente"
fi