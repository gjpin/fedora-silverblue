#!/usr/bin/env bash

################################################
##### General
################################################

# Create user folders
mkdir -p \
    ${HOME}/.bashrc.d \
    ${HOME}/.local/bin \
    ${HOME}/.themes \
    ${HOME}/.local/share/gnome-shell/extensions \
    ${HOME}/src

# Add bash aliases
tee ${HOME}/.bashrc.d/aliases << EOF
alias code="flatpak run com.visualstudio.code"
alias te="toolbox enter"
EOF

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
update-all() {
  # Update system
  sudo rpm-ostree upgrade -y

  # Update Flatpak apps
  flatpak update -y

  # Update Firefox theme
  update-firefox-theme

  # Update GTK theme
  update-gtk-theme

  # Update tailscale
  update-tailscale
}
EOF

# Set default firewall zone
sudo firewall-cmd --set-default-zone=block

################################################
##### Flathub
################################################

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable
sudo flatpak update --appstream

################################################
##### Firefox
################################################

# Remove Firefox RPM
sudo rpm-ostree override remove firefox

# Install Firefox from Flathub
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/21.08

# Set Firefox Flatpak as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

# Install Firefox Gnome theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme
cd firefox-gnome-theme
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
cd .. && rm -rf firefox-gnome-theme/

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/env bash

git clone https://github.com/rafaelmardojai/firefox-gnome-theme
cd firefox-gnome-theme
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
cd .. && rm -rf firefox-gnome-theme/
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

# Install Intel VA-API drivers if applicable
if cat /proc/cpuinfo | grep vendor | grep "GenuineIntel" > /dev/null; then
  sudo flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/21.08
fi

################################################
##### Applications
################################################

sudo flatpak install -y flathub org.gnome.World.Secrets
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub net.cozic.joplin_desktop
sudo flatpak install -y flathub rest.insomnia.Insomnia
sudo flatpak install -y flathub org.gimp.GIMP
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak install -y flathub org.gnome.Extensions
sudo flatpak install -y flathub com.usebottles.bottles && \
    sudo flatpak override com.usebottles.bottles --filesystem=xdg-data/applications
sudo flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform
sudo flatpak install -y flathub org.kde.PlatformTheme.QtSNI
sudo flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration

################################################
##### Visual Studio Code
################################################

# Install VSCode
sudo flatpak install -y flathub com.visualstudio.code

# Configure VSCode
mkdir -p ${HOME}/.var/app/com.visualstudio.code/config/Code/User
tee ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "workbench.preferredDarkColorTheme": "Adwaita Dark",
    "workbench.preferredLightColorTheme": "Adwaita Light",
    "editor.fontWeight": "500",
    "redhat.telemetry.enabled": false,
    "files.associations": {
      "*.j2": "terraform",
      "*.hcl": "terraform",
      "*.bu": "yaml",
      "*.ign": "json",
      "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true,
    "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",
    "editor.formatOnSave": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "terminal.integrated.defaultProfile.linux": "toolbox",
    "terminal.integrated.profiles.linux": {
      "toolbox": {
        "path": "/usr/bin/flatpak-spawn",
        "args": ["--host", "--env=TERM=xterm-256color", "toolbox", "enter"]
      },
      "bash": {
        "path": "/usr/bin/flatpak-spawn",
        "args": ["--host", "--env=TERM=xterm-256color", "bash"]
      }
    }
}
EOF

# Install extensions
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension HashiCorp.terraform
flatpak run com.visualstudio.code --install-extension redhat.ansible
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/env bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
rm -rf ${HOME}/.themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.themes/
rm -f adw-*.tar.xz
EOF

chmod +x ${HOME}/.local/bin/update-gtk-theme

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'

################################################
##### Shortcuts
################################################

# Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab '<Primary><Shift>w'

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
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

# Laptop specific
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

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
gnome-extensions enable ${EXTENSION_UUID}
rm -f *shell-extension.zip

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v42.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
gnome-extensions enable ${EXTENSION_UUID}
rm -f *shell-extension.zip

################################################
##### Tailscale
################################################

# References:
# https://tailscale.com/blog/steam-deck/

# Install Tailscale
LATEST_TAILSCALE_VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | awk -F\" '/"name"/{print $(NF-1)}')
curl -sSL https://pkgs.tailscale.com/stable/tailscale_${LATEST_TAILSCALE_VERSION}_amd64.tgz -O
tar -xf tailscale_*.tgz --strip-components 1 -C ${HOME}/.local/bin/ --wildcards tailscale_*/tailscale
tar -xf tailscale_*.tgz --strip-components 1 -C ${HOME}/.local/bin/ --wildcards tailscale_*/tailscaled
rm -f tailscale_*.tgz

# Create tailscaled aliases
tee ${HOME}/.bashrc.d/tailscale << 'EOF'
alias start-tailscaled='(sudo systemd-run \
    --service-type=notify \
    --description="Tailscale node agent" \
    -u tailscaled.service \
    -p ExecStartPre="${HOME}/.local/bin/tailscaled --cleanup" \
    -p ExecStopPost="${HOME}/.local/bin/tailscaled --cleanup" \
    -p Restart=on-failure \
    -p RuntimeDirectory=tailscale \
    -p RuntimeDirectoryMode=0755 \
    -p StateDirectory=tailscale \
    -p StateDirectoryMode=0700 \
    -p CacheDirectory=tailscale \
    -p CacheDirectoryMode=0750 \
    "${HOME}/.local/bin/tailscaled" \
    "--state=/var/lib/tailscale/tailscaled.state" \
    "--socket=/run/tailscale/tailscaled.sock")'

alias stop-tailscaled="sudo systemctl stop tailscaled.service"
EOF

# Tailscale updater
tee ${HOME}/.local/bin/update-tailscale << 'EOF'
#!/usr/bin/env bash

LATEST_TAILSCALE_VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | awk -F\" '/"name"/{print $(NF-1)}')
INSTALLED_TAILSCALE_VERSION=$(tailscale --version | head -n 1)

if [ "$LATEST_TAILSCALE_VERSION" != "$INSTALLED_TAILSCALE_VERSION" ]; then
    rm -f ${HOME}/.local/bin/{tailscale,tailscaled}
    curl -sSL https://pkgs.tailscale.com/stable/tailscale_${LATEST_TAILSCALE_VERSION}_amd64.tgz -O
    tar -xf tailscale_*.tgz --strip-components 1 -C ${HOME}/.local/bin/ --wildcards tailscale_*/tailscale
    tar -xf tailscale_*.tgz --strip-components 1 -C ${HOME}/.local/bin/ --wildcards tailscale_*/tailscaled
    rm -f tailscale_*.tgz
fi
EOF

chmod +x ${HOME}/.local/bin/update-tailscale