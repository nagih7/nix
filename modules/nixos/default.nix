{ config, ... }:

{
  imports = [
    # === HARDWARE CONFIGURATION ===
    ./hardware/boot.nix # Bootloader and kernel configuration
    ./hardware/firmware.nix # Firmware configuration
    ./hardware/bluetooth.nix # Bluetooth configuration

    # === SERVICES CONFIGURATION ===
    ./services/security.nix # Security hardening (SSH, sudo, etc.)
    ./services/resolved.nix
    ./services/gaming.nix
    ./services/git.nix
    ./services/multimedia.nix # Multimedia services (audio, video, etc.)
    ./services/warp.nix
    ./services/tailscale.nix # Tailscale configuration for secure VPN access
    ./services/cloudflared.nix # Cloudflared configuration for secure tunneling
    ./services/obs-studio.nix
    ./services/smb.nix

    # === DESKTOP CONFIGURATION ===
    ./desktop/hyprland.nix
    ./desktop/graphics.nix
    ./desktop/audio.nix
    ./desktop/display.nix
    ./desktop/fonts.nix

    # === CORE CONFIGURATION ===
    ./core/networking.nix # Networking configuration
    ./core/virtualization.nix # Visual enhancements (themes, icons, etc.)

    # === FEATURE CONFIGURATION ===
    ./features/cli.nix # CLI tools and utilities
    ./features/locale.nix # Locale and language settings
    ./features/nix-ld.nix # Nix LDA configuration
  ];
}
