#!/bin/bash

################################################
##### Set variables
################################################

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Gaming (yes / no): " GAMING
export GAMING

################################################
##### General
################################################

# Set hostname
sudo hostnamectl set-hostname --pretty "${NEW_HOSTNAME}"
sudo hostnamectl set-hostname --static "${NEW_HOSTNAME}"

# Create user folders
mkdir -p \
    ${HOME}/.bashrc.d \
    ${HOME}/.local/bin \
    ${HOME}/.local/share/themes \
    ${HOME}/.local/share/applications \
    ${HOME}/.local/share/gnome-shell/extensions \
    ${HOME}/.config/systemd/user \
    ${HOME}/src

# Create WireGuard folder
sudo mkdir -p /etc/wireguard
sudo chmod 700 /etc/wireguard

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
#!/bin/bash

update-all() {
  # Update system
  sudo rpm-ostree upgrade

  # Update Flatpak apps
  flatpak update -y

  # Update Firefox theme
  update-firefox-theme

  # Update GTK theme
  update-gtk-theme

  # Update toolbox packages
  toolbox run sudo dnf upgrade -y --refresh
}
EOF

# Set default firewall zone
sudo firewall-cmd --set-default-zone=block

# Create aliases
tee ${HOME}/.bashrc.d/selinux << EOF
alias sedenials="sudo ausearch -m AVC,USER_AVC -ts recent"
alias selogs="sudo journalctl -t setroubleshoot"
EOF

################################################
##### Toolbox
################################################

# References:
# https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/#toolbox-commands

# Create toolbox
toolbox create -y

# Update toolbox packages
toolbox run sudo dnf upgrade -y --refresh

# Install bind-utils (dig, etc)
toolbox run sudo dnf install -y bind-utils

# Install DNF plugins
toolbox run sudo dnf install -y dnf-plugins-core

# Install go
toolbox run sudo dnf install -y golang

tee ${HOME}/.bashrc.d/golang << 'EOF'
# paths
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Install nodejs
toolbox run sudo dnf install -y nodejs npm

# Install cfssl
toolbox run sudo dnf install -y golang-github-cloudflare-cfssl

# Install make
toolbox run sudo dnf install -y make

# Install butane
toolbox run sudo dnf install -y butane

# Hashicorp tools
toolbox run sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
toolbox run sudo dnf -y install terraform nomad consul vault

################################################
##### Flathub
################################################

# Add Flathub repos
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-modify flathub --enable

sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
sudo flatpak remote-modify flathub-beta --enable

################################################
##### Firefox
################################################

# References:
# https://github.com/pyllyukko/user.js/blob/master/user.js
# https://github.com/rafaelmardojai/firefox-gnome-theme/blob/master/configuration/user.js

# Remove Firefox RPM
sudo rpm-ostree override remove firefox

# Install Firefox from Flathub
flatpak install -y flathub org.mozilla.firefox
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08

# Install Intel VA-API drivers if applicable
if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
fi

# Set Firefox Flatpak as default browser and handler for https(s)
xdg-settings set default-web-browser org.mozilla.firefox.desktop
xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/http
xdg-mime default firefox.desktop x-scheme-handler/https

# Temporarily open Firefox to create profiles
timeout 5 flatpak run org.mozilla.firefox --headless

# Install Firefox Gnome theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo "@import \"firefox-gnome-theme/userChrome.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo "@import \"firefox-gnome-theme/userContent.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF

// Enable customChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Set UI density to normal
user_pref("browser.uidensity", 0);

// Enable SVG context-propertes
user_pref("svg.context-properties.content.enabled", true);

// Add more contrast to the active tab
user_pref("gnomeTheme.activeTabContrast", true);
EOF

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/bin/bash

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

# Enable wayland
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Import Firefox configs
wget https://raw.githubusercontent.com/gjpin/arch-linux/main/extra/firefox.js -O ${FIREFOX_PROFILE_PATH}/user.js

# Install extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

################################################
##### Applications
################################################

# Install common applications
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak install -y flathub org.keepassxc.KeePassXC
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub io.github.celluloid_player.Celluloid
flatpak install -y flathub io.github.seadve.Kooha
flatpak install -y flathub org.gaphor.Gaphor
flatpak install -y flathub com.github.flxzt.rnote
flatpak install -y flathub org.libreoffice.LibreOffice
flatpak install -y flathub rest.insomnia.Insomnia
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub com.usebottles.bottles

# Flatpak overrides
sudo flatpak override --filesystem=xdg-data/applications com.usebottles.bottles

################################################
##### Visual Studio Code
################################################

# References:
# https://github.com/flathub/com.visualstudio.code

# Install VSCode
flatpak install -y flathub com.visualstudio.code

# Add bash alias
tee ${HOME}/.bashrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

# Install extensions
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension HashiCorp.terraform
flatpak run com.visualstudio.code --install-extension HashiCorp.HCL
flatpak run com.visualstudio.code --install-extension redhat.vscode-yaml
flatpak run com.visualstudio.code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
flatpak run com.visualstudio.code --install-extension esbenp.prettier-vscode
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint

# Configure VSCode
mkdir -p ${HOME}/.var/app/com.visualstudio.code/config/Code/User
tee ${HOME}/.var/app/com.visualstudio.code/config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "redhat.telemetry.enabled": false,
    "terraform.telemetry.enabled": false,
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

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark
sudo flatpak override --filesystem=${HOME}/.local/share/themes

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/bin/bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
rm -rf ${HOME}/.local/share/themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz
EOF

chmod +x ${HOME}/.local/bin/update-gtk-theme

# Set adw-gtk3 theme
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'

################################################
##### Unlock LUKS2 with TPM2 token
################################################

# Install tpm2-tools
sudo rpm-ostree install -y tpm2-tools

# Update crypttab
sudo sed -ie '/^luks-/s/$/ tpm2-device=auto/' /etc/crypttab

# Regenerate initramfs
sudo rpm-ostree initramfs --enable --arg=--force-add --arg=tpm2-tss

################################################
##### Syncthing
################################################

# Create syncthing directory
mkdir -p ${HOME}/syncthing

# Create systemd user unit for syncthing container
tee ${HOME}/.config/systemd/user/syncthing.service << EOF
[Unit]
Description=syncthing
After=firewalld.service

[Service]
ExecStartPre=-/usr/bin/podman kill syncthing
ExecStartPre=-/usr/bin/podman rm syncthing
ExecStartPre=/usr/bin/podman pull docker.io/syncthing/syncthing:latest
ExecStart=/usr/bin/podman run -a \
    --name=syncthing \
    --hostname=$(hostnamectl --static) \
    --userns keep-id \
    -p 8384:8384/tcp \
    -p 22000:22000/tcp \
    -p 22000:22000/udp \
    -p 21027:21027/udp \
    -v ${HOME}/syncthing:/var/syncthing:Z \
    docker.io/syncthing/syncthing:latest
ExecStop=/usr/bin/podman stop syncthing
ExecStopPost=/usr/bin/podman rm syncthing
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable systemd user unit
systemctl --user enable syncthing.service

################################################
##### Gnome
################################################

# Configure Gnome
curl https://raw.githubusercontent.com/gjpin/fedora-silverblue/main/gnome.sh -O
chmod +x gnome.sh
./gnome.sh
rm gnome.sh

################################################
##### Gaming
################################################

# Install and configure gaming with Flatpak
if [ ${GAMING} = "yes" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-silverblue/main/setup_gaming.sh -O
    chmod +x setup_gaming.sh
    ./setup_gaming.sh
    rm setup_gaming.sh
fi