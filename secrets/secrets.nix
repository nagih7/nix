# agenix recipient list. Used by the `agenix` CLI only (not by the flake):
#
#   cd secrets
#   agenix -e smb-credentials.age     # cifs credentials file:
#                                     #   username=...
#                                     #   password=...
#                                     #   domain=...   (optional)
#   agenix -e tailscale-authkey.age   # a reusable auth key from the admin console
#
# Each secret is decrypted on the host with its /etc/ssh/ssh_host_ed25519_key
# (see age.identityPaths in modules/nixos/secrets.nix); the user key is added
# so you can edit the files from your own account.
let
  nagih = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5zy0044P9cHpQ9zhu3wdnGzPrYIeVHavdd3sxeopHU vuongmanhnghia@gmail.com";
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFEZBe4EhYSeInjCVp/GKmPjlsCRivRBCqyjuMYPhu35 root@nixos";

  all = [
    nagih
    desktop
  ];
in
{
  "smb-credentials.age".publicKeys = all;
  "tailscale-authkey.age".publicKeys = all;
}
