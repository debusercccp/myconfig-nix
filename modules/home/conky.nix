{ ... }:

{
  # Il pacchetto conky è installato in niri.nix (richiesto dallo spawn-at-startup).
  # Qui mappiamo solo il file di configurazione su ~/.config/conky/conky.conf,
  # percorso usato da niri: "conky -c ~/.config/conky/conky.conf".
  xdg.configFile."conky/conky.conf".source = ./config/conky/conky.conf;
}
