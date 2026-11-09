{ pkgs, ... }:

{
  # BLOCCO PACCHETTI UTENTE PULITO (Senza font duplicati)
  home.packages = with pkgs; [
    fuzzel
    awww              # Demone sfondo (sostituisce swaybg; usato da set-theme)
    qt6Packages.qt6ct # QT_QPA_PLATFORMTHEME=qt6ct (config.kdl)
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
    swayidle          # Gestione idle (blocco/spegnimento monitor)
    playerctl         # Controlli multimediali (XF86Audio Play/Pause/Next/Prev)
    xwayland-satellite # Server Xwayland on-demand (app X11 su :0)
    kdePackages.polkit-kde-agent-1 # Agente PolicyKit (prompt grafici auth)

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
  # niri/colors.kdl, waybar/matugen.css e fuzzel/matugen.ini sono generati da
  # matugen (theme.nix): le directory sono reali (recursive) e solo i file del
  # repo sono symlink, così matugen può scriverci accanto.
  xdg.configFile."niri/config.kdl".source = ./config/niri/config.kdl;
  xdg.configFile."waybar" = {
    source = ./config/waybar-niri;
    recursive = true;
  };
  xdg.configFile."fuzzel" = {
    source = ./config/fuzzel;
    recursive = true;
  };

  # --- GESTIONE STARTUP SERVIZI GRAFICI ---
  # Demone awww + ripristino dell'ultimo sfondo scelto con set-theme
  # (~/.cache/current_wallpaper), con fallback su flames.jpg.
  systemd.user.services.awww = {
    Unit = {
      Description = "awww Wallpaper Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      # Il prefisso "-" e il controllo del file: senza sfondo (es. VM) il demone resta attivo.
      ExecStartPost = "-${pkgs.bash}/bin/bash -c 'sleep 0.5; w=$(cat %h/.cache/current_wallpaper 2>/dev/null || echo /home/noya/Immagini/flames.jpg); [ -f \"$w\" ] && ${pkgs.awww}/bin/awww img \"$w\" --resize crop; exit 0'";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
