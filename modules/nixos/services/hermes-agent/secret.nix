{ config, pkgs, ... }:

{
  sops.secrets."hermes/env" = {
    sopsFile = ../../../../secrets/hermes.yaml;
    owner = "hermes";
    group = "hermes";
  };

  sops.secrets."hermes/auth" = {
    sopsFile = ../../../../secrets/hermes.yaml;
    owner = "hermes";
    group = "hermes";
  };

  services.hermes-agent = {
    environmentFiles = [ config.sops.secrets."hermes/env".path ];
    # authFile = config.sops.secrets."hermes/auth".path;
  };

  # hermes-agent's activation script only depends on `users` upstream,
  # so it can race ahead of sops-nix's `setupSecrets`. Force the ordering.
  system.activationScripts.hermes-agent-setup.deps = [ "setupSecrets" ];

  # Upstream module writes cli-config.yaml but hermes 0.4.0 reads config.yaml.
  # Symlink so our declarative config is actually loaded.
  systemd.tmpfiles.rules = [
    "L+ /var/lib/hermes/.hermes/config.yaml - - - - cli-config.yaml"
  ];
}
