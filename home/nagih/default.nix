{
  config,
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
    ../../modules/home-manager/apps/beekeeper-studio.nix
    ../../modules/home-manager/apps/cisco-packet-tracer.nix
  ];

  home.packages = with pkgs; [
    inputs.zen-browser.packages.${system}.default
    inputs.claude-desktop.packages.${system}.default
    pkgs.unstable.discord
    pkgs.unstable.spotify
    pkgs.unstable.vscode
    pkgs.unstable.antigravity
    pkgs.unstable.telegram-desktop
    pkgs.unstable.slack
    pkgs.unstable.obsidian
    pkgs.unstable.teams-for-linux
    pkgs.unstable.hugo
    pkgs.unstable.bruno
    pkgs.unstable.google-chrome
    pkgs.nodejs_24
    pkgs.yarn
    pkgs.unstable.claude-code
    pkgs.unstable.gemini-cli
    pkgs.unstable.github-copilot-cli
    pkgs.unstable.qwen-code
    pkgs.unstable.codex
    pkgs.unstable.livecaptions
    pkgs.unstable.kmidimon
    fluidsynth
    qpwgraph
    zed-editor
    udisks
    calibre
    awscli2
    talosctl
    wireguard-tools
    wireguard-ui
    jellyfin
    syncplay
    unrar
    vlc
    drawio
    virt-viewer
    omnissa-horizon-client
    (prismlauncher.override {
      jdks = [
        jdk
        jdk17
      ];
    })
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

  # Syncthing is per-user state, not host metadata.
  services.syncthing = {
    enable = true;

    settings = {
      gui = {
        address = "127.0.0.1:8384";
        user = "nagih";
      };

      devices = {
        "nixos-desktop" = {
          id = "CQA7ZJT-S4HOWZ5-TZLMHEC-B7XGZB4-XWVA7BM-IPR3RPL-SCTFXIA-O6GSHQQ";
        };
        "syncthing-server" = {
          id = "6DLXC5P-OYUDW5M-7NYJOSU-3DHKU65-2KECRVD-MEVDAF4-CYTOJWE-7NJXFAF";
          addresses = [ "tcp://14.225.218.83:22000" ];
        };
      };

      # Folder IDs must stay exactly as the server knows them.
      folders =
        let
          shared = id: dir: {
            inherit id;
            path = "/home/nagih/${dir}";
            devices = [
              "nixos-desktop"
              "syncthing-server"
            ];
          };
        in
        {
          workspaces = shared "workspaces" "Workspaces";
          documents = shared "documents" "Documents";
          pictures = shared "pictures" "Pictures";
          hugo = shared "hugo" "hugo";
        };
    };
  };
}
