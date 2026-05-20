# Da aggiungere al flake.nix, nella sezione outputs dopo nixosConfigurations
# Uso: nix flake develop --impure
# In ogni devShell arai lo strumento isolato dal sistema

devShells.${system} = {
  # Default shell: Rust + Python + Node + C/C++
  default = pkgs.mkShell {
    name = "dev-default";
    buildInputs = with pkgs; [
      # Rust ecosystem
      rust rustfmt clippy cargo
      
      # Python ecosystem
      python3 python3Packages.pip python3Packages.virtualenv
      
      # Node/JS ecosystem
      nodejs nodePackages.npm nodePackages.yarn
      
      # C/C++
      gcc clang lldb cmake make
      
      # Utils generali
      git jq vim tmux
    ];
    shellHook = ''
      echo "🚀 Dev shell loaded: Rust, Python, Node, C/C++"
      rustc --version
      python3 --version
      node --version
    '';
  };

  # Rust-only shell
  rust = pkgs.mkShell {
    name = "dev-rust";
    buildInputs = with pkgs; [
      rust rustfmt clippy cargo
      lldb
      pkg-config
    ];
    shellHook = ''
      echo "🦀 Rust dev shell"
      rustc --version
    '';
  };

  # Python-only shell
  python = pkgs.mkShell {
    name = "dev-python";
    buildInputs = with pkgs; [
      python3 python3Packages.pip python3Packages.virtualenv
      python3Packages.black python3Packages.flake8 python3Packages.mypy
    ];
    shellHook = ''
      echo "🐍 Python dev shell"
      python3 --version
      # Auto-create venv se non esiste
      if [ ! -d venv ]; then
        python3 -m venv venv
      fi
      source venv/bin/activate
    '';
  };

  # Bioinformatics shell (con strumenti specifici)
  bioinf = pkgs.mkShell {
    name = "dev-bioinf";
    buildInputs = with pkgs; [
      python3 python3Packages.pip python3Packages.virtualenv
      # Bioinformatics tools
      biopython emboss samtools bcftools vcftools
    ];
    shellHook = ''
      echo "🧬 Bioinformatics dev shell"
    '';
  };

  # Node/JS shell
  node = pkgs.mkShell {
    name = "dev-node";
    buildInputs = with pkgs; [
      nodejs nodePackages.npm nodePackages.yarn
    ];
    shellHook = ''
      echo "🟢 Node dev shell"
      node --version && npm --version
    '';
  };
};
