{ config, pkgs, ... }:

{
  # === VERSION CONTROL SYSTEM ===
  programs.git = {
    enable = true; # Enable Git system-wide
    config = {
      credential.helper = "store"; # Store credentials in memory
      init.defaultBranch = "main"; # Use 'main' as default branch name (modern standard)
      pull.rebase = false; # Use merge strategy for git pull (safer default)
    };
  };

  environment.systemPackages = with pkgs; [
    git # Distributed version control system
    git-lfs # Git Large File Storage for handling large binary files
  ];
}
