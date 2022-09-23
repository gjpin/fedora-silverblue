# Login to tailscale
```
sudo tailscale up --operator=${USER}
```

# Flatpak - Revert to commit
```
# Install app
sudo flatpak install -y flathub org.godotengine.Godot

# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=HASH org.godotengine.Godot

# Prevent app from being updated
flatpak mask org.godotengine.Godot
```

## Gaming
```
###### STEAM
mkdir -p /mnt/data/games/steam
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
sudo flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Steam controllers udev rules
sudo curl -sSL https://raw.githubusercontent.com/gjpin/fedora-silverblue/main/configs/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules

# Reload udev rules
sudo udevadm control --reload && sudo udevadm trigger

# Enable uinput module
sudo tee /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

###### MangoHud
sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud

###### Heroic Games Launcher
mkdir -p /mnt/data/games/heroic
sudo flatpak install -y com.heroicgameslauncher.hgl
sudo flatpak override --filesystem=/mnt/data/games/heroic com.heroicgameslauncher.hgl
```

## Gamescope + MangoHud + Steam
```
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -e -- %command%

# gamescope native resolution + MangoHud
gamescope -f -e -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -e -- mangohud %command%
```

# References
- [How to debug issues with volumes mounted on rootless containers](https://www.redhat.com/sysadmin/debug-rootless-podman-mounted-volumes)
- [Fedora OSTree filesystem](https://docs.fedoraproject.org/en-US/fedora-coreos/storage/#_mounted_filesystems)