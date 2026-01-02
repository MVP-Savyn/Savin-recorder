#!/bin/bash
set -euo pipefail

# Directorio de vídeos universal
VIDDIR="$(xdg-user-dir VIDEOS)"

# Crear subdirectorios si no existen
mkdir -p "$VIDDIR/GIFS" "$VIDDIR/MP4"

# Directorio de instalación de scripts
TARGET="$HOME/.config/hypr/savinsh"
mkdir -p "$TARGET"

# Copiar scripts al directorio destino
cp start.sh mp4.sh gif.sh "$TARGET"

# Dar permisos de ejecución
chmod +x "$TARGET"/start.sh "$TARGET"/mp4.sh "$TARGET"/gif.sh

# Comprobar dependencias básicas
for dep in wf-recorder slurp jq wl-copy ffmpeg notify-send; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "⚠️ Falta dependencia: $dep"
    fi
done

# Añadir bloque de configuración a Hyprland
HYPRCONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRCONF" ]; then
    {
        echo "# >>> SAVIN-RECORDER START >>>"
        echo "#For Savin-recorder blinds ;)"
        echo "source = sablinds/savin-recorder.conf"
        echo "# <<< SAVIN-RECORDER END <<<"
    } >> "$HYPRCONF"
    echo "✅ Bloque Savin-recorder añadido a $HYPRCONF"
else
    echo "⚠️ No se encontró $HYPRCONF, asegúrate de tener Hyprland configurado."
fi

# Crear directorio sablinds y copiar savin-recorder.conf
SABLINDSDIR="$HOME/.config/hypr/sablinds"
mkdir -p "$SABLINDSDIR"

cp savin-recorder.conf "$SABLINDSDIR/"
echo "✅ Archivo savin-recorder.conf copiado a $SABLINDSDIR"

# Mensaje final
echo "✅ Instalación completada"
echo "Scripts instalados en: $TARGET"
echo "Vídeos se guardarán en: $VIDDIR/{GIFS,MP4}"
