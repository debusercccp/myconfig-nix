{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Formatters
    prettier
    black
    rustfmt
    shfmt
    clang-tools
    stylua

    # Linters
    eslint
    python3Packages.pylint python3Packages.flake8 python3Packages.mypy
    shellcheck
    yamllint

    # Utilities
    ripgrep fd fzf bat eza
    httpie
    imagemagick ffmpeg
  ];
}
