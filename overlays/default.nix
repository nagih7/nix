# Top-level overlay. `pkgs.unstable.<name>` gives the nixpkgs-unstable build of
# a package on top of the stable base.
{ inputs, system }:
final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  # Not in nixpkgs (Apple's own SF Pro license restricts use to software
  # built for Apple platforms — using it as a general Linux system font is
  # outside those terms, though extremely common practice; see
  # gui/fontconfig.nix for where this is actually wired in). Sourced from a
  # community GitHub mirror of Apple's own developer.apple.com download,
  # pinned to a specific commit for reproducibility. Verified (via
  # fontTools) to have full Vietnamese diacritic coverage before choosing
  # this over the open-licensed SN Pro alternative.
  #
  # Also carries SF Mono (same mirror, same commit): SF Pro is a
  # proportional UI face, not usable as a terminal/monospace font — SF Mono
  # is Apple's actual monospace family and is what dotfiles/alacritty
  # points at. Verified separately for the same Vietnamese coverage.
  sf-pro = final.stdenvNoCC.mkDerivation {
    pname = "sf-pro";
    version = "unstable-2024-05-24";

    src = final.fetchFromGitHub {
      owner = "oyezcubed";
      repo = "Apple-Fonts-San-Francisco-New-York";
      rev = "5a8fc7d569fa2b4fb5fe9a63ad66e5cf9ae00eae";
      hash = "sha256-NBvWqHMaieaCZffqNitnhn979Sl2bAkIwC5sWW24z7g=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm444 -t "$out/share/fonts/opentype" "$src/SF Pro"/*.otf
      install -Dm444 -t "$out/share/fonts/truetype" "$src/SF Pro"/*.ttf
      install -Dm444 -t "$out/share/fonts/opentype" "$src/SF Mono"/*.otf
      runHook postInstall
    '';

    meta = {
      description = "Apple's SF Pro Display/Text/Rounded and SF Mono typefaces";
      homepage = "https://developer.apple.com/fonts/";
      license = final.lib.licenses.unfree;
      platforms = final.lib.platforms.all;
    };
  };
}
