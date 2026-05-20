{ pkgs, ... }:

let
  # 1. Script per il Backup dell'Hard Disk
  # 1. Script per il Backup dell'Hard Disk
  backupHDD = pkgs.writeShellScriptBin "backupHDD" ''
    #!/bin/sh
    exec > /tmp/pipeline_debug.log 2>&1
    set -x

    UUID_ATTUALE="$1"
    SOURCE="/home/noya/"

    # Usiamo i binari espliciti dal Nix Store
    TARGET=$(${pkgs.util-linux}/bin/lsblk -rn -o UUID,MOUNTPOINT | ${pkgs.gnugrep}/bin/grep "$UUID_ATTUALE" | ${pkgs.gawk}/bin/awk '{print $2}')
    TARGET=$(echo "$TARGET" | ${pkgs.coreutils}/bin/tr -d '\n' | ${pkgs.coreutils}/bin/tr -d '\r')

    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus"
    export XAUTHORITY="/home/noya/.Xauthority"

    invia_notifica() {
        ${pkgs.libnotify}/bin/notify-send "Pipeline HDD" "$1" --icon="$2" -t 5000 || echo "Notifica fallita"
    }

    # ECCOR IL FIX: usiamo ''$ per l'escape dell'interpolazione in Nix string
    LOCKFILE="/tmp/backup_hdd_''${UUID_ATTUALE}.lock"
    if [ -e "$LOCKFILE" ]; then
        PID=$(${pkgs.coreutils}/bin/cat "$LOCKFILE")
        if ${pkgs.procps}/bin/ps -p "$PID" > /dev/null; then
            exit 0
        fi
    fi
    echo $$ > "$LOCKFILE"
    trap 'rm -f "$LOCKFILE"; exit' INT TERM EXIT

    echo "Attendo montaggio..."
    ATTESA=0
    while [ $ATTESA -lt 60 ]; do
        TARGET=$(${pkgs.util-linux}/bin/lsblk -rn -o UUID,MOUNTPOINT | ${pkgs.gnugrep}/bin/grep "$UUID_ATTUALE" | ${pkgs.gawk}/bin/awk '{print $2}')
        TARGET=$(echo "$TARGET" | ${pkgs.coreutils}/bin/tr -d '\n' | ${pkgs.coreutils}/bin/tr -d '\r')
        if [ -n "$TARGET" ] && ${pkgs.util-linux}/bin/mountpoint -q "$TARGET"; then break; fi
        sleep 2
        ATTESA=$((ATTESA + 2))
    done

    if [ -z "$TARGET" ] || ! ${pkgs.util-linux}/bin/mountpoint -q "$TARGET"; then
        invia_notifica "Backup annullato: disco non montato" "dialog-warning"
        exit 1
    fi

    case "$UUID_ATTUALE" in
        72e5*) NOME_DISCO="Disco A (500Gb)" ;;
        8476*) NOME_DISCO="Disco B (2Tb)" ;;
        6550*) NOME_DISCO="Disco C (500Gb)" ;;
        *)     NOME_DISCO="Disco Ignoto" ;;
    esac

    invia_notifica "Avvio backup su $NOME_DISCO..." "drive-harddisk"

    ${pkgs.coreutils}/bin/mkdir -p "$TARGET/backup_automatico"
    ${pkgs.coreutils}/bin/mkdir -p "$TARGET/Datasets_Archivio"
    ${pkgs.coreutils}/bin/mkdir -p "$TARGET/Modelli_Archivio"
    ${pkgs.coreutils}/bin/mkdir -p "$TARGET/noya_packs_Archivio"

    echo "4. Inizio Rsync Mirror..."
    ${pkgs.rsync}/bin/rsync -avS --delete \
        --exclude="target/" --exclude="node_modules/" --exclude=".cache/" \
        --exclude=".dbus/" --exclude=".local/share/Trash/" --exclude=".git/" \
        --exclude="*.lock" --exclude="HDD_Attivo" --exclude="backupHDD/" \
        --exclude="lost+found/" --exclude=".var/app/" --exclude=".aider" \
        --exclude="datasets/" --exclude="modelli/" --exclude=".mozilla/" \
        --exclude="noya_packs/" \
        "$SOURCE" "$TARGET/backup_automatico/"

    echo "4b. Archiviazione file pesanti (Accumulo)..."
    # ALTRI FIX DI ESCAPE: ''$ per evitare l'interpretazione di SOURCE come var Nix
    [ -d "''${SOURCE}datasets" ] && ${pkgs.rsync}/bin/rsync -avS "''${SOURCE}datasets/" "$TARGET/Datasets_Archivio/"
    [ -d "''${SOURCE}modelli" ] && ${pkgs.rsync}/bin/rsync -avS "''${SOURCE}modelli/" "$TARGET/Modelli_Archivio/"
    [ -d "''${SOURCE}noya_packs" ] && ${pkgs.rsync}/bin/rsync -avS "''${SOURCE}noya_packs/" "$TARGET/noya_packs_Archivio/"

    echo "5. Aggiornamento Link Simbolici..."
    ${pkgs.coreutils}/bin/ln -sfn "$TARGET/backup_automatico" /home/noya/HDD_Attivo
    ${pkgs.coreutils}/bin/ln -sfn "$TARGET/Datasets_Archivio" /home/noya/TUTTI_I_DATASETS
    ${pkgs.coreutils}/bin/ln -sfn "$TARGET/Modelli_Archivio" /home/noya/TUTTI_I_MODELLI
    ${pkgs.coreutils}/bin/ln -sfn "$TARGET/noya_packs_Archivio" /home/noya/TUTTI_I_PACKS

    invia_notifica "Backup e Archivi pronti su $NOME_DISCO!" "emblem-ok-symbolic"
  '';

  # 2. Script per il Monitoraggio della Batteria
  # Trasformato in un vero demone loop per evitare loop infiniti di systemd spawn
  batteryMonitor = pkgs.writeShellScriptBin "batteryMonitor" ''
    #!/bin/sh
    BATTERY_THRESHOLD=10
    BATTERY_PATH="/sys/class/power_supply/BAT0"

    if [ ! -d "$BATTERY_PATH" ]; then
        echo "Errore: Batteria non trovata in $BATTERY_PATH" >&2
        exit 1
    fi

    while true; do
        capacity=$(${pkgs.coreutils}/bin/cat "$BATTERY_PATH/capacity")
        status=$(${pkgs.coreutils}/bin/cat "$BATTERY_PATH/status")

        if [ "$capacity" -le "$BATTERY_THRESHOLD" ] && [ "$status" = "Discharging" ]; then
            ${pkgs.libnotify}/bin/notify-send -u critical \
                        -i battery-low \
                        "Porcamadonna la batteria è scarica" \
                        "Il livello della batteria è al $capacity%. Collega il caricabatterie."
        fi

        # Attendi 120 secondi prima del prossimo controllo passivo
        sleep 120
    done
  '';
in
{
  home.packages = [
    backupHDD
    batteryMonitor
  ];

  # Servizio di monitoraggio persistente
  systemd.user.services.battery-monitor = {
    Unit = {
      Description = "Script per il monitoraggio della batteria di Noya";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${batteryMonitor}/bin/batteryMonitor";
      Restart = "always";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
