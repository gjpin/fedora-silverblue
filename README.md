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


# temp
```
flatpak run org.gnome.Extensions
```