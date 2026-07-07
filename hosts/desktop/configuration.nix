{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Questo file viene mantenuto così come generato dall'installer
  ];

  # Abilita il supporto Bluetooth hardware
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; # Accendi al boot

  # Abilita il demone Blueman (necessario per blueman-manager)
  services.blueman.enable = true;

  # --- ABILITAZIONE PARADIGMA MODERNO NIX ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- CONFIGURAZIONE BOOTLOADER & KERNEL ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Nota: Se in futuro vorrai compilare i tuoi kernel custom o applicare patch (es. Bore)
  # potrai farlo dichiarativamente qui usando boot.kernelPackages.

  # Abilita il demone per il montaggio automatico dei dischi (richiesto da udisksctl)
  services.udisks2.enable = true;

  # Abilita la geolocalizzazione di sistema
  services.geoclue2 = {
    enable = true;
    # Whitelist per consentire a Gammastep di leggere la posizione
    appConfig = {
      "gammastep" = {
        isAllowed = true;
        isSystem = false;
      };
    };
  };

  # Supporto per i file system più comuni sui dischi esterni
  boot.supportedFilesystems = [ "ntfs" "vfat" "exfat" "ext4" ];

  # --- RETE E LOCALIZZAZIONE ---
  networking.hostName = "lynx"; # Il tuo hostname originale
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Variabile per app Electron/Chromium su Wayland (Ozone)
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Configurazione universale della tastiera (Sistema, TTY e Wayland)
  services.xserver.xkb = {
    layout = "gb"; # "gb" è il codice ISO corretto per il layout UK (Regno Unito)
    variant = "";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "uk"; # Mantiene la TTY testuale in UK
  };

  # --- AMBIENTE UTENTE E PERMESSI ---
  users.users.noya = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "kvm" ];
    shell = pkgs.bash;
    packages = with pkgs; [ thunderbird ];
  };

  # --- INTERFACCIA GRAFICA & COMPOSITOR ---
  # Abilitiamo Niri a livello di sistema operativo per configurare correttamente
  # i canali grafici, i permessi Wayland e le sessioni di sistema.
  programs.niri.enable = true;

  # Un Display Manager minimale basato su TUI (coerente col tuo setup leggero)
  services.displayManager.ly.enable = true;

  # --- STRUMENTI DI MONITORAGGIO HARDWARE & AUDIO ---
  services.upower.enable = true; # Ottimizza la lettura dello stato energetico per Waybar/Battery
  security.polkit.enable = true; # Necessario per l'elevazione dei privilegi nelle sessioni Wayland

  # Audio via PipeWire (rimpiazza PulseAudio). Necessario per wpctl/wireplumber
  # usati dai keybind di niri e dal modulo pulseaudio di Waybar.
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # --- AUTOMAZIONE UDEV PER PIPELINE BACKUP HDD ---
  # All'inserimento di uno dei dischi di backup noti (match per UUID), udev attiva
  # il servizio di sistema template backup-hdd@<UUID>.service (device activation via
  # SYSTEMD_WANTS), che esegue backup_hdd.sh come utente noya. Regola extra:
  # l'adattatore SATA-USB JMicron JMS578 è escluso dall'autosuspend USB
  # (mitigazione dei distacchi HDD).
  services.udev.extraRules = ''
    # Adattatore SATA-USB JMicron JMS578: niente autosuspend (mitigazione distacchi HDD)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="152d", ATTR{idProduct}=="0578", TEST=="power/control", ATTR{power/control}="on"

    # Disco A (2 TB, 8476…)
    ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_FS_UUID}=="84763b78-b0dc-4593-ba3b-cebc88d54dda", TAG+="systemd", ENV{SYSTEMD_WANTS}="backup-hdd@84763b78-b0dc-4593-ba3b-cebc88d54dda.service"

    # Disco B (500 GB, 6550…)
    ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_FS_UUID}=="65505cfd-073a-4f4c-8f8f-cbbec134f2aa", TAG+="systemd", ENV{SYSTEMD_WANTS}="backup-hdd@65505cfd-073a-4f4c-8f8f-cbbec134f2aa.service"

    # Disco C (WD 500 GB, d8c9…)
    ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="partition", ENV{ID_FS_UUID}=="d8c9f8b2-d093-4751-a5c9-469c49361fb4", TAG+="systemd", ENV{SYSTEMD_WANTS}="backup-hdd@d8c9f8b2-d093-4751-a5c9-469c49361fb4.service"
  '';

  # Servizio template della pipeline di backup: eseguito come noya con priorità I/O
  # bassa (ionice best-effort classe 2, livello 7). L'istanza %i è l'UUID passato da
  # udev. `path` fornisce tutti i comandi usati da backup_hdd.sh; lo script è preso
  # verbatim dallo store Nix (sync da myconfig/backupHDD/backup_hdd.sh).
  systemd.services."backup-hdd@" = {
    description = "Pipeline Backup HDD USB";
    path = with pkgs; [
      bash
      coreutils
      util-linux
      gawk
      gnugrep
      procps
      rsync
      libnotify
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "noya";
      ExecStart = "${pkgs.util-linux}/bin/ionice -c 2 -n 7 ${pkgs.bash}/bin/bash ${./backup_hdd.sh} %i";
    };
  };

  # --- GESTIONE DEI FONT DI SISTEMA ---
  fonts.packages = with pkgs; [
    nerd-fonts.shure-tech-mono
    nerd-fonts.jetbrains-mono
  ];

  # --- PACCHETTI DI SISTEMA GLOBALI (Cyber Jail & Toolchain) ---
  environment.systemPackages = with pkgs; [
    # Toolchain di base per Neovim (compilazione plugin come Treesitter)
    gcc
    gnumake
    unzip
    wget
    curl
    git
    firefox
    fastfetch
    git
    curl
    cargo

    util-linux
    acpi
    libnotify
    rsync
    pmutils
    htop
    nmap
    tree

    # Sicurezza ed esperimenti in chroot / jail isolati
    bubblewrap # Strumento moderno e sicuro per creare jail isolate su NixOS senza manipolare i mount di root
    coreutils
  ];

  # --- SERVIZI & PROGRAMMI DI SISTEMA ---
  # Portali XDG per Wayland (screencast, file chooser). niri riavvia
  # xdg-desktop-portal-gtk all'avvio, quindi includiamo sia gnome che gtk.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # Firefox gestito a livello di sistema (oltre al binario nei systemPackages)
  programs.firefox.enable = true;

  # nix-ld: permette di eseguire binari dinamici non-Nix (toolchain esterne, ecc.)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    nspr nss glib gtk3 atk at-spi2-atk cairo pango gdk-pixbuf
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXi xorg.libXrandr xorg.libXrender
    xorg.libXtst xorg.libXScrnSaver alsa-lib mesa expat dbus
    libdrm libxkbcommon systemd
  ];

  # Agente GnuPG con supporto SSH
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Stampa (CUPS) e accesso remoto SSH
  services.printing.enable = true;
  services.openssh.enable = true;

  # Porte aperte (es. Ollama 11434, dev server 3000/8080)
  networking.firewall.allowedTCPPorts = [ 11434 3000 8080 ];

  # --- AMBIENTE DI SICUREZZA ---
  # Abilitiamo le configurazioni minime per evitare vulnerabilità macroscopiche
  security.rtkit.enable = true; # Permette a Pipewire/Wireplumber di acquisire priorità in tempo reale

  system.stateVersion = "24.05"; # Mantiene la compatibilità con lo stato iniziale dell'installazione

  # Consenti pacchetti unfree (es. driver, alcune app)
  nixpkgs.config.allowUnfree = true;

    # --- OTTIMIZZAZIONE E PULIZIA AUTOMATICA DEL SISTEMA ---
  nix.settings.auto-optimise-store = true; # Rileva i file duplicati e crea hardlink per risparmiare spazio

  nix.gc = {
    automatic = true;
    dates = "weekly";            # Esegue la pulizia ogni settimana
    options = "--delete-older-than 14d"; # Pialla automaticamente tutto ciò che è più vecchio di due settimane
  };

  # Opzionale: Limita il numero massimo di configurazioni visualizzate nel menu di boot
  boot.loader.systemd-boot.configurationLimit = 10; # Mostra al massimo le ultime 10 generazioni
}
