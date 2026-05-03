{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    file-roller # Archive manager
  ];

  services.tumbler.enable = true;
}
