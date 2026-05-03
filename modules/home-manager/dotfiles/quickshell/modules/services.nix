{
  config,
  pkgs,
  quickshell,
  ...
}:

{
  # === SYSTEMD USER SERVICES ===
  systemd.user.services = {
    ydotool = {
      Unit = {
        Description = "Ydotool daemon";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ydotool}/bin/ydotoold";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    ollama = {
      Unit = {
        Description = "Ollama AI Service";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    cliphist-watch = {
      Unit = {
        Description = "Clipboard history watcher";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store'";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
