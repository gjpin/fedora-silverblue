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

## Override systemd configurations
```
sudo mkdir -p /etc/systemd/system.conf.d/

sudo tee /etc/systemd/system.conf.d/99-default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF
```

## Disable turbo boost if on battery (laptops only)
```
# References:
# https://chrisdown.name/2017/10/29/adding-power-related-targets-to-systemd.html

# If device is a laptop
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then

# Create systemd AC / battery targets
sudo tee /etc/systemd/system/ac.target << EOF
[Unit]
Description=On AC power
DefaultDependencies=no
StopWhenUnneeded=yes
EOF

sudo tee /etc/systemd/system/battery.target << EOF
[Unit]
Description=On battery power
DefaultDependencies=no
StopWhenUnneeded=yes
EOF

# Tell udev to start AC / battery targets when relevant
sudo tee /etc/udev/rules.d/99-powertargets.rules << 'EOF'
SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="0", RUN+="/usr/bin/systemctl start battery.target"
SUBSYSTEM=="power_supply", KERNEL=="AC", ATTR{online}=="1", RUN+="/usr/bin/systemctl start ac.target"
EOF

# Reload and apply udev's new config
sudo udevadm control --reload-rules

# Disable turbo boost if on battery 
sudo tee /etc/systemd/system/disable-turbo-boost.service << EOF
[Unit]
Description=Disable turbo boost on battery

[Service]
Type=oneshot
ExecStart=-/usr/bin/echo 0 > /sys/devices/system/cpu/cpufreq/boost
ExecStart=-/usr/bin/echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo

[Install]
WantedBy=battery.target
EOF

# Enable turbo boost if on AC 
sudo tee /etc/systemd/system/enable-turbo-boost.service << EOF
[Unit]
Description=Enable turbo boost on AC

[Service]
Type=oneshot
ExecStart=-/usr/bin/echo 1 > /sys/devices/system/cpu/cpufreq/boost
ExecStart=-/usr/bin/echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo

[Install]
WantedBy=ac.target
EOF

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable disable-turbo-boost.service
sudo systemctl enable enable-turbo-boost.service

fi
```

## Enable amd-pstate CPU Performance Scaling Driver
```
# Check if CPU is AMD and current scaling driver is not amd-pstate
if cat /proc/cpuinfo | grep "AuthenticAMD" > /dev/null && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver | grep -v "amd-pstate" > /dev/null; then
  sudo rpm-ostree kargs --append=amd_pstate.shared_mem=1
  echo amd_pstate | sudo tee /etc/modules-load.d/amd-pstate.conf
fi
```

# References
- [How to debug issues with volumes mounted on rootless containers](https://www.redhat.com/sysadmin/debug-rootless-podman-mounted-volumes)
- [Fedora OSTree filesystem](https://docs.fedoraproject.org/en-US/fedora-coreos/storage/#_mounted_filesystems)