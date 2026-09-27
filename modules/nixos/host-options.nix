# Typed schema for hosts/<name>/variables.nix.
#
# variables.nix stays a plain attrset (flake.nix and home-manager read it as
# data), but it is also assigned to `config.host` here so every key is
# type-checked and unknown keys are rejected at eval time. NixOS modules read
# config.host.* rather than the raw hostVars.
{
  lib,
  hostVars,
  ...
}:

let
  inherit (lib) mkOption types;

  userModule = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      username = mkOption { type = types.str; };
      description = mkOption {
        type = types.str;
        default = "";
      };
      email = mkOption { type = types.str; };
      git_name = mkOption { type = types.str; };
      git_email = mkOption { type = types.str; };
    };
  };
in
{
  options.host = {
    hostname = mkOption { type = types.str; };

    # Absolute path of this repo on the machine (used by nh).
    nixConfig = mkOption { type = types.str; };

    cpu = mkOption {
      type = types.enum [
        "intel"
        "amd"
      ];
    };

    gpu = mkOption {
      type = types.enum [
        "nvidia"
        "amdgpu"
        "intel"
        "none"
      ];
    };

    nameservers = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    fallbackDns = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };

    firewall = {
      tcpPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
      };
      udpPorts = mkOption {
        type = types.listOf types.port;
        default = [ ];
      };
      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };

    tailscale.enable = mkOption {
      type = types.bool;
      default = false;
    };

    users = mkOption {
      type = types.nonEmptyListOf userModule;
    };
  };

  config.host = hostVars;
}
