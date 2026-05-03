{ config, pkgs, ... }:

{
  hardware = {
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };
}
