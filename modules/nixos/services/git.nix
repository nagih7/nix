{ pkgs, ... }:

{
  # Per-user git config (identity, delta, credential helper) lives in
  # home-manager dotfiles/git; the system only provides the binaries.
  environment.systemPackages = with pkgs; [
    git
    git-lfs
  ];
}
