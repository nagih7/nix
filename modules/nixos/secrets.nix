# agenix-managed secrets. Each secret is only wired up once its encrypted
# file exists in ../../secrets, so the config keeps evaluating on a fresh
# checkout; consumers (smb.nix, tailscale.nix) fall back to their manual
# paths / no-op until then. Recipients are listed in secrets/secrets.nix.
{
  config,
  lib,
  ...
}:

let
  secretsDir = ../../secrets;
  secretFile = name: secretsDir + "/${name}.age";
  hasSecret = name: builtins.pathExists (secretFile name);

  mkSecret =
    name: extra:
    lib.mkIf (hasSecret name) {
      ${name} = {
        file = secretFile name;
      }
      // extra;
    };
in
{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  age.secrets = lib.mkMerge [
    (mkSecret "smb-credentials" { })
    (mkSecret "tailscale-authkey" { })
  ];

  services.tailscale.authKeyFile = lib.mkIf (hasSecret "tailscale-authkey") (
    config.age.secrets.tailscale-authkey.path
  );
}
