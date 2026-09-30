# Nix-level declarations for the caelestia desktop shell, alongside the
# live-symlinked hypr-vars.lua/hypr-user.lua/cli.json/templates/ in this
# same directory (see modules/home-manager/dotfiles/caelestia-shell for how
# those get wired in). Unlike those, this file only takes effect through
# `home-manager switch` — it's not a live-reloaded runtime file, just a
# convenient single place to keep every caelestia-related setting instead
# of splitting them between here and home/nagih/default.nix.
{
  # See modules/home-manager/dotfiles/caelestia-shell for how/when these
  # get applied to ~/.config/caelestia/shell.json (short version: seeded
  # once each, only if genuinely missing — never overwrites a value you or
  # the shell itself later changes).
  custom.caelestiaShell.shellJsonDefaults = {
    osd = {
      enableMicrophone = true;
      enableBrightness = false;
    };
  };
}
