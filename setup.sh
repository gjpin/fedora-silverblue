# Set versions
NOMAD_VERSION=1.2.3
CONSUL_VERSION=1.11.1
VAULT_VERSION=1.9.2
TERRAFORM_VERSION=1.1.2
GOLANG_VERSION=1.17.5
INTER_VERSION=3.19

# Add Flathub and Flathub Beta repos
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Remove Firefox RPM
rpm-ostree override remove firefox

# Install Firefox Flatpak
flatpak install -y flathub org.mozilla.firefox
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Open Firefox and then manually close it to create profile folder
echo "Close Firefox window to proceed with setup"
flatpak run org.mozilla.firefox

# Install Firefox theme
git clone https://github.com/vinceliuice/Fluent-gtk-theme.git
cd Fluent-gtk-theme
cp -r src/firefox/chrome/ ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
cp src/firefox/configuration/user.js ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
cd ..
rm -rf Fluent-gtk-theme

# Install Gnome Shell extensions
## https://extensions.gnome.org/extension/19/user-themes/
wget https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v48.shell-extension.zip
gnome-extensions install user-themegnome-shell-extensions.gcampax.github.com.v48.shell-extension.zip
rm user-themegnome-shell-extensions.gcampax.github.com.v48.shell-extension.zip

## https://extensions.gnome.org/extension/3193/blur-my-shell/
wget https://extensions.gnome.org/extension-data/blur-my-shellaunetx.v25.shell-extension.zip
gnome-extensions install blur-my-shellaunetx.v25.shell-extension.zip
rm blur-my-shellaunetx.v25.shell-extension.zip

# Enable Gnome Shell extensions
gsettings set org.gnome.shell disabled-extensions []
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'blur-my-shell@aunetx']"

# Install GTK and icon themes
mkdir -p ${HOME}/.local/share/themes ${HOME}/.local/share/icons

podman run -it --name gnome --volume ${HOME}/.local/share/themes:/gtk-theme:Z \
--volume ${HOME}/.local/share/icons:/icon-theme:Z \
quay.io/fedora/fedora:35 bash -c "dnf install -y sassc git; mkdir -p /gtk-theme; git clone https://github.com/vinceliuice/Fluent-gtk-theme.git; cd Fluent-gtk-theme; ./install.sh -t grey -s standard -i fedora --tweaks noborder solid -d /gtk-theme; mkdir -p /icon-theme; git clone https://github.com/vinceliuice/Fluent-icon-theme.git; cd Fluent-icon-theme; ./install.sh -a -d /icon-theme"

podman rm -f gnome

# Set GTK and icon themes
gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-light'
gsettings set org.gnome.desktop.interface icon-theme 'Fluent-orange'

# Set Gnome Shell theme
dconf write /org/gnome/shell/extensions/user-theme/name "'Fluent-grey'"
dconf write /org/gnome/shell/extensions/blur-my-shell/blur-panel false

# Allow Flatpaks to access GTK themes and icons
sudo flatpak override --filesystem=xdg-data/themes:ro
sudo flatpak override --filesystem=xdg-data/icons:ro

# Install fonts
mkdir -p ${HOME}/.local/share/fonts

