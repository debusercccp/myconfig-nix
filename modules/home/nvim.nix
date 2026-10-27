{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
      ripgrep
      fd
    ];
  };

  # Mappatura ricorsiva della tua directory nativa di Neovim.
  # recursive: nvim/lua/matugen_colors.lua è scritto da matugen (theme.nix).
  xdg.configFile."nvim" = {
    source = ./config/nvim;
    recursive = true;
  };
}
