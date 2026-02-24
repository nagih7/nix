#!/usr/bin/env bash

# Source utils
_GEN_HOME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GEN_HOME_DIR}/lib/utils.sh"

mkdir -p home/$(whoami)

writer "Generating home/$(whoami)/default.nix..." 0.01

cat > home/$(whoami)/default.nix <<'EOL'
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
  ];

  home.packages = with pkgs; [
    pkgs.unstable.brave
    pkgs.unstable.discord
    pkgs.unstable.spotify
    pkgs.unstable.vscode
  ];

  programs.git.settings.user = {
    name = userObj.git_name;
    email = userObj.git_email;
  };

  home.shellAliases = { };
}
EOL
