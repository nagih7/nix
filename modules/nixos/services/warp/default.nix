{ pkgs, ... }: {
  services.cloudflare-warp.enable = true;

  environment.systemPackages = with pkgs; [
    cloudflare-warp
  ];
}