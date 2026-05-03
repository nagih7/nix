{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5; # Number of boot entries to keep
        editor = false;
        consoleMode = "auto"; # Options: "auto", "max", "0", "1", "2"
      };

      timeout = 5;
      efi = {
        canTouchEfiVariables = true; # Allow writing to EFI variables
        efiSysMountPoint = "/boot"; # EFI partition mount point (or "/boot/efi")
      };
    };

    kernelParams = [
      "quiet"
      "splash"
    ];

    plymouth.enable = true;

    kernelModules =
      [ ]
      ++ lib.optionals (hostVars.cpu == "intel") [ "kvm-intel" ]
      ++ lib.optionals (hostVars.cpu == "amd") [ "kvm-amd" ];

    extraModulePackages = [ ];

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_amd nested=1
    '';
  };

  # === NIX STORE MANAGEMENT AND OPTIMIZATION ===
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
  };

  environment.systemPackages =
    with pkgs;
    [
    ]
    ++ lib.optionals (hostVars.cpu == "intel") [
      intel-gpu-tools
      libva-utils
    ]
    ++ lib.optionals (hostVars.cpu == "amd") [
      radeontop
    ];
}
