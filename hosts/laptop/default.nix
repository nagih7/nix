{ hostVars, ... }:

{
  imports = [
    ./hardware-configuration.nix # Hardware configurations
    ../common
  ];

  services.zerotierone.enable = true;
}
