{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.host) gpu cpu;
  isNvidia = gpu == "nvidia";
  isIntel = cpu == "intel";
in
{
  # === GRAPHICS HARDWARE SUPPORT ===
  # extraPackages is for driver-side packages only (VA-API / Vulkan ICDs);
  # user-facing tools go to environment.systemPackages below.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = lib.optionals isNvidia [ pkgs.nvidia-vaapi-driver ];
  };

  zramSwap.enable = true;

  # powertop --auto-tune is a laptop optimisation: on a desktop it enables USB
  # autosuspend, which makes mice/keyboards/audio interfaces drop out.
  powerManagement.enable = true;
  services.upower.enable = true;
  services.thermald.enable = isIntel;
  services.power-profiles-daemon.enable = false;
  services.xserver.videoDrivers = lib.optional (gpu != "none") gpu;
  services.flatpak.enable = true;

  # === GPU CONFIGURATION ===
  # The nvidia module already loads nvidia/nvidia_modeset/nvidia_uvm/nvidia_drm
  # and blacklists nouveau when videoDrivers contains "nvidia".
  hardware.nvidia = lib.mkIf isNvidia {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  hardware.nvidia-container-toolkit.enable = isNvidia;

  # === GRAPHICS TOOLS ===
  environment.systemPackages =
    with pkgs;
    [
      libva-utils # vainfo
      vulkan-tools # vulkaninfo, vkcube
      vulkan-validation-layers
      p11-kit
    ]
    ++ lib.optionals isNvidia [ nvtopPackages.nvidia ];
}
