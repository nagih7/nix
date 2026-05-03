# QuickShell Configuration Module

QuickShell (illogical-impulse) configuration for NixOS with home-manager.

## Structure

```
quickshell/
├── default.nix              # Main entry point
├── modules/
│   ├── config-builder.nix   # Builds customized config with qmldir patches
│   ├── environment.nix      # Qt6, Python, QML paths
│   ├── activation.nix       # Setup scripts
│   ├── dependencies.nix     # KDE, Qt6 packages
│   └── services.nix         # SystemD services
```

## Troubleshooting

### Adding New QML Services

When upstream adds new services to `services/` directory:

0. **View Quickshell logs**

    ```bash
    pkill quickshell; sleep 1; quickshell --config ii 2>&1
    ```

1. **Check if it's a singleton**:

    ```bash
    grep "pragma Singleton" ~/.config/quickshell/ii/services/NewService.qml
    ```

2. **Edit `modules/config-builder.nix`**:
    - If has `pragma Singleton`: Add to singleton section
    - If not: Add to non-singleton section

    ```nix
    # In the services qmldir section:
    singleton NewService 1.0 NewService.qml  # if singleton
    NewService 1.0 NewService.qml            # if not singleton
    ```

3. **Rebuild**:
    ```bash
    sudo nixos-rebuild switch --flake '.#device.example'
    ```

### Common Issues

**QML module not found**: Check qmldir exists and contains your service

```bash
cat ~/.config/quickshell/ii/services/qmldir | grep YourService
```

**Settings won't open**: SettingsLauncher service handles QS_CONFIG_NAME conflicts automatically

**Python errors**: Virtual env should auto-create at `~/.local/state/quickshell/.venv`

### Updating upstream config

The config is pulled from `end-4-dots` flake input. Update flake.lock to get latest changes.

## References

- [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)
- [QuickShell](https://git.outfoxxed.me/outfoxxed/quickshell)
