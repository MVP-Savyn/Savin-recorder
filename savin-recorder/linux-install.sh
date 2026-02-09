#!/bin/bash
set -e

echo "--- SAVIN-RECORDER: Instalador Global ---"

# 1. DETECTAR SERVIDOR GRÁFICO (Wayland o X11)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    SESSION="wayland"
else
    SESSION="x11"
fi

# 2. DETECTAR ESCRITORIO (DE)
# Pasamos todo a minúsculas para evitar errores
DESKTOP=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

echo "🔍 Sistema detectado: $DESKTOP sobre $SESSION"

# 3. LÓGICA DE DIRECCIONAMIENTO
TARGET_DIR=""

if [[ "$DESKTOP" == *"hyprland"* ]]; then
    TARGET_DIR="Hyprland"
elif [[ "$DESKTOP" == *"gnome"* ]]; then
    TARGET_DIR="GNOME"
elif [[ "$DESKTOP" == *"kde"* || "$DESKTOP" == *"plasma"* ]]; then
    # Plasma puede ser Wayland o X11, lo tratamos en su carpeta
    TARGET_DIR="PLASMA"
elif [ "$SESSION" == "x11" ]; then
    # Si no es ninguno de los anteriores pero es X11 (i3, bspwm, Xfce...)
    TARGET_DIR="X11"
else
    echo "❌ Error: Entorno no soportado automáticamente."
    exit 1
fi

# 4. EJECUCIÓN DEL INSTALADOR REAL
if [ -d "./$TARGET_DIR" ]; then
    echo "🚀 Iniciando instalación para $TARGET_DIR..."
    chmod +x "$TARGET_DIR/install.sh"
    cd "$TARGET_DIR" && ./install.sh
else
    echo "❌ Error: No se encontró la carpeta $TARGET_DIR en el repositorio."
    exit 1
fi