# Savin-recorder

Este es un grabador de pantalla para Linux y windows, está orientado a la "documentación", por lo que es rápido y fácil de usar, y al no estar pensado para gaming utiliza tan sólo la CPU, hacienco que sea compatible con cualquier hardware, pero… eso no es lo interesante, lo interesante es que utiliza (de forma opcional) servicios en la nube a elegir para distintos propósitos; por ejemplo, saltarse la restricción de límite de tamaño en Discord. <br>
Graba la pantalla con la opción de exportar la grabación en formato GIF, o MP4. <br>
El programa está cuidadosamente configurado para obtener la mayor calidad de grabación y ligereza posible.
<br>
(Todavía está en desarrollo)
<br> <br>
La primera versión está terminada, los archivos se pueden descargar e instalar ejecutando el comando ./install.sh
Seguiré trabajando en esta pequeña aplicación y en la explicación de cómo usarlo, por ahora sólo quiero tenerlo guardado.
<br> <br>
# 🎥 Savin-Recorder (Linux Edition)

El grabador de pantalla para diseñado para la rapidez, compatibilidad y facilidad de uso.
Detecta automáticamente tu entorno (GNOME, Plasma, Hyprland o X11) y configura los atajos por ti.

## ✨ Características
- **GIFs Ultra-ligeros**: Algoritmo de paleta de 256 colores optimizada.
- **MP4 Inteligente**: Compresión H.264 automática antes de subir.
- **Auto-Upload**: Sube tus capturas a `tmpfiles.org` y copia el link al portapapeles.
- **Multi-Entorno**: Soporte nativo para Wayland y X11.

## 🚀 Instalación
Solo tienes que ejecutar el instalador raíz. Él se encargará de detectar tu escritorio, instalar las dependencias necesarias (ffmpeg, wf-recorder, etc.) y configurar los atajos.

## 🐧 Linux
LA versión de Linux incluye un instalador inteligente que detecta tu servidor gráfico (**Wayland/X11**) y tu entorno de escritorio (**GNOME, Plasma, Hyprland**) para configurar las dependencias y atajos de teclado automáticamente.
<br> <br>
IMPORTANTE: Por ahora sólo puedo confirmar que funciona en hyprland, estoy trabajando en la compatibilidad con el resto de escritorios.

### Requisitos:
- Gestor de paquetes compatible (`pacman`, `apt`, `dnf`).
- Los scripts se instalan en `~/.config/savin-recorder/`.

### Comando de una línea:
```bash
git clone [https://github.com/MVP-Savyn/savin-recorder.git](https://github.com/MVP-Savyn/savin-recorder.git) && cd savin-recorder && chmod +x linux-install.sh && ./linux-install.sh
