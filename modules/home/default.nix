{ pkgs, ... }:

{
  home.username = "noya";
  home.homeDirectory = "/home/noya";

  imports = [
    ./niri.nix
    ./nvim.nix
    ./kitty.nix
    ./dunst.nix
    ./scripts.nix
    ./shell.nix
  ];

  # Pacchetti generali richiesti dalle tue utility
  home.packages = with pkgs; [
    git
    jq
    libnotify # Richiesto da batteryMonitor e dunst
    acpi      # Richiesto per controllare lo stato della batteria
    rsync     # Consigliato per gli script di backup
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
}
