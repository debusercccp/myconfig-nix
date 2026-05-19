{ pkgs, ... }:

{
  home.packages = [ pkgs.dunst ];

  # Mappiamo il file dunstrc
  xdg.configFile."dunst/dunstrc".source = ./config/dunst/dunstrc;
}
