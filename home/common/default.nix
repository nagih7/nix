{
  config,
  systemVars,
  hostVars,
  userObj,
  ...
}:

{
  programs.home-manager.enable = true;
  home.stateVersion = systemVars.homeManagerVersion;

  programs.direnv.enable = true;

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
    EDITOR = "nvim";
    VISUAL = "nvim";

    DOWNLOAD_DIR = "${config.home.homeDirectory}/Downloads";
    DOCUMENTS_DIR = "${config.home.homeDirectory}/Documents";
    NIX_CONFIG_DIR = hostVars.nixConfig;
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

    # --- System (NH_FLAKE is exported by programs.nh; the flake is pure) ---
    nixs = "nh os switch";
    nixt = "nh os test";
    nixu = "nix flake update --flake $NH_FLAKE";
    hms = "nh home switch -b bak";
    nixc = "nh clean all --keep 3";
    nixf = "nh search";

    hdt = "hyprctl keyword debug:overlay true";
    hdf = "hyprctl keyword debug:overlay false";
  };
}
