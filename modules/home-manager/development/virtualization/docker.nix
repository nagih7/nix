{
  config,
  pkgs,
  hostVars,
  ...
}:

{
  home.packages = with pkgs; [
    docker-compose
  ];
}
