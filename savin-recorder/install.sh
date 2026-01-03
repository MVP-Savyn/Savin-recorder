#!/bin/bash
set -euo pipefail

# Directorio de vídeos universal
VIDDIR="$(xdg-user-dir VIDEOS)"

# Crear subdirectorios si no existen
mkdir -p "$VIDDIR/GIFS" "$VIDDIR/MP4"

# Directorio de instalación de scripts
TARGET="$HOME/.config/hypr/savinsh"
mkdir -p "$TARGET"

# Copiar scripts al directorio destino (forzar actualización)
cp -f start.sh mp4.sh gif.sh "$TARGET"
echo "✅ Scripts start.sh, mp4.sh y gif.sh instaladas en $TARGET"

# Dar permisos de ejecución
chmod +x "$TARGET"/start.sh "$TARGET"/mp4.sh "$TARGET"/gif.sh
echo "🔧 Permisos de ejecución aplicados a los scripts"

# Comprobar dependencias básicas
for dep in wf-recorder slurp jq wl-copy ffmpeg notify-send; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "⚠️ Falta dependencia: $dep"
    fi
done

# Añadir o actualizar bloque de configuración en Hyprland
HYPRCONF="$HOME/.config/hypr/hyprland.conf"
EXPECTED_BLOCK=$(cat << 'EOF'
# >>> SAVIN-RECORDER START >>>
#For Savin-recorder blinds ;)
source = sablinds/savin-recorder.conf
# <<< SAVIN-RECORDER END <<<
EOF
)

if [ -f "$HYPRCONF" ]; then
    if grep -q "# >>> SAVIN-RECORDER START >>>" "$HYPRCONF"; then
        # Extraer bloque actual
        CURRENT_BLOCK=$(sed -n '/# >>> SAVIN-RECORDER START >>>/,/# <<< SAVIN-RECORDER END <<</p' "$HYPRCONF")

        if [ "$CURRENT_BLOCK" != "$EXPECTED_BLOCK" ]; then
            echo "🔄 Bloque encontrado pero desactualizado. Actualizando…"

            # Eliminar bloque viejo
            sed -i '/# >>> SAVIN-RECORDER START >>>/,/# <<< SAVIN-RECORDER END <<</d' "$HYPRCONF"

            # Añadir bloque nuevo
            printf "%s\n" "$EXPECTED_BLOCK" >> "$HYPRCONF"

            echo "✅ Bloque actualizado en $HYPRCONF"
        else
            echo "ℹ️ El bloque ya está actualizado. No se modifica."
        fi
    else
        echo "➕ Bloque no encontrado. Añadiéndolo…"
        printf "%s\n" "$EXPECTED_BLOCK" >> "$HYPRCONF"
        echo "✅ Bloque añadido a $HYPRCONF"
    fi
else
    echo "⚠️ No se encontró $HYPRCONF, asegúrate de tener Hyprland configurado."
fi

# Crear directorio sablinds y copiar savin-recorder.conf (forzar actualización)
SABLINDSDIR="$HOME/.config/hypr/sablinds"
mkdir -p "$SABLINDSDIR"

cp -f savin-recorder.conf "$SABLINDSDIR/"
echo "✅ Archivo savin-recorder.conf actualizado en $SABLINDSDIR"

# Mensaje final
echo "✅ Instalación completada"
echo "Vídeos se guardarán en: $VIDDIR/{GIFS,MP4}"
