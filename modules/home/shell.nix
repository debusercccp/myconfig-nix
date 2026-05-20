{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      activate = "source .venv/bin/activate";
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#lynx";
      nix-clean = "sudo nix-env --delete-generations old && nix-store --gc";
      cestino = "rm -rf ~/.local/share/Trash/*";
    };
    sessionVariables = {
      GH_TOKEN = "suca";
    };
    bashrcExtra = ''
      export PATH="''${HOME}/.cargo/bin:''${PATH}"
      export PATH="''${HOME}/.local/bin:''${PATH}"
      export NVM_DIR="''${HOME}/.nvm"
      [ -s "''${NVM_DIR}/nvm.sh" ] && \. "''${NVM_DIR}/nvm.sh"
      [ -s "''${NVM_DIR}/bash_completion" ] && \. "''${NVM_DIR}/bash_completion"
      [ -f "''${HOME}/.cargo/env" ] && . "''${HOME}/.cargo/env"

      eval "$(${pkgs.starship}/bin/starship init bash)"
    '';
  };
}
