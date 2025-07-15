#!/bin/bash

# Function to display usage help
display_help() {
    echo "Usage: $0 [path_to_wallpaper_1] [path_to_wallpaper_2]"
    echo "If one argument is provided, the same wallpaper is set for both monitors."
    echo "If two arguments are provided, the first is set for monitor 0 and the second for monitor 1."
    exit 1
}

# Check for help arguments or incorrect number of arguments
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-H" || "$1" == "-help" || $# -eq 0 || $# -gt 2 ]]; then
    display_help
fi

# Set the wallpaper paths
if [[ $# -eq 1 ]]; then
    wallpaper1="$1"
    wallpaper2="$1"
elif [[ $# -eq 2 ]]; then
    wallpaper1="$1"
    wallpaper2="$2"
fi

# Ensure both arguments are absolute paths
if [[ ! -f "$wallpaper1" || ! -f "$wallpaper2" ]]; then
    echo "Error: One or both wallpaper files do not exist."
    exit 1
fi

CMD_STRING="
var Desktops = desktops();
d0 = Desktops[0];
d0.wallpaperPlugin = 'org.kde.image';
d0.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
d0.writeConfig('Image', 'file://$wallpaper1');

d1 = Desktops[1];
d1.wallpaperPlugin = 'org.kde.image';
d1.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
d1.writeConfig('Image', 'file://$wallpaper2');
"


# Set wallpapers using dbus-send
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript string:"$CMD_STRING"

echo "Wallpapers set successfully!"
