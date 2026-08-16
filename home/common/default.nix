{
  config,
  pkgs,
  lib,
  unstable,
  inputs,
  systemVars,
  hostVars,
  userObj,
  ...
}:

{
  programs.home-manager.enable = true;
  home.stateVersion = systemVars.homeManagerVersion;

  imports = [
    ../../modules/home-manager
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

  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
    cache=${config.home.homeDirectory}/.npm-cache
    init-author-name=${userObj.username}
    init-author-email=${userObj.email}
    init-license=MIT
    save-exact=true
    package-lock=true
  '';

  home.shellAliases = {
    oh = "cd ~/ && echo 'Went back home'";
    nh = "nocorrect nh";
    task = "nocorrect task";

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

}
