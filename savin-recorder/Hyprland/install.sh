#!/bin/bash
set -euo pipefail

# Directorio de vídeos universal
VIDDIR="$(xdg-user-dir VIDEOS)"

# Crear subdirectorios si no existen (importante para que Thunar no falle)
mkdir -p "$VIDDIR/GIFS" "$VIDDIR/MP4"
echo "📂 Carpetas de destino verificadas en $VIDDIR"

# Directorio de instalación de scripts
TARGET="$HOME/.config/hypr/savinsh"
mkdir -p "$TARGET"

# Copiar scripts al directorio destino (forzar actualización)
cp -f start.sh mp4.sh gif.sh "$TARGET"
echo "✅ Scripts instalados en $TARGET"

# Dar permisos de ejecución
chmod +x "$TARGET"/start.sh "$TARGET"/mp4.sh "$TARGET"/gif.sh
echo "🔧 Permisos de ejecución aplicados"

# Comprobar dependencias (Incluyendo Thunar)
# Añadimos xdg-user-dirs por si el usuario no tiene configurado el dir de Videos
for dep in wf-recorder slurp jq wl-copy ffmpeg notify-send thunar xdg-user-dir; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "⚠️  ATENCIÓN: Falta la dependencia '$dep'. Instálala para un funcionamiento total."
    else
        echo "✔ $dep detectado."
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
        CURRENT_BLOCK=$(sed -n '/# >>> SAVIN-RECORDER START >>>/,/# <<< SAVIN-RECORDER END <<</p' "$HYPRCONF")

        if [ "$CURRENT_BLOCK" != "$EXPECTED_BLOCK" ]; then
            echo "🔄 Actualizando bloque de configuración en Hyprland..."
            sed -i '/# >>> SAVIN-RECORDER START >>>/,/# <<< SAVIN-RECORDER END <<</d' "$HYPRCONF"
            printf "%s\n" "$EXPECTED_BLOCK" >> "$HYPRCONF"
            echo "✅ Configuración actualizada en $HYPRCONF"
        else
            echo "ℹ️ Hyprland ya está configurado correctamente."
        fi
    else
        echo "➕ Añadiendo bloque de configuración a Hyprland..."
        printf "\n%s\n" "$EXPECTED_BLOCK" >> "$HYPRCONF"
        echo "✅ Configuración añadida a $HYPRCONF"
    fi
else
    echo "⚠️ No se encontró $HYPRCONF. El autostart no funcionará."
fi

# Crear directorio sablinds y copiar savin-recorder.conf
SABLINDSDIR="$HOME/.config/hypr/sablinds"
mkdir -p "$SABLINDSDIR"

cp -f savin-recorder.conf "$SABLINDSDIR/"
echo "✅ savin-recorder.conf actualizado en $SABLINDSDIR"

# Mensaje final con resumen de atajos
echo -e "\n--- ✨ INSTALACIÓN COMPLETADA ✨ ---"
echo "Atajos configurados:"
echo "  • Super+Shift+R      -> Iniciar Selección"
echo "  • AltGr+G            -> Guardar GIF"
echo "  • AltGr+Shift+G      -> Abrir Carpeta GIFS (Thunar)"
echo "  • AltGr+H            -> Guardar MP4"
echo "  • AltGr+Shift+H      -> AØbrir Carpeta MP4 (Thunar)"
echo "---------------------------------------"