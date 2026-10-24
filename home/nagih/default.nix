{
  config,
  lib,
  pkgs,
  userObj,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home = {
    username = userObj.username;
    homeDirectory = "/home/${userObj.username}";
  };

  imports = [
    ../common
    ./caelestia
    ../../modules/home-manager/apps/beekeeper-studio.nix
    # ../../modules/home-manager/apps/cisco-packet-tracer.nix
  ];

  home.packages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
    inputs.claude-desktop.packages.${system}.default
    pkgs.unstable.discord
    pkgs.unstable.vscode
    pkgs.unstable.telegram-desktop
    pkgs.unstable.obsidian
    pkgs.unstable.teams-for-linux
    pkgs.unstable.bruno
    pkgs.unstable.claude-code
    pkgs.unstable.livecaptions
    pkgs.unstable.kmidimon
    fluidsynth
    qpwgraph
    udisks
    calibre
    awscli2
    jellyfin
    syncplay
    unrar
    vlc
    drawio
    virt-viewer
    omnissa-horizon-client
    kdePackages.kdenlive
    git-credential-manager
    gitFull
    # (prismlauncher.override {
    #   jdks = [
    #     jdk
    #     jdk17
    #   ];
    # })
    (writeShellScriptBin "kfx-convert" ''
      set -euo pipefail

      INPUT=''${1:?Usage: kfx-convert input.epub [output.kfx]}
      OUTPUT=''${2:-"''${INPUT%.*}.kfx"}

      if [[ ! -f "$INPUT" ]]; then
        echo "❌ File not exits: $INPUT" >&2
        exit 1
      fi

      echo "📚 Rendering EPUB → KFX: $INPUT → $OUTPUT"

      docker run --rm -it \
        -v "$PWD:/app:rw" \
        yshalsager/calibre-with-kfx \
        "$INPUT" "$OUTPUT" \
        --pages 0 \
        --book

      echo "✅ Done: $OUTPUT"
    '')

    # Nissan Nexus IDP
    nodejs_22
  ];

  home.shellAliases = {
    cls = "clear";
    blog = "cd /home/nagih/hugo";
    nix-config = "cd /home/nagih/Workspaces/config/nixos";

    idea = "idea-community";

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

    settings = {
      "devbox" = {
        hostname = "10.10.60.10";
        user = "nagih";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };

      "macos" = {
        hostname = "192.168.0.16";
        user = "nghiavm7";
        port = 22;
        identityFile = "~/.ssh/id_ed25519";
      };

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

  # Claude Desktop runs in a bwrap user namespace where root-owned nix store
  # files appear as "nobody", so OpenSSH rejects a symlinked ~/.ssh/config
  # ("Bad owner or permissions"). Replace the symlink with a user-owned copy.
  home.file.".ssh/config".force = true;

  home.activation.sshConfigMutable = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    f="$HOME/.ssh/config"
    if [ -L "$f" ]; then
      src="$(readlink -f "$f")"
      rm "$f"
      install -m 600 "$src" "$f"
    fi
  '';
}
