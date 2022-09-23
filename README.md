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

# References
- [How to debug issues with volumes mounted on rootless containers](https://www.redhat.com/sysadmin/debug-rootless-podman-mounted-volumes)
- [Fedora OSTree filesystem](https://docs.fedoraproject.org/en-US/fedora-coreos/storage/#_mounted_filesystems)