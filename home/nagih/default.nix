{
  config,
  pkgs,
  userObj,
  ...
}:

{
  home = {
    username = userObj.username;
    homeDirectory = "/home/${userObj.username}";
  };

  imports = [
    ../common

    # Applications
    ../../modules/home-manager/apps/beekeeper-studio
    ../../modules/home-manager/apps/cisco-packet-tracer
    # (pkgs.callPackage ../../modules/home-manager/build/coccoc { })
  ];

  home.packages = with pkgs; [
    pkgs.unstable.brave
    pkgs.unstable.discord
    pkgs.unstable.spotify
    pkgs.unstable.vscode
    pkgs.unstable.antigravity
    pkgs.unstable.telegram-desktop
    pkgs.unstable.slack
    pkgs.unstable.obsidian
    pkgs.unstable.obs-studio
    pkgs.unstable.drawio
    pkgs.unstable.teams-for-linux
    pkgs.unstable.logseq
    pkgs.rpi-imager
    pkgs.unstable.hugo
    pkgs.unstable.ngrok
    pkgs.unstable.bruno
    pkgs.unstable.teamviewer
    pkgs.unstable.seafile-client
    pkgs.nodejs_24
    pkgs.claude-code
    pkgs.unstable.livecaptions
    pkgs.unstable.kmidimon
    fluidsynth
    qpwgraph
    zed-editor
    zerotierone
    (prismlauncher.override {
      jdks = [
        jdk
        jdk17
      ];
    })
  ];

  home.shellAliases = {
    cls = "clear";
    blog = "cd /home/nagih/hugo";
    nix-config = "cd /home/nagih/Workspaces/config/nixos";

    # === CODE EDITOR WORKFLOW (Enhanced) ===
    code = "cursor";
    idea = "idea-community";

    # === DEVELOPMENT SHORTCUTS ===
    wsp = "cd ~/Workspaces";
    prj = "cd ~/Workspaces/projects";
    noob = "cd ~/Workspaces/noob";
    ptit = "cd ~/Workspaces/ptit";
    vir = "cd ~/Workspaces/virtual";
    janus = "cd ~/Workspaces/projects/Janus";
  };

  programs.git.settings.user = {
    name = userObj.git_name;
    email = userObj.git_email;
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
        identitiesOnly = false;
      };

      "i-* mi-*" = {
        userKnownHostsFile = "/dev/null";
        proxyCommand = "sh -c '${pkgs.awscli2}/bin/aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters \"portNumber=%p\"'";
      };
    };
  };
}
