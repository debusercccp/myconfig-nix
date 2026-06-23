{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    jq
    libnotify
    acpi
    rsync
    util-linux
    blueman

    # Python con le librerie usate dagli script:
    #  - requests: meteo (wttr.py)
    #  - icalendar / recurring-ical-events: calendario Google via iCal
    #    (cal-sync.py; sostituisce il virtualenv usato su Arch/Debian)
    (python3.withPackages (ps: [
      ps.requests
      ps.icalendar
      ps."recurring-ical-events"
    ]))
  ];

  # Script Batteria
  home.file.".local/bin/batteryMonitor" = {
    executable = true;
    source = ./config/waybar-niri/scripts/batteryMonitor.sh;
  };

  # Script Backup HDD
  home.file.".local/bin/backup-hdd-check" = {
    executable = true;
    source = ./config/waybar-niri/scripts/backup-hdd-check.sh;
  };

  # Script Test Notifiche
  home.file.".local/bin/test-notifications" = {
    executable = true;
    source = ./config/waybar-niri/scripts/test-notifications.sh;
  };

  # Script Meteo
  home.file.".local/bin/wttr.py" = {
    executable = true;
    source = ./config/waybar-niri/scripts/wttr.py;
  };

  # Script Luce Notturna (Nightlight)
  home.file.".local/bin/nightlight.sh" = {
    executable = true;
    source = ./config/waybar-niri/scripts/nightlight.sh;
  };

  # Script Gestione Dischi (Mounts)
  home.file.".local/bin/mounts.sh" = {
    executable = true;
    source = ./config/waybar-niri/scripts/mounts.sh;
  };

  # Script di Aggiornamento Sistema
  home.file.".local/bin/update-sys" = {
    executable = true;
    source = ./config/waybar-niri/scripts/update-sys;
  };
}
