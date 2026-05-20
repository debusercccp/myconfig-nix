{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    jq
    libnotify
    acpi
    rsync
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
}
