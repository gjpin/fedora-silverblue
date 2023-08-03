#!/bin/bash

################################################
##### Common
################################################

# References:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git

# Install Mesa git
flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git//22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git//22.08

# Install ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//22.08

# Configure MangoHud
mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf

tee ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf << EOF
control=mangohud
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

################################################
##### Steam
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope

# Make Steam use mesa-git
sudo flatpak override --env=FLATPAK_GL_DRIVERS=mesa-git com.valvesoftware.Steam

# Allow Steam to access external directory
sudo flatpak override --filesystem=/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -O
sudo mv 60-steam-input.rules /etc/udev/rules.d/60-steam-input.rules
sudo udevadm control --reload
sudo udevadm trigger
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Make Heroic use mesa-git
sudo flatpak override --env=FLATPAK_GL_DRIVERS=mesa-git com.heroicgameslauncher.hgl

# Allow Heroic to access external directory
sudo flatpak override --filesystem=/data/games/heroic com.heroicgameslauncher.hgl