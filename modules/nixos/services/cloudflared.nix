{ hostVars, ... }:

{
  config = {
    services.cloudflared = {
      enable = false;
    };
  };
}
