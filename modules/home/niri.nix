{ pkgs, ... }:

{
  # BLOCCO PACCHETTI UTENTE PULITO (Senza font duplicati)
  home.packages = with pkgs; [
    fuzzel
    swaybg
    brightnessctl
    wireplumber
    kdePackages.dolphin

    # Strumenti richiesti dagli spawn-at-startup / keybind di niri
    cliphist          # Storia degli appunti (Mod+A)
    wl-clipboard      # wl-paste / wl-copy
    grim              # Screenshot (Print)
    slurp             # Selezione area per grim
    swaylock          # Blocco schermo (Mod+L)
    galculator        # Calcolatrice (XF86Calculator)
    conky             # Widget desktop di sistema

    pyright
    nodejs
    rust-analyzer
    clang-tools
    lua-language-server
  ];

  # Abilitiamo Waybar e Dunst come servizi utente Systemd
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  services.dunst = {
    enable = true;
  };

  # --- MAPPATURA DIRECTORY DOTFILES ---
  xdg.configFile."niri/config.kdl".source = ./config/niri/config.kdl;
  xdg.configFile."niri/colors.kdl".source = ./config/niri/colors.kdl;
  xdg.configFile."waybar".source = ./config/waybar-niri;
  xdg.configFile."fuzzel".source = ./config/fuzzel;

  # --- GESTIONE STARTUP SERVIZI GRAFICI ---
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Swaybg Wallpaper Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i /home/noya/Immagini/blacklodge.jpg -m fill";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
