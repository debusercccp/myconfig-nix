{ pkgs, ... }:

{
  # BLOCCO PACCHETTI UTENTE PULITO (Senza font duplicati)
  home.packages = with pkgs; [
    fuzzel
    swaybg
    brightnessctl
    wireplumber
    kdePackages.dolphin
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
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i /home/noya/Pictures/pixel.png -m fill";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
