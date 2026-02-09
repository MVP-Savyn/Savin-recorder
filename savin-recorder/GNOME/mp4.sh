#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder/MP4"
mkdir -p "$OUTDIR"
TEMPFILE="$(xdg-user-dir VIDEOS)/SavinRecorder/temp_recording.mp4"

# 1. Detener wf-recorder
if [ -f /tmp/wfrecorder.pid ]; then
    PID=$(cat /tmp/wfrecorder.pid)
    kill -INT "$PID"
    rm /tmp/wfrecorder.pid
    wait "$PID"
fi

[ ! -f "$TEMPFILE" ] && notify-send "Error" "No hay grabación temporal" && exit 1

STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FINALFILE="$OUTDIR/rec_${STAMP}.mp4"

# 2. COPIAR en lugar de mover para mantener el temp.mp4 activo
cp "$TEMPFILE" "$FINALFILE"

# 3. Subida
LINK=$(curl -s -F "file=@$FINALFILE" https://tmpfiles.org/api/v1/upload | jq -r '.data.url' | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

if [ "$LINK" != "null" ]; then
    echo -n "$LINK" | wl-copy
    notify-send "Savin-Recorder" "MP4 Exportado y Link copiado" -i video-x-generic
else
    notify-send "Savin-Recorder" "MP4 Exportado a la carpeta"
fi