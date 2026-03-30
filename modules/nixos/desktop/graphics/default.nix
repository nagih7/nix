{
  config,
  pkgs,
  lib,
  hostVars,
  ...
}:
{
  # === GRAPHICS HARDWARE SUPPORT ===
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages =
      with pkgs;
      [
        vulkan-loader # Vulkan graphics API loader
        vulkan-tools # Vulkan utilities
        vulkan-validation-layers # Vulkan debugging and validation
      ]
      ++ lib.optionals (hostVars.gpu == "nvidia") [
        nvidia-vaapi-driver
        nvtopPackages.nvidia
        nvidia-container-toolkit
      ];
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  services.upower.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.xserver.videoDrivers = [ hostVars.gpu ];
  services.flatpak.enable = true;

  # === GPU CONFIGURATION ===
  hardware.nvidia = lib.mkIf (hostVars.gpu == "nvidia") {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  boot.kernelModules = lib.mkIf (hostVars.gpu == "nvidia") [
    "nvidia" # Main NVIDIA driver module
    "nvidia_modeset" # Modesetting support for Wayland
    "nvidia_uvm" # Unified Virtual Memory support
    "nvidia_drm" # Direct Rendering Manager support
  ];

  boot.blacklistedKernelModules = [
    "nouveau"
  ];

  # === ADDITIONAL GRAPHICS TOOLS ===
  environment.systemPackages = with pkgs; [
    libva-utils # VA-API utilities for testing video acceleration
    vulkan-tools # Vulkan utilities (vulkaninfo, vkcube)
    powertop # Power management tool
    p11-kit # PKCS#11 module management
  ];
}
