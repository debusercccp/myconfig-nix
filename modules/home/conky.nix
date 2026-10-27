{ pkgs, ... }:

{
  # Il pacchetto conky è installato in niri.nix.
  # ~/.config/conky/conky.conf è generato da matugen (theme.nix), non linkato qui.
  systemd.user.services.conky = {
    Unit = {
      Description = "Conky System Monitor";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.conky}/bin/conky -c %h/.config/conky/conky.conf";
      Restart = "on-failure";
      # Terminazione rapida: conky a volte si blocca sul SIGTERM
      TimeoutStopSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
