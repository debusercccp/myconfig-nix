{ pkgs, ... }:

{
  programs.bash = {
    enable = true;

    # Gestione avanzata della cronologia
    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;

    # Opzioni native della shell
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];

    # --- GLI ALIAS DI ENTRABI I VECCHI FILE ---
    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";

      # Sviluppo (Python venv & Aider/Ollama)
      activate = "source .venv/bin/activate";
      
      # Manutenzione NixOS (Sostituiscono Apt)
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#lynx";
      nix-clean = "sudo nix-env --delete-generations old && nix-store --gc";
      cestino = "rm -rf ~/.local/share/Trash/*";

      # Script personali
      backup-ssd = "/home/noya/backupMiniSSD/backup_to_minissd.sh";
    };

    # --- VARIABILI D'AMBIENTE INTERACTIVE ---
    sessionVariables = {
      GH_TOKEN = "suca";
    };

    # --- PROMPT DINAMICO & AMBIENTI ESTERNI (FIXED BASHRC EXTRA) ---
    bashrcExtra = ''
      # Path locali per Cargo e script binari utente
      export PATH="''${HOME}/.cargo/bin:''${PATH}"
      export PATH="''${HOME}/.local/bin:''${PATH}"

      # Caricamento Node Version Manager (NVM) manuale
      export NVM_DIR="''${HOME}/.nvm"
      [ -s "''${NVM_DIR}/nvm.sh" ] && \. "''${NVM_DIR}/nvm.sh"
      [ -s "''${NVM_DIR}/bash_completion" ] && \. "''${NVM_DIR}/bash_completion"

      # Configurazione dell'ambiente Rust / Cargo
      [ -f "''${HOME}/.cargo/env" ] && . "''${HOME}/.cargo/env"

      # Funzione Pura Bash per estrarre il ramo Git corrente
      parse_git_branch() {
          git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
      }

      # Il tuo Prompt Custom: [Orario] noya@lynx [Path] (ramo_git) -->
      export PS1='\[\033[35m\]\t \[\033[37m\]\u\[\033[38;5;213m\]@\h \[\033[33m\]\w\[\033[1;36m\]$(parse_git_branch)\[\033[0m\] '
    ''; 
    };
}
