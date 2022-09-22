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

# Filesystem
# https://docs.fedoraproject.org/en-US/fedora-coreos/storage/#_mounted_filesystems
```
Immutable /, read only /usr

As OSTree is used to manage all files belonging to the operating system, the / and /usr mountpoints are not writable. Any changes to the operating system should be applied via rpm-ostree.

Similarly, the /boot mountpoint is not writable, and the EFI System Partition is not mounted by default. These filesystems are managed by rpm-ostree and bootupd, and must not be directly modified by an administrator.

Adding top level directories (i.e. /foo) is currently unsupported and disallowed by the immutable attribute.

The real / (as in the root of the filesystem in the root partition) is mounted readonly in /sysroot and must not be accessed or modified directly.
Configuration in /etc and state in /var

The only supported writable locations are /etc and /var. /etc should contain only configuration files and is not expected to store data. All data must be kept under /var and will not be touched by system upgrades. Traditional places that might hold state (e.g. /home, or /srv) are symlinks to directories in /var (e.g. /var/home or /var/srv).
```


# temp
```
flatpak run org.gnome.Extensions
```