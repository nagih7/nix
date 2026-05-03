{ config, pkgs, ... }:

{
  # === BLUETOOTH CONFIGURATION ===

  # Enable Bluetooth support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        KernelExperimental = true;
      };
    };
  };

  # Enable blueman applet for Bluetooth management
  services.blueman.enable = true;

  # Install Bluetooth utilities
  environment.systemPackages = with pkgs; [
    bluez # Core Bluetooth stack
    bluez-tools # Command line tools for Bluetooth
  ];
}