## Inter
mkdir inter
cd inter
curl -sSL https://github.com/rsms/inter/releases/download/v${INTER_VERSION}/Inter-${INTER_VERSION}.zip -o inter.zip
unzip inter.zip
cp "Inter Desktop"/*.otf ${HOME}/.local/share/fonts
cd ..
rm -rf inter

## Google Noto Sans Mono
mkdir noto-sans-mono
cd noto-sans-mono
curl -sSL https://fonts.google.com/download?family=Noto%20Sans%20Mono -o noto-sans-mono.zip
unzip noto-sans-mono.zip
cp static/NotoSansMono/*.ttf ${HOME}/.local/share/fonts
cd ..
rm -rf noto-sans-mono

## Google Noto Sans
mkdir noto-sans
cd noto-sans
curl -sSL https://fonts.google.com/download?family=Noto%20Sans -o noto-sans.zip
unzip noto-sans.zip
cp *.ttf ${HOME}/.local/share/fonts
cd ..
rm -rf noto-sans

# Update font cache
fc-cache -v

# Set fonts
gsettings set org.gnome.desktop.interface document-font-name 'Inter 9'
gsettings set org.gnome.desktop.interface font-name 'Inter 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 9'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

# Misc changes
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gtk.Settings.FileChooser sort-directories-first true

## Nautilus
gsettings set org.gnome.nautilus.preferences click-policy 'single'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

## Text editor
dconf write /org/gnome/gedit/preferences/ui/side-panel-visible true
dconf write /org/gnome/gedit/preferences/editor/wrap-mode "'none'"

## Laptop specific
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

## Gnome Terminal padding
tee -a ${HOME}/.config/gtk-3.0/gtk.css << EOF
VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 5px 5px 5px 5px;
    -VteTerminal-inner-border: 5px 5px 5px 5px;
}
EOF

# Shortcuts
## Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab '<Primary><Shift>w'

## Window management
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

## Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

## Screenshots
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Super><Shift>s']"

# Install Flatpak applications
flatpak install -y flathub org.gnome.Extensions
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak install -y flathub com.visualstudio.code
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.gimp.GIMP
flatpak install -y flathub org.blender.Blender
flatpak install -y flathub org.chromium.Chromium
flatpak install -y flathub org.keepassxc.KeePassXC
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub-beta com.google.Chrome
flatpak install -y flathub com.usebottles.bottles
# flatpak install -y flathub com.valvesoftware.Steam
# sudo flatpak override --filesystem=/media/${USER}/data/games/steam com.valvesoftware.Steam
# flatpak install flathub-beta net.lutris.Lutris//beta
# flatpak install -y flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default
# sudo flatpak override --filesystem=/media/${USER}/data/games/lutris net.lutris.Lutris

# Force GTK theme for some apps
# sudo flatpak override --env=GTK_THEME=Fluent-grey-dark com.visualstudio.code
# sudo flatpak override --env=GTK_THEME=Fluent-grey-dark com.spotify.Client
# sudo flatpak override --env=GTK_THEME=Fluent-grey-dark org.gimp.GIMP
# sudo flatpak override --env=GTK_THEME=Fluent-grey-dark org.blender.Blender

# Chrome - Enable GPU acceleration
mkdir -p ~/.var/app/com.google.Chrome/config
tee -a ~/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Chromium - Enable GPU acceleration
mkdir -p ~/.var/app/org.chromium.Chromium/config
tee -a ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Create custom toolbox
podman build toolbox/ -t ${USER}/fedora-toolbox:latest
toolbox create -c fedora-toolbox-35 -i ${USER}/fedora-toolbox

# Start SSHD on login
mkdir -p ${HOME}/.ssh
chmod 700 ${HOME}/.ssh/
tee -a ${HOME}/.ssh/config << EOF
Host toolbox
	HostName localhost
	Port 2222
	StrictHostKeyChecking no
	UserKnownHostsFile=/dev/null
EOF
chmod 600 ${HOME}/.ssh/config

# Create systemd user units folder
mkdir -p ${HOME}/.config/systemd/user

# Start sshd on login
tee -a ${HOME}/.config/systemd/user/toolbox_sshd.service << EOF
[Unit]
Description=Launch sshd in Fedora Toolbox

[Service]
Type=longrun
ExecPre=/usr/bin/podman start fedora-toolbox-35
ExecStart=/usr/bin/toolbox run sudo /usr/sbin/sshd -D

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now toolbox_sshd

# Start syncthing on login
tee -a ${HOME}/.config/systemd/user/toolbox_syncthing.service << EOF
[Unit]
Description=Launch syncthing in Fedora Toolbox

[Service]
Type=longrun
ExecPre=/usr/bin/podman start fedora-toolbox-35
ExecStart=/usr/bin/toolbox run /usr/bin/syncthing

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now toolbox_syncthing

# Create bashrc.d configs folder
mkdir -p ${HOME}/.bashrc.d/

# Add aliases
tee -a ~/.bashrc.d/aliases << EOF
alias code="flatpak run com.visualstudio.code"
alias te="toolbox enter"
alias dark="gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-dark' && dconf write /org/gnome/shell/extensions/user-theme/name \"'Fluent-grey-dark'\""
alias light="gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-light' && dconf write /org/gnome/shell/extensions/user-theme/name \"'Fluent-grey'\""
EOF

# Create local bin folder
mkdir -p ${HOME}/.local/bin

# Install applications
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip
unzip nomad.zip
mv nomad ${HOME}/.local/bin/nomad
rm nomad.zip

curl -sSL https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip
unzip consul.zip
mv consul ${HOME}/.local/bin/consul
rm consul.zip

curl -sSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip
unzip vault.zip
mv vault ${HOME}/.local/bin/vault
rm vault.zip

curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
unzip terraform.zip
mv terraform ${HOME}/.local/bin/terraform
rm terraform.zip

# Install hey
wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
mv hey_linux_amd64 ${HOME}/.local/bin/hey
chmod +x ${HOME}/.local/bin/hey

# Install Golang
touch ${HOME}/.bashrc.d/exports
wget https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
rm -rf ${HOME}/.local/go
tar -C ${HOME}/.local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz
grep -qxF 'export PATH=$PATH:${HOME}/.local/go/bin' ${HOME}/.bashrc.d/exports || echo 'export PATH=$PATH:${HOME}/.local/go/bin' >> ${HOME}/.bashrc.d/exports
rm go${GOLANG_VERSION}.linux-amd64.tar.gz
