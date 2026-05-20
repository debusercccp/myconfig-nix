{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    jq
    libnotify
    acpi
    rsync
  ];

  # Script batteria
  home.file.".local/bin/batteryMonitor" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Monitora batteria e avvisa se < 20%
      while true; do
        battery=$(acpi -b | grep -oP '\d+(?=%)')
        if [ "$battery" -lt 20 ]; then
          notify-send "Batteria Bassa" "Carica: $battery%"
        fi
        sleep 60
      done
    '';
  };

  # Script backup
  home.file.".local/bin/backup-hdd-check" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Verifica se HDD esterno è collegato
      if [ -d "/media/backup" ] || [ -d "/mnt/backup" ]; then
        notify-send "Backup HDD" "HDD rilevato, puoi fare backup"
        echo "HDD trovato"
      else
        notify-send "Backup HDD" "HDD non trovato" -u critical
        echo "HDD non trovato"
      fi
    '';
  };

  # Test rapido (per verificare)
  home.file.".local/bin/test-notifications" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      notify-send "Test" "Notifiche funzionano!"
      echo "Notifica inviata"
    '';
  };
}
