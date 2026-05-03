{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = "$character $os$directory(fg:#7aa2f7) $git_branch$git_status$kubernetes$docker_context$terraform$nix_shell$cmd_duration";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      os = {
        disabled = false;
        style = "bold fg:#7aa2f7";
        symbols = {
          NixOS = "  ";
        };
      };

      directory = {
        style = "bold fg:#7aa2f7";
        format = "[$path]($style) ";
        truncation_length = 1;
        truncation_symbol = "";
        truncate_to_repo = false;
      };

      git_branch = {
        symbol = "󰘬 ";
        style = "bold green";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        modified = "[● ](bold red)";
        staged = "[+ ](bold green)";
        deleted = "[✘ ](bold red)";
        renamed = "[» ](bold yellow)";
        untracked = "[? ](bold magenta)";

        format = "([$all_status]($style))";
      };

      kubernetes = {
        symbol = "󱃾 ";
        style = "fg:#7dcfff";
        format = "[$symbol$context( \($namespace\))]($style) ";
      };

      docker_context = {
        symbol = "󰡨 ";
        style = "fg:#7dcfff";
        format = "[$symbol$context]($style) ";
      };

      nix_shell = {
        symbol = " ";
        style = "fg:#7dcfff";
        format = "[$symbol$state]($style) ";
      };

      cmd_duration = {
        min_time = 500;
        format = "took [$duration](bold yellow) ";
      };
    };
  };
}
