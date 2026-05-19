{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Questo file viene mantenuto così come generato dall'installer
  ];

  # --- ABILITAZIONE PARADIGMA MODERNO NIX ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # --- CONFIGURAZIONE BOOTLOADER & KERNEL ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Nota: Se in futuro vorrai compilare i tuoi kernel custom o applicare patch (es. Bore) 
  # potrai farlo dichiarativamente qui usando boot.kernelPackages.

  # --- RETE E LOCALIZZAZIONE ---
  networking.hostName = "lynx"; # Il tuo hostname originale
  networking.networkmanager.enable = true;
  
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";

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

  # --- AUTOMAZIONE UDEV PER PIPELINE BACKUP HDD ---
  # Questa regola intercetta l'inserimento di qualsiasi disco fisso esterno.
  # Se l'UUID corrisponde ai tuoi dischi, chiama l'unita systemd dell'utente "noya"
  # passando l'UUID rilevato da udev ($env{ID_FS_UUID}) come argomento.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_UUID}=="?*", RUN+="${pkgs.systemd}/bin/systemctl --user --machine=noya@.host start backupHDD@$env{ID_FS_UUID}.service"
  '';

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

  # --- AMBIENTE DI SICUREZZA ---
  # Abilitiamo le configurazioni minime per evitare vulnerabilità macroscopiche
  security.rtkit.enable = true; # Permette a Pipewire/Wireplumber di acquisire priorità in tempo reale

  system.stateVersion = "24.05"; # Mantiene la compatibilità con lo stato iniziale dell'installazione

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

