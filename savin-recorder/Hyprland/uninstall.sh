#!/bin/bash
set -euo pipefail

echo "🚮 Desinstalando Savin-recorder..."

# Directorios específicos a eliminar
rm -rf "$HOME/.config/hypr/savinsh"
rm -rf "$HOME/.config/hypr/sablinds"

# Archivo de configuración de Hyprland
HYPRCONF="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPRCONF" ]; then
    # Elimina todo el bloque entre las marcas
    sed -i '/# >>> SAVIN-RECORDER START >>>/,/# <<< SAVIN-RECORDER END <<</d' "$HYPRCONF"
    echo "✅ Bloque Savin-recorder eliminado de $HYPRCONF"
else
    echo "⚠️ No se encontró $HYPRCONF"
fi

echo "✅ Desinstalación completada"
echo "Se han eliminado ~/.config/hypr/savinsh y ~/.config/hypr/sablinds"
echo "Las grabaciones en Vídeos se han conservado"
