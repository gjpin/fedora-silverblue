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
sudo mkdir -p /etc/wireguard/
sudo chmod 700 /etc/wireguard/

# Updater bash function
tee ${HOME}/.bashrc.d/update-all << EOF
update-all() {
  # Update system
  sudo rpm-ostree upgrade

  # Update Flatpak apps
  flatpak update -y

  # Update Firefox theme
  update-firefox-theme

  # Update GTK theme
  update-gtk-theme

  # Update toolbox pckages
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

# Install wireguard-tools
toolbox run sudo dnf install -y wireguard-tools

# Install go
toolbox run sudo dnf install -y golang

tee ${HOME}/.bashrc.d/golang << 'EOF'
# paths
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Install nodejs
toolbox run sudo dnf install -y nodejs npm

# Install language servers
toolbox run sudo dnf install -y \
  python-lsp-server \
  typescript \
  nodejs-bash-language-server \
  golang-x-tools-gopls \
  clang-tools-extra

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
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08

# Install Intel VA-API drivers if applicable
if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
fi

# Set Firefox Flatpak as default browser
xdg-settings set default-web-browser org.mozilla.firefox.desktop

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
EOF

# Firefox theme updater
tee ${HOME}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/env bash

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
EOF

chmod +x ${HOME}/.local/bin/update-firefox-theme

# Enable wayland
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Import Firefox configs
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF

// Enable FFMPEG VA-API
user_pref("media.ffmpeg.vaapi.enabled", true);

// Disable title bar
user_pref("browser.tabs.inTitlebar", 1);

// Disable View feature
user_pref("browser.tabs.firefox-view", false);

// Disable List All Tabs button
user_pref("browser.tabs.tabmanager.enabled", false);

// Disable password manager
user_pref("signon.rememberSignons", false);

// Disable default browser check
user_pref("browser.shell.checkDefaultBrowser", false);

// Enable scrolling with middle mouse button
user_pref("general.autoScroll", true);

// Enable Firefox Tracking Protection
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("network.cookie.cookieBehavior", 5);

// Disable Mozilla telemetry/experiments
user_pref("toolkit.telemetry.enabled",				false);
user_pref("toolkit.telemetry.unified",				false);
user_pref("toolkit.telemetry.archive.enabled",			false);
user_pref("experiments.supported",				false);
user_pref("experiments.enabled",				false);
user_pref("experiments.manifest.uri",				"");

// Disallow Necko to do A/B testing
user_pref("network.allow-experiments",				false);

// Disable collection/sending of the health report
user_pref("datareporting.healthreport.uploadEnabled",		false);
user_pref("datareporting.healthreport.service.enabled",		false);
user_pref("datareporting.policy.dataSubmissionEnabled",		false);
user_pref("browser.discovery.enabled",				false);

// Disable Pocket
user_pref("browser.pocket.enabled",				false);
user_pref("extensions.pocket.enabled",				false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories",	false);

// Disable Location-Aware Browsing (geolocation)
user_pref("geo.enabled",					false);

// Disable "beacon" asynchronous HTTP transfers (used for analytics)
user_pref("beacon.enabled",					false);

// Disable speech recognition
user_pref("media.webspeech.recognition.enable",			false);

// Disable speech synthesis
user_pref("media.webspeech.synth.enabled",			false);

// Disable pinging URIs specified in HTML <a> ping= attributes
user_pref("browser.send_pings",					false);

// Don't try to guess domain names when entering an invalid domain name in URL bar
user_pref("browser.fixup.alternate.enabled",			false);

// Opt-out of add-on metadata updates
user_pref("extensions.getAddons.cache.enabled",			false);

// Opt-out of themes (Persona) updates
user_pref("lightweightThemes.update.enabled",			false);

// Disable Flash Player NPAPI plugin
user_pref("plugin.state.flash",					0);

// Disable Java NPAPI plugin
user_pref("plugin.state.java",					0);

// Disable Gnome Shell Integration NPAPI plugin
user_pref("plugin.state.libgnome-shell-browser-plugin",		0);

// Updates addons automatically
user_pref("extensions.update.enabled",				true);

// Enable add-on and certificate blocklists (OneCRL) from Mozilla
user_pref("extensions.blocklist.enabled",			true);
user_pref("services.blocklist.update_enabled",			true);

// Disable Extension recommendations
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr",	false);

// Disable sending Firefox crash reports to Mozilla servers
user_pref("breakpad.reportURL",					"");

// Disable sending reports of tab crashes to Mozilla
user_pref("browser.tabs.crashReporting.sendReport",		false);
user_pref("browser.crashReports.unsubmittedCheck.enabled",	false);

// Enable Firefox's anti-fingerprinting mode
user_pref("privacy.resistFingerprinting",			true);

// Disable Shield/Heartbeat/Normandy
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("extensions.shield-recipe-client.enabled",		false);
user_pref("app.shield.optoutstudies.enabled",			false);

// Disable Firefox Hello metrics collection
user_pref("loop.logDomains",					false);

// Enable blocking reported web forgeries
user_pref("browser.safebrowsing.phishing.enabled",		true);

// Enable blocking reported attack sites
user_pref("browser.safebrowsing.malware.enabled",		true);

// Disable downloading homepage snippets/messages from Mozilla
user_pref("browser.aboutHomeSnippets.updateUrl",		"");

// Enable Content Security Policy (CSP)
user_pref("security.csp.experimentalEnabled",			true);

// Enable Subresource Integrity
user_pref("security.sri.enable",				true);

// Don't send referer headers when following links across different domains
user_pref("network.http.referer.XOriginPolicy",		2);

// Disable new tab tile ads & preload
user_pref("browser.newtabpage.enhanced",			false);
user_pref("browser.newtab.preload",				false);
user_pref("browser.newtabpage.directory.ping",			"");
user_pref("browser.newtabpage.directory.source",		"data:text/plain,{}");

// Enable HTTPS-Only Mode
user_pref("dom.security.https_only_mode",			true);

// Enable HSTS preload list
user_pref("network.stricttransportsecurity.preloadlist",	true);
EOF

################################################
##### Applications
################################################

# Install common applications
sudo flatpak install -y flathub com.bitwarden.desktop
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak install -y flathub com.github.tchx84.Flatseal

sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub io.github.celluloid_player.Celluloid
sudo flatpak install -y flathub io.github.seadve.Kooha

sudo flatpak install -y flathub org.gaphor.Gaphor
sudo flatpak install -y flathub com.github.flxzt.rnote

sudo flatpak install -y flathub org.godotengine.Godot

# Insomnia
sudo flatpak install -y flathub rest.insomnia.Insomnia
sudo flatpak override --env=GTK_THEME=adw-gtk3-dark rest.insomnia.Insomnia
sudo flatpak override --socket=wayland rest.insomnia.Insomnia

cp /var/lib/flatpak/app/rest.insomnia.Insomnia/current/active/files/share/applications/rest.insomnia.Insomnia.desktop ${HOME}/.local/share/applications
sed -i "s|Exec=/app/bin/insomnia|Exec=flatpak run rest.insomnia.Insomnia --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland|g" ${HOME}/.local/share/applications/rest.insomnia.Insomnia.desktop

# GIMP beta (has native wayland support)
sudo flatpak install -y flathub-beta org.gimp.GIMP

# Blender
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak override --socket=wayland org.blender.Blender

# Bottles
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak override --filesystem=xdg-data/applications com.usebottles.bottles

# Obsidian
sudo flatpak install -y flathub md.obsidian.Obsidian
sudo flatpak override --env=OBSIDIAN_USE_WAYLAND=1 md.obsidian.Obsidian
sudo flatpak override --env=GTK_THEME=adw-gtk3-dark md.obsidian.Obsidian

# Improve QT applications theming in GTK
sudo flatpak install -y flathub org.kde.KStyle.Adwaita/x86_64/5.15-22.08
sudo flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-22.08
sudo flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15-22.08

################################################
##### Visual Studio Code
################################################

# Install VSCode
sudo flatpak install -y flathub com.visualstudio.code

# Add bash alias
tee ${HOME}/.bashrc.d/vscode << EOF
alias code="flatpak run com.visualstudio.code"
EOF

# Install extensions
flatpak run com.visualstudio.code --install-extension piousdeer.adwaita-theme
flatpak run com.visualstudio.code --install-extension golang.Go
flatpak run com.visualstudio.code --install-extension dbaeumer.vscode-eslint
flatpak run com.visualstudio.code --install-extension vue.volar
flatpak run com.visualstudio.code --install-extension llvm-vs-code-extensions.vscode-clangd
flatpak run com.visualstudio.code --install-extension geequlim.godot-tools

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

# Run VSCode under Wayland
sudo flatpak override --socket=wayland com.visualstudio.code
cp /var/lib/flatpak/app/com.visualstudio.code/current/active/files/share/applications/com.visualstudio.{code,code-url-handler}.desktop ${HOME}/.local/share/applications
sed -i "s|Exec=code|Exec=flatpak run com.visualstudio.code --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto|g" ${HOME}/.local/share/applications/com.visualstudio.{code,code-url-handler}.desktop

################################################
##### GTK theme
################################################

# Install adw-gtk3 flatpak
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz

# GTK theme updater
tee ${HOME}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/env bash

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
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v46.shell-extension.zip -O
EXTENSION_UUID=$(unzip -c *shell-extension.zip metadata.json | grep uuid | cut -d \" -f4)
mkdir -p ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
unzip -q *shell-extension.zip -d ${HOME}/.local/share/gnome-shell/extensions/${EXTENSION_UUID}
rm -f *shell-extension.zip

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu']"

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
##### Gaming
################################################

# Install and configure gaming with Flatpak
if [ ${GAMING} = "yes" ]; then
    curl https://raw.githubusercontent.com/gjpin/fedora-silverblue/main/setup_gaming.sh -O
    chmod +x setup_gaming.sh
    ./setup_gaming.sh
    rm setup_gaming.sh
fi