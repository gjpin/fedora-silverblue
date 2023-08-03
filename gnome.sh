#!/bin/bash

################################################
##### Shortcuts
################################################

# Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'

# Windows management
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

# Screenshots
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"

# Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>E'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Shift><Control>Escape'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'gnome-system-monitor'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'gnome-system-monitor'

# Change alt+tab behaviour
gsettings set org.gnome.desktop.wm.keybindings switch-applications "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"

# Switch to workspace
gsettings set org.gnome.shell.keybindings switch-to-application-1 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "@as []"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"

# Move window to workspace
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Super>exclam']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Super>at']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Super>numbersign']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Super>dollar']"

################################################
##### UI / UX changes
################################################

# Volume
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

# Calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small'

# Laptop specific
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

# Configure bash prompt
tee ${HOME}/.bashrc.d/prompt << EOF
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Configure terminal color scheme
dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ default-size-columns 110
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ palette "['rgb(46,52,54)', 'rgb(204,0,0)', 'rgb(34,209,139)', 'rgb(196,160,0)', 'rgb(51,142,250)', 'rgb(117,80,123)', 'rgb(6,152,154)', 'rgb(211,215,207)', 'rgb(85,87,83)', 'rgb(239,41,41)', 'rgb(138,226,52)', 'rgb(252,233,79)', 'rgb(114,159,207)', 'rgb(173,127,168)', 'rgb(52,226,226)', 'rgb(238,238,236)']"

# Set fonts
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Noto Sans Bold 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

################################################
##### Gnome Shell Extensions
################################################

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
sudo rpm-ostree install -y xprop

curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v8.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

gsettings set org.gnome.shell.extensions.dark-variant applications "['com.visualstudio.code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.spotify.Client.desktop', 'md.obsidian.Obsidian.desktop', 'org.gimp.GIMP.desktop', 'org.blender.Blender.desktop', 'org.godotengine.Godot.desktop', 'com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop']"

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v53.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

# Grand Theft Focus
# # https://extensions.gnome.org/extension/5410/grand-theft-focus
curl -sSL https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v3.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'grand-theft-focus@zalckos.github.com']"