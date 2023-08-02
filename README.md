# Installation guide
1. Download setup script: `curl https://raw.githubusercontent.com/gjpin/fedora-silverblue/main/setup.sh -O`
2. Make setup script executable: `chmod +x setup.sh`
3. Run setup.sh: `./setup.sh`
4. Reboot
5. Enroll TPM2 token into LUKS2: `sudo systemd-cryptenroll --tpm2-device=auto --wipe-slot=tpm2 /dev/nvme0n1p3`
6. Import WireGuard config to /etc/wireguard
7. Enable WireGuard connection: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
8. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-interface=wg0`

# Guides
## How to revert to a previous Flatpak commit
```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```

## How to use Gamescope + MangoHud in Steam
```bash
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -- %command%

# gamescope native resolution + MangoHud
gamescope -f -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -- mangohud %command%
```

## How to install .deb package (eg. Aseprite)
```bash
mkdir -p ${HOME}/aseprite
mv ${HOME}/Downloads/Aseprite*.deb ${HOME}/aseprite
ar -x ${HOME}/aseprite/Aseprite*.deb --output ${HOME}/aseprite
tar -xf ${HOME}/aseprite/data.tar.xz -C ${HOME}/aseprite
cp -r ${HOME}/aseprite/usr/bin/aseprite ${HOME}/.local/bin/
cp -r ${HOME}/aseprite/usr/share/* ${HOME}/.local/share/
rm -rf ${HOME}/aseprite
```

## How to automatically disable turbo boost if on battery
```bash
# References:
# https://chrisdown.name/2017/10/29/adding-power-related-targets-to-systemd.html

# Confirm udev events:
# udevadm monitor --environment
# udevadm info -a -p /sys/class/power_supply/AC

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

## How to enable amd-pstate CPU Performance Scaling Driver
```bash
# Check if CPU is AMD and current scaling driver is not amd-pstate
if cat /proc/cpuinfo | grep "AuthenticAMD" > /dev/null && cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver | grep -v "amd-pstate" > /dev/null; then
  sudo rpm-ostree kargs --append=amd_pstate.shared_mem=1
  echo amd_pstate | sudo tee /etc/modules-load.d/amd-pstate.conf
fi
```

# References
- [How to debug issues with volumes mounted on rootless containers](https://www.redhat.com/sysadmin/debug-rootless-podman-mounted-volumes)
- [Fedora OSTree filesystem](https://docs.fedoraproject.org/en-US/fedora-coreos/storage/#_mounted_filesystems)