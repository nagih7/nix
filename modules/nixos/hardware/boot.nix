{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.host) cpu;
in
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
        consoleMode = "auto";
      };

      timeout = 5;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelParams = [
      "quiet"
      "splash"
    ];

    plymouth.enable = true;

    kernelModules = lib.optional (cpu == "intel") "kvm-intel" ++ lib.optional (cpu == "amd") "kvm-amd";

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_amd nested=1
    '';
  };

  # === NIX ===
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # nh owns rebuilds and garbage collection (replaces nix.gc); it also
  # exports NH_FLAKE so `nh os switch` / `nh home switch` need no arguments.
  programs.nh = {
    enable = true;
    flake = config.host.nixConfig;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 7d";
    };
  };

  environment.systemPackages =
    with pkgs;
    lib.optionals (cpu == "intel") [
      intel-gpu-tools
      libva-utils
    ]
    ++ lib.optionals (cpu == "amd") [
      radeontop
    ];
}
