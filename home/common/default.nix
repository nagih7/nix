{
  config,
  pkgs,
  lib,
  unstable,
  inputs,
  systemVars,
  hostVars,
  ...
}:

let
  git = "${pkgs.git}/bin/git";
  dotfilesRepo = "https://github.com/nagih7/dotfiles.git";
  dotfilesDir = "${hostVars.nixConfig}/dotfiles";
in
{
  programs.home-manager.enable = true;
  home.stateVersion = systemVars.homeManagerVersion;

  imports = [
    # Desktop
    ../../modules/home-manager/desktop/hyprland
    ../../modules/home-manager/desktop/hyprlock
    ../../modules/home-manager/desktop/hypridle
    ../../modules/home-manager/desktop/xdg-portal

    # Features
    ../../modules/home-manager/features/quickshell
    ../../modules/home-manager/features/zsh
    ../../modules/home-manager/features/nvim
    ../../modules/home-manager/features/wezterm
    ../../modules/home-manager/features/tmux
    ../../modules/home-manager/features/git
    ../../modules/home-manager/features/fcitx5
    ../../modules/home-manager/features/mpv
    ../../modules/home-manager/features/nemo
    ../../modules/home-manager/features/fastfetch
    ../../modules/home-manager/features/ripgrep
    ../../modules/home-manager/features/starship
    ../../modules/home-manager/features/cava
    ../../modules/home-manager/features/kitty
    ../../modules/home-manager/features/qimgv
    ../../modules/home-manager/features/dolphin

    # CLI
    ../../modules/home-manager/features/cli/nix
    ../../modules/home-manager/features/cli/utils
    ../../modules/home-manager/features/cli/devtools

    # GUI
    ../../modules/home-manager/gui/cursor
    ../../modules/home-manager/gui/fontconfig
    ../../modules/home-manager/gui/gtk-theme
    ../../modules/home-manager/gui/kde
    ../../modules/home-manager/gui/kvantum
    ../../modules/home-manager/gui/matugen
    ../../modules/home-manager/gui/qt5ct
    ../../modules/home-manager/gui/qt6ct

    # Development
    ../../modules/home-manager/development/database
    ../../modules/home-manager/development/lsp/python
    ../../modules/home-manager/development/lsp/golang
    # ../../modules/home-manager/development/lsp/cpp
    ../../modules/home-manager/development/virtualization/iac
    ../../modules/home-manager/development/virtualization/machines
    ../../modules/home-manager/development/virtualization/docker
    ../../modules/home-manager/development/virtualization/kubernetes
    ../../modules/home-manager/development/networking
  ];

  programs.direnv.enable = true;

  services.syncthing = hostVars.syncthing;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    documents = "${config.home.homeDirectory}/Documents";
    pictures = "${config.home.homeDirectory}/Pictures";

    extraConfig = {
      XDG_DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
      XDG_WORKSPACES_DIR = "${config.home.homeDirectory}/Workspaces";
    };
  };

  home.sessionVariables = {
    NH_FLAKE = hostVars.nixConfig;
    HOSTNAME = hostVars.hostname;
    # Editor
    EDITOR = "nvim";
    VISUAL = "nvim";

    # Directories
    DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
    DOCUMENTS_DIR = "${config.home.homeDirectory}/Documents";
    NIX_CONFIG_DIR = "${hostVars.nixConfig}";
  };

  home.shellAliases = {
    oh = "cd ~/ && echo 'Went back home'";
    nh = "nocorrect nh";

    docs = "cd ~/Documents";
    down = "cd ~/Downloads";

    # --- System Operations ---
    nixs = "nh os switch $NH_FLAKE --hostname $HOSTNAME --impure";
    nixu = "nix flake update";
    nixt = "nh os test $NH_FLAKE --hostname $HOSTNAME --impure";

    # --- Home Manager ---
    hms = "nh home switch $NH_FLAKE --impure -b bak";

    # --- Garbage Collection (Dọn rác) ---
    nixc = "nh clean all --keep 3";

    # --- Developer Tools ---
    nixf = "nh search";

    hdt = "hyprctl keyword debug:overlay true";
    hdf = "hyprctl keyword debug:overlay false";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    extraConfig = ''
      AddKeysToAgent yes
      IdentityFile ~/.ssh/id_ed25519
    '';

    matchBlocks = {
      "*" = {
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
        identitiesOnly = true;
      };
    };
  };

  home.activation.cloneDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${dotfilesDir}" ]; then
      ${git} clone ${dotfilesRepo} "${dotfilesDir}"
    else
      cd "${dotfilesDir}"
      ${git} fetch origin main
      
      LOCAL=$(${git} rev-parse @)
      REMOTE=$(${git} rev-parse @{u})
      
      if [ $LOCAL != $REMOTE ]; then
        ${git} pull
      fi
    fi
  '';
}
