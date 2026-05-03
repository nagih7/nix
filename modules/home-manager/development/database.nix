{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    sqlc # SQL compiler - generates type-safe code from SQL
    goose # Database migration tool
  ];
}
