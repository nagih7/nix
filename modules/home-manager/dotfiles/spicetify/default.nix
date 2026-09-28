# ███████╗██████╗ ██╗ ██████╗███████╗████████╗██╗███████╗██╗   ██╗
# ██╔════╝██╔══██╗██║██╔════╝██╔════╝╚══██╔══╝██║██╔════╝╚██╗ ██╔╝
# ███████╗██████╔╝██║██║     █████╗     ██║   ██║█████╗   ╚████╔╝
# ╚════██║██╔═══╝ ██║██║     ██╔══╝     ██║   ██║██╔══╝    ╚██╔╝
# ███████║██║     ██║╚██████╗███████╗   ██║   ██║██║        ██║
# ╚══════╝╚═╝     ╚═╝ ╚═════╝╚══════╝   ╚═╝   ╚═╝╚═╝        ╚═╝
# -------------------------------------------------------------------------
# spicetify patches Spotify's client bundle in place (unpacks
# Apps/xpui.spa into Apps/xpui/, rewrites files under it) — impossible
# against a /nix/store install, which is read-only.
#
# First attempt: rsync the whole tree into a writable copy and patch that.
# Doesn't work — nixpkgs' own launcher wrapper (the file literally named
# "spotify" next to the real binary) has an *absolute exec path* baked in
# by makeWrapper at build time, pointing back at the original /nix/store
# location no matter where you copy the wrapper *script* itself; the real
# binary (.spotify-wrapped) then resolves its own Apps/ relative to that
# same real, pristine location. Confirmed empirically: copying the wrapper
# elsewhere and running it still launches the unpatched original.
#
# Second attempt (this one): keep the real binary and its wrapper exactly
# where Nix put them, but bind-mount the writable, spicetify-patched Apps/
# *over* the real Apps/ path for that one process tree, via bubblewrap.
# Transparent to Spotify — no code on its side needs to know its resources
# moved. spicetify apply/watch still only ever touches the writable copy.
# This keeps caelestia-cli's own `spicetify watch -s` workflow (dynamic
# recolouring on every scheme/wallpaper change, driven by
# ~/.config/spicetify/Themes/caelestia/color.ini, written by
# apply_spicetify() in its utils/theme.py) working like a non-Nix install —
# unlike spicetify-nix, whose build-time bake freezes colours until the
# next `home-manager switch` (tried first; see git history).
#
# Cost: an extra ~200MB writable copy of Apps/, and every
# `home-manager switch` re-syncs + re-applies (a few seconds), because the
# sync necessarily wipes any previously-unpacked Apps/xpui/ patch.

{
  config,
  lib,
  pkgs,
  caelestia-dots,
  ...
}:

let
  home = config.home.homeDirectory;
  spotifySrc = "${pkgs.unstable.spotify}/share/spotify";
  writableSpotify = "${home}/.local/share/spotify-writable";

  # Installed as ${writableSpotify}/spotify — the exact file
  # SpotifyStart()/SpotifyRestart() in spicetify-cli's src/cmd/restart.go
  # execs (via filepath.Join(spotify_path, "spotify")) when caelestia-cli's
  # `spicetify watch -s` (kbMusicWs) auto-launches Spotify.
  bwrapLauncher = pkgs.writeShellScript "spotify-bwrap-launcher" ''
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --dev-bind / / \
      --bind "${writableSpotify}/Apps" "${spotifySrc}/Apps" \
      -- "${spotifySrc}/spotify" "$@"
  '';
in
{
  home.packages = [
    pkgs.spicetify-cli
    pkgs.rsync
    pkgs.bubblewrap

    # Overrides the "spotify" command everywhere (app launcher, a terminal)
    # to the same bind-mount launcher, so manually running `spotify` gets
    # the theme too, not just caelestia's own toggle. Do not also install
    # pkgs.unstable.spotify directly — that would just reintroduce an
    # unthemed "spotify" binary shadowing this one.
    (pkgs.writeShellScriptBin "spotify" ''
      exec "${writableSpotify}/spotify" "$@"
    '')
  ];

  # user.css (the theme's actual CSS rules) never changes at runtime — seed
  # once, like hypr/scheme/current.lua. color.ini next to it is the mutable
  # part (caelestia-cli atomic_writes it on every scheme change) — never
  # touched here.
  home.activation.syncWritableSpotify = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${home}/.config/spicetify/Themes/caelestia"

    if [ ! -f "${home}/.config/spicetify/Themes/caelestia/user.css" ]; then
      $DRY_RUN_CMD install -m 0644 "${caelestia-dots}/spicetify/Themes/caelestia/user.css" \
        "${home}/.config/spicetify/Themes/caelestia/user.css"
    fi

    $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete "${spotifySrc}/" "${writableSpotify}/"
    $DRY_RUN_CMD chmod -R u+w "${writableSpotify}"
    $DRY_RUN_CMD install -m 0755 "${bwrapLauncher}" "${writableSpotify}/spotify"

    $DRY_RUN_CMD ${pkgs.spicetify-cli}/bin/spicetify \
      config spotify_path "${writableSpotify}" current_theme caelestia color_scheme caelestia \
      >/dev/null 2>&1 || true
    $DRY_RUN_CMD ${pkgs.spicetify-cli}/bin/spicetify backup apply >/dev/null 2>&1 || true
  '';
}
