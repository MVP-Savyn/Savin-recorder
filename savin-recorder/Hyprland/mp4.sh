#!/bin/bash
OUTDIR="$(xdg-user-dir VIDEOS)"
TEMPFILE="$OUTDIR/GIFS/temp.mp4"   # archivo temporal grabado en MP4 por wf-recorder

# Detener wf-recorder
PID=$(cat /tmp/wfrecorder.pid)
kill -INT "$PID"
rm /tmp/wfrecorder.pid
wait "$PID"

# Renombrar archivo final con timestamp
STAMP=$(date +"%Y-%m-%d_%H-%M-%S")
MP4FILE="$OUTDIR/MP4/recording_${STAMP}.mp4"

sleep 0.3

# Exportar directamente (mover archivo temporal)
mv "$TEMPFILE" "$MP4FILE"

# Subir a Tmpfiles.org y obtener enlace directo (/dl/)
MP4LINK=$(curl -s -F "file=@$MP4FILE" https://tmpfiles.org/api/v1/upload \
  | jq -r '.data.url' \
  | sed 's#tmpfiles.org/#tmpfiles.org/dl/#')

# Copiar al portapapeles
echo -n "$MP4LINK" | wl-copy

# Notificación en el sistema
notify-send "Grabación detenida" "Archivo: $MP4FILE\nEnlace directo: $MP4LINK"

# Mostrar en terminal también
echo "Enlace directo MP4: $MP4LINK"
