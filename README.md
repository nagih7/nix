<div align="center">

[![NixOS](https://img.shields.io/badge/NixOS-26.05-blue.svg?style=flat&logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Bleeding%20Edge-blue.svg?style=flat&logo=wayland&logoColor=white)](https://hyprland.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Stars](https://img.shields.io/github/stars/nagih7/nix?style=flat)](https://github.com/nagih7/nix)

<h2>❄️ Nagih's NixOS Configuration</h2>

_A modern, reproducible NixOS configuration powered by Hyprland & Flakes._

</div>

## Overview

This is a comprehensive NixOS configuration built around the Hyprland Wayland compositor, designed for developers and enthusiasts who prioritize a beautiful, functional, and reproducible desktop environment.

Leveraging the robust foundation of [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) for core Hyprland and Quickshell components, this configuration extends the ecosystem with custom modules, performance optimizations, and a DevOps-centric workflow.

## Installation

### Prerequisites

- **Architecture**: x86_64-linux
- **OS**: NixOS 26.05 (stable channel; selected apps from nixpkgs-unstable)
- **Firmware**: UEFI system
- **Hardware**: At least 8GB RAM recommended, 20GB+ free disk space.

### Setup

1.  **Clone the repository:**

    ```bash
    # SSH (Recommended)
    git clone git@github.com:nagih7/nix.git

    # HTTPS
    git clone https://github.com/nagih7/nix.git
    ```

2.  **Run setup script:**

    ```bash
    cd nix
    chmod +x setup.sh
    ./setup.sh
    ```

    > **Note:** Ensure you have backed up your current configuration before proceeding.

3.  Follow the on-screen instructions to build and switch generations.

## Usage

### Nix Commands

This configuration utilizes [`nh`](https://github.com/viperML/nh) for faster builds and better output formatting. Convenient aliases are pre-configured:

`programs.nh` exports `NH_FLAKE`, so none of these need a path argument. The flake is pure (no `--impure`).

| Alias  | Underlying Command                 | Description                                   |
| :----- | :--------------------------------- | :-------------------------------------------- |
| `nixs` | `nh os switch`                     | Rebuild and switch to the new generation      |
| `nixt` | `nh os test`                       | Build and activate without a boot entry       |
| `nixu` | `nix flake update --flake $NH_FLAKE` | Update flake inputs                         |
| `hms`  | `nh home switch -b bak`            | Rebuild Home Manager configuration only       |
| `nixc` | `nh clean all --keep 3`            | Garbage collect (weekly `nh clean` also runs) |
| `nixf` | `nh search`                        | Search for packages in Nixpkgs                |

Other useful commands:

```bash
nix flake check   # evaluates + builds every host and home configuration
nix fmt           # nixfmt (tree-wide)
nix develop       # nixfmt-tree, nixd, nh, agenix, home-manager
```

### Layout

```
flake.nix                 hosts are discovered from hosts/*; one pkgs for NixOS + HM
variables.nix             system-wide constants (state version, arch, active desktop shell)
hosts/<name>/variables.nix host data — validated by modules/nixos/host-options.nix
hosts/<name>/             default.nix + hardware-configuration.nix
modules/nixos/            system modules (drivers, daemons, session, secrets)
modules/home-manager/     user modules (apps, dotfiles, desktop shell providers)
home/<user>/              per-user packages/aliases/ssh/syncthing
secrets/                  agenix-encrypted files + recipient list (secrets.nix)
overlays/                 pkgs.unstable.* overlay
```

### Secrets (agenix)

Secrets are opt-in per file: the config builds without them and picks each one up as soon as its `.age` file exists.

```bash
cd secrets
agenix -e smb-credentials.age    # cifs credentials file (username=/password=)
agenix -e tailscale-authkey.age  # reusable auth key → tailscaled-autoconnect
```

### Cisco Packet Tracer

The AppImage is behind a Cisco login and is referenced via `requireFile`; add it once:

```bash
nix-store --add-fixed sha256 packettracer.AppImage
```

### Key Bindings

Keybindings come from the active desktop shell provider (end-4's `keybinds.lua`); press <kbd>Super</kbd> + <kbd>/</kbd> for the in-shell cheatsheet.

### Development Tools

Pre-configured environment includes:

- **Languages:** Python, Node.js (npm, yarn), Go, Rust tooling.
- **Editors:** Neovim (NvChad based, from `nagih7-dots`), VS Code, Zed.
- **CLI Utilities:** ripgrep, fd, bat, eza, fzf, delta, zoxide.
- **Input Method:** fcitx5 (Unikey)

### Screenshots

| end-4/dots-hyprland                                                     | terminal                                                                   |
| :---------------------------------------------------------------------- | :------------------------------------------------------------------------- |
| <img width="1920" height="1080" alt="image" src="./assets/end-4.png" /> | <img width="1920" height="1080" alt="image" src="./assets/terminal.png" /> |

## Credits

Special thanks to the following projects:

- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)**: For the amazing Hyprland and Quickshell implementation that powers the core UI of this setup.
- **NixOS Community**: For the documentation and tools
