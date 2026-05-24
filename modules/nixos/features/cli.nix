{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Nix-specific
    nix-output-monitor
    nh
    nixfmt
    nixfmt-tree
    nix-index

    # System Monitoring & Info
    htop
    btop
    neofetch
    lshw
    pciutils
    usbutils
    acpi
    lm_sensors

    # Modern CLI Replaces
    eza
    bat
    fd
    zoxide
    delta
    starship

    # System Utilities
    fzf
    wl-clipboard
    tree
    file
    which
    glow
    openssl

    # Network & Transfer
    curl
    wget
    axel
    rsync
    openssh
    speedtest-cli

    # Archive Tools
    zip
    unzip
    p7zip
    gzip
    unrar

    # Terminal
    bash-completion
    coreutils
    woeusb-ng

    # Security
    age
    ssh-to-age
    sops
  ];
}
