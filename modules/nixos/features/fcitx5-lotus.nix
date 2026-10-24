# System-level half of the Lotus Vietnamese input method.
#
# fcitx5-lotus is not a pure fcitx5 addon: its uinput typing modes (Smooth,
# SuperSmooth, Select, Minecraft) are driven by a privileged helper daemon that
# synthesises key events through /dev/uinput. The package ships the unit, udev
# rule, sysusers entry and modules-load entry for that daemon under lib/, but
# home-manager's i18n.inputMethod only pulls share/ and lib/fcitx5/ into the
# fcitx5 wrapper -- so none of it gets installed by
# modules/home-manager/dotfiles/fcitx5. Hence this module.
#
# Without it the addon still loads and Mode=Preedit works; the uinput modes
# just fail with "Cannot connect to uinput server".
{
  config,
  pkgs,
  lib,
  ...
}:

let
  lotus = pkgs.unstable.fcitx5-lotus;
in
{
  # The package's modules-load.d/fcitx5-lotus.conf is not read by NixOS.
  boot.kernelModules = [ "uinput" ];

  # Equivalent of the package's sysusers.d/lotus.conf. The unit runs as this
  # user, and the udev rule grants it rw on /dev/uinput via setfacl.
  users.users.uinput_proxy = {
    isSystemUser = true;
    group = "uinput_proxy";
    extraGroups = [ "input" ]; # unit sets Group=input
    description = "Lotus Uinput Proxy";
  };
  users.groups.uinput_proxy = { };

  services.udev.packages = [ lotus ]; # 99-lotus.rules
  systemd.packages = [ lotus ]; # fcitx5-lotus-server@.service

  # The daemon is a template unit, one instance per user ("-u %i"). asDropin
  # keeps the package's unit body and only adds the Install wiring.
  systemd.services =
    lib.genAttrs (map (u: "fcitx5-lotus-server@${u.username}") config.host.users)
      (_: {
        overrideStrategy = "asDropin";
        wantedBy = [ "multi-user.target" ];
      });
}
