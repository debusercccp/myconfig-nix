{ config, lib, pkgs, ... }:

let
  configHome = config.xdg.configHome;
  defaults = ./config/matugen/defaults;

  # File generati da matugen (vedi config/matugen/config.toml).
  # matugen deve poterli riscrivere, quindi NON sono symlink read-only verso lo
  # store: al primo switch vengono copiati dai default del repo, poi se ne
  # occupa `set-theme <wallpaper>`.
  matugenOutputs = {
    "niri/colors.kdl" = "${defaults}/niri/colors.kdl";
    "swaylock/config" = "${defaults}/swaylock/config";
    "conky/conky.conf" = "${defaults}/conky/conky.conf";
    "waybar/matugen.css" = "${defaults}/waybar/matugen.css";
    "fuzzel/matugen.ini" = "${defaults}/fuzzel/matugen.ini";
    "dunst/dunstrc.d/99-matugen.conf" = "${defaults}/dunst/99-matugen.conf";
    "nvim/lua/matugen_colors.lua" = "${defaults}/nvim/matugen_colors.lua";
  };
in
{
  home.packages = [ pkgs.matugen ];

  xdg.configFile."matugen/config.toml".source = ./config/matugen/config.toml;
  xdg.configFile."matugen/templates".source = ./config/matugen/templates;

  # Le generazioni precedenti linkavano waybar/, fuzzel/ e nvim/ come intere
  # directory nello store. Ora sono directory vere (recursive = true) perché
  # matugen ci scrive dentro: rimuoviamo i vecchi symlink prima del controllo
  # dei conflitti di home-manager.
  home.activation.removeOldConfigDirLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for d in waybar fuzzel nvim; do
      t="${configHome}/$d"
      if [ -L "$t" ] && [[ "$(readlink "$t")" == /nix/store/* ]]; then
        run rm "$t"
      fi
    done
  '';

  # Copia i default solo se il file manca o è ancora un vecchio symlink:
  # i colori generati da matugen sopravvivono ai rebuild.
  home.activation.seedMatugenOutputs = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.concatStrings (lib.mapAttrsToList (path: src: ''
      t="${configHome}/${path}"
      if [ ! -e "$t" ] || [ -L "$t" ]; then
        run mkdir -p "$(dirname "$t")"
        run rm -f "$t"
        run install -m 644 ${src} "$t"
      fi
    '') matugenOutputs)
  );
}
