# Top-level overlay. `pkgs.unstable.<name>` gives the nixpkgs-unstable build of
# a package on top of the stable base.
{ inputs, system }:
final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
}
