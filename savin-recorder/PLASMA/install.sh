#!/bin/bash
set -euo pipefail

TARGET="$HOME/.config/savin-recorder/scripts"
mkdir -p "$TARGET"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/GIFS"
mkdir -p "$(xdg-user-dir VIDEOS)/SavinRecorder/MP4"

cp -f start.sh gif.sh mp4.sh "$TARGET/"
chmod +x "$TARGET"/*.sh

echo "⌨️  Configurando atajos para KDE Plasma..."

# Función para inyectar atajos en el sistema de KDE
# Usamos kwriteconfig6 (para Plasma 6) o kwriteconfig5 (para Plasma 5)
KWC=$(command -v kwriteconfig6 || command -v kwriteconfig5)

if [ -z "$KWC" ]; then
    echo "⚠️  No se encontró kwriteconfig. Por favor, asigna los atajos manualmente."
else
    # Registrar el script en el sistema de atajos de KDE
    $KWC --file kglobalshortcutsrc --group "khotkeys" --key "SavinStart" "$TARGET/start.sh,none,SavinStart"
    $KWC --file kglobalshortcutsrc --group "khotkeys" --key "SavinGif" "$TARGET/gif.sh,none,SavinGif"
    
    # Notificar al sistema para que recargue los atajos
    qdbus org.kde.kglobalaccel /kglobalaccel org.kde.kglobalaccel.rebindPasswords > /dev/null 2>&1 || true
    echo "✅ Atajos registrados en KDE."
fi

echo "🚀 Instalación para Plasma completada."