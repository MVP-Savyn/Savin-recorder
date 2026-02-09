#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)/SavinRecorder"
TEMPFILE="$OUTDIR/temp_recording.mp4"

# 1. Detener FFmpeg
if [ -f /tmp/ffmpeg_rec.pid ]; then
    PID=$(cat /tmp/ffmpeg_rec.pid)
    kill -INT "$PID"
    rm /tmp/ffmpeg_rec.pid
    wait "$PID"
fi

[ ! -f "$TEMPFILE" ] && exit 1

STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
GIFFILE="$OUTDIR/GIFS/recording_${STAMP}.gif"

# 2. Lógica ShareX (idéntica para mantener calidad)
ffmpeg -i "$TEMPFILE" -vf "fps=15,scale=800:-1:flags=lanczos,palettegen" -y /tmp/palette.png
ffmpeg -i "$TEMPFILE" -i /tmp/palette.png -lavfi "fps=15,scale=800:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=sierra2_4a" -y "$GIFFILE"

# 3. Clipboard (X11)
LINK=$(curl -s -F "file=@$GIFFILE" https://tmpfiles.org/api/v1/upload | jq -r '.data.url' | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

if [ "$LINK" != "null" ]; then
    echo -n "$LINK" | xclip -selection clipboard
    notify-send "Savin-Recorder" "GIF Creado y Link copiado" -i camera-video
fi