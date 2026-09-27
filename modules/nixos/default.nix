{
  imports = [
    ./host-options.nix # typed schema for hosts/<name>/variables.nix
    ./secrets.nix # agenix secrets (opt-in per file)

    # === HARDWARE ===
    ./hardware/boot.nix
    ./hardware/firmware.nix
    ./hardware/bluetooth.nix

    # === CORE ===
    ./core/networking.nix
    ./core/virtualization.nix # docker + libvirt

    # === DESKTOP ===
    ./desktop/hyprland.nix
    ./desktop/graphics.nix
    ./desktop/audio.nix
    ./desktop/display.nix
    ./desktop/fonts.nix

    # === SERVICES ===
    ./services/security.nix # polkit, keyring PAM, sshd, local CA
    ./services/resolved.nix
    ./services/gaming.nix
    ./services/git.nix
    ./services/multimedia.nix
    ./services/tailscale.nix
    ./services/cloudflared.nix
    ./services/obs-studio.nix
    ./services/smb.nix
    # ./services/warp.nix

    # === FEATURES ===
    ./features/cli.nix
    ./features/locale.nix
    ./features/nix-ld.nix
  ];
}
