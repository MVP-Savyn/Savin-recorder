#!/bin/bash
set -euo pipefail

# 1. Rutas y Carpetas
TARGET="$HOME/.config/savin-recorder/scripts"
mkdir -p "$TARGET"
mkdir -p "$(xdg-user-dir VIDEOS)/GIFS"
mkdir -p "$(xdg-user-dir VIDEOS)/MP4"

# 2. Instalar Scripts
cp -f start.sh gif.sh mp4.sh "$TARGET/"
chmod +x "$TARGET"/*.sh
echo "✅ Scripts copiados a $TARGET"

# 3. Función para crear atajos en GNOME (gsettings)
create_gnome_shortcut() {
    local name=$1
    local command=$2
    local binding=$3
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$name/"

    # Añadir la ruta a la lista de atajos personalizados
    current_list=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if [[ "$current_list" == "@as []" ]]; then
        new_list="['$path']"
    elif [[ "$current_list" != *"$path"* ]]; then
        new_list="${current_list%]*}, '$path']"
    else
        new_list="$current_list"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:$path name "$name"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:$path command "$command"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:$path binding "$binding"
}

# 4. INYECTAR ATAJOS
echo "⌨️ Configurando atajos de teclado en GNOME..."

# Limpiar posibles restos anteriores (opcional pero recomendado)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "@as []"

# Inyectar estos comandos en la función create_gnome_shortcut del install.sh
create_gnome_shortcut "savin-start" "$TARGET/start.sh" "<Super><Shift>r"
create_gnome_shortcut "savin-gif"   "$TARGET/gif.sh"   "ISO_Level3_Shift+g"
create_gnome_shortcut "savin-mp4"   "$TARGET/mp4.sh"   "ISO_Level3_Shift+h"

# AQUÍ USAMOS XDG-OPEN:
create_gnome_shortcut "savin-open-gif" "xdg-open $(xdg-user-dir VIDEOS)/SavinRecorder/GIFS" "<Shift>ISO_Level3_Shift+g"
create_gnome_shortcut "savin-open-mp4" "xdg-open $(xdg-user-dir VIDEOS)/SavinRecorder/MP4" "<Shift>ISO_Level3_Shift+h"
echo "✅ Atajos inyectados correctamente."
echo "ℹ️ Nota: En GNOME, AltGr se identifica como ISO_Level3_Shift."