{ ... }:

{
  # Il pacchetto swaylock è installato in niri.nix (keybind Mod+L).
  # swaylock legge ~/.config/swaylock/config automaticamente.
  xdg.configFile."swaylock/config".source = ./config/swaylock/config;
}
