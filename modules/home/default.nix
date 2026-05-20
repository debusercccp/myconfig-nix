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
    ./formatters.nix
    ./starship.nix
    ./precommit.nix
  ];
  home.packages = with pkgs; [
    git
    jq
    libnotify
    acpi
    rsync
  ];
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
}
