#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)"
TEMPFILE="$OUTDIR/GIFS/temp.mp4"

# Detener wf-recorder
PID=$(cat /tmp/wfrecorder.pid)
kill -INT "$PID"
rm /tmp/wfrecorder.pid
wait "$PID"

# Renombrar archivo temporal con timestamp para el GIF
STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
GIFFILE="$OUTDIR/GIFS/recording_${STAMP}.gif"

sleep 0.3

# Generar paleta optimizada a 15 fps, escala nativa
ffmpeg -i "$TEMPFILE" -vf "fps=15,palettegen=max_colors=256" -y "$OUTDIR/GIFS/palette.png"

# Convertir a GIF con dithering avanzado (sierra2_4a) a 15 fps, escala nativa
ffmpeg -i "$TEMPFILE" -i "$OUTDIR/GIFS/palette.png" \
  -lavfi "fps=15 [x]; [x][1:v] paletteuse=dither=sierra2_4a" \
  -y "$GIFFILE"

# Comprimir sin pérdida con gifsicle
gifsicle -O3 "$GIFFILE" -o "$GIFFILE"

# Subir a Tmpfiles.org y transformar el enlace al formato /dl/
LINK=$(curl -s -F "file=@$GIFFILE" https://tmpfiles.org/api/v1/upload \
  | jq -r '.data.url' \
  | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

# Copiar al portapapeles
echo -n "$LINK" | wl-copy

# Notificación en el sistema
notify-send "Grabación detenida" "Archivo: $GIFFILE\nEnlace directo: $LINK"

# Mostrar en terminal también
echo "Enlace directo: $LINK"
