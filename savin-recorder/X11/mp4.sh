#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder/MP4"
mkdir -p "$OUTDIR"
TEMPFILE="$(xdg-user-dir VIDEOS)/SavinRecorder/temp_recording.mp4"

# 1. Detener FFmpeg (Grabación activa)
if [ -f /tmp/ffmpeg_rec.pid ]; then
    PID=$(cat /tmp/ffmpeg_rec.pid)
    kill -INT "$PID"
    rm /tmp/ffmpeg_rec.pid
    wait "$PID"
fi

[ ! -f "$TEMPFILE" ] && notify-send "Error" "No hay grabación temporal" && exit 1

STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FINALFILE="$OUTDIR/rec_${STAMP}.mp4"

# 2. OPTIMIZACIÓN DE VIDEO (H.264 ShareX Style)
# -crf 23: Balance perfecto calidad/peso (más alto = menos peso)
# -preset slow: Mejor compresión
# -pix_fmt yuv420p: Máxima compatibilidad con navegadores y Discord
notify-send "Savin-Recorder" "Optimizando MP4..." -i video-x-generic

ffmpeg -i "$TEMPFILE" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -pix_fmt yuv420p -y "$FINALFILE"

# 3. SUBIDA Y CLIPBOARD
LINK=$(curl -s -F "file=@$FINALFILE" https://tmpfiles.org/api/v1/upload | jq -r '.data.url' | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

if [ "$LINK" != "null" ]; then
    echo -n "$LINK" | xclip -selection clipboard
    notify-send "Savin-Recorder" "MP4 Optimizado y Link copiado" -i video-x-generic
else
    notify-send "Savin-Recorder" "MP4 Guardado en carpeta MP4" -i video-x-generic
fi