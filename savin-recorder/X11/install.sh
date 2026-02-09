#!/bin/bash
set -euo pipefail

TARGET="$HOME/.config/savin-recorder/scripts"
mkdir -p "$TARGET"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/GIFS"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/MP4"

cp -f start.sh gif.sh mp4.sh "$TARGET/"
chmod +x "$TARGET"/*.sh

# Comprobar herramientas X11
deps=(ffmpeg xrectsel xclip jq notify-send)
for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "⚠️  Falta: $dep (Obligatorio para X11)"
    fi
done

echo "✅ Scripts instalados en $TARGET"
echo "👉 En X11, configura tus atajos manualmente apuntando a estos scripts."