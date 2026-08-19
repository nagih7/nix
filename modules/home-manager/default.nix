{
  imports = [
    # Desktop shell (must come before the desktop/dotfiles modules that
    # read config.custom.desktopShell)
    ./desktop-shell

    # Desktop
    ./desktop/hyprland
    ./desktop/hyprlock
    ./desktop/hypridle.nix
    ./desktop/xdg-portal.nix

    # Dotfiles
    ./dotfiles/quickshell
    ./dotfiles/zsh
    ./dotfiles/nvim
    ./dotfiles/wezterm
    ./dotfiles/tmux
    ./dotfiles/git
    ./dotfiles/fcitx5
    ./dotfiles/mpv
    # ./dotfiles/nemo
    ./dotfiles/fastfetch
    ./dotfiles/ripgrep
    ./dotfiles/starship
    ./dotfiles/cava
    ./dotfiles/kitty
    ./dotfiles/qimgv
    ./dotfiles/dolphin
    ./dotfiles/taskwarrior

    # GUI
    ./gui/cursor.nix
    ./gui/fontconfig.nix
    ./gui/gtk-theme
    ./gui/kde.nix
    ./gui/qt-theme.nix
    ./gui/matugen
    ./gui/multimedia.nix

    # Development
    ./development/cli.nix
    ./development/database.nix
    ./development/lsp/python.nix
    ./development/lsp/golang.nix
    ./development/virtualization/iac.nix
    ./development/virtualization/machine.nix
    ./development/virtualization/docker.nix
    ./development/virtualization/kubernetes.nix
    ./development/networking.nix
  ];
}
