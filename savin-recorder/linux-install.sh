#!/bin/bash
set -euo pipefail

echo "--- SAVIN-RECORDER GLOBAL INSTALLER ---"

# 1. Crear estructura base de directorios
TARGET_SCRIPTS="$HOME/.config/savin-recorder/scripts"
mkdir -p "$TARGET_SCRIPTS"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/GIFS"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/MP4"

# 2. Detectar Gestor de Paquetes y dependencias
if command -v pacman >/dev/null; then
    INSTALL="sudo pacman -S --noconfirm --needed"
elif command -v apt-get >/dev/null; then
    INSTALL="sudo apt-get install -y"
elif command -v dnf >/dev/null; then
    INSTALL="sudo dnf install -y"
else
    echo "⚠️ Gestor de paquetes no soportado. Instala dependencias manualmente."
    INSTALL="true"
fi

# 3. Detectar Entorno
SESSION_TYPE=$(echo "$XDG_SESSION_TYPE" | tr '[:upper:]' '[:lower:]' || echo "x11")
DESKTOP=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]' || echo "unknown")

COMMON_DEPS="ffmpeg jq curl libnotify"

if [ "$SESSION_TYPE" == "wayland" ]; then
    SPECIFIC_DEPS="wf-recorder slurp wl-clipboard"
    if [[ "$DESKTOP" == *"hyprland"* ]]; then FOLDER="Hyprland"
    elif [[ "$DESKTOP" == *"gnome"* ]]; then FOLDER="GNOME"
    elif [[ "$DESKTOP" == *"plasma"* ]]; then FOLDER="PLASMA"
    else FOLDER="Wayland-Universal"; fi
else
    SPECIFIC_DEPS="xrectsel xclip"
    FOLDER="X11"
fi

# 4. Instalación
echo "📦 Instalando dependencias: $COMMON_DEPS $SPECIFIC_DEPS"
$INSTALL $COMMON_DEPS $SPECIFIC_DEPS

if [ -d "./$FOLDER" ]; then
    echo "🚀 Ejecutando instalador específico para $FOLDER..."
    chmod +x "$FOLDER/install.sh"
    # Pasamos el TARGET_SCRIPTS como variable para que todos usen la misma ruta
    export SAVIN_TARGET="$TARGET_SCRIPTS"
    cd "$FOLDER" && ./install.sh
else
    echo "❌ Carpeta $FOLDER no encontrada en el repositorio."
    exit 1
fi

echo "✨ Savin-Recorder instalado con éxito."