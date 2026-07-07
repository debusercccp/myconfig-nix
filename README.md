# myconfig-nix

Configurazione NixOS declarativa e fully reproducible con Home Manager, dotfiles, e development environment isolati.

## Architettura

```
myconfig-nix/
├── flake.nix                          # Punto d'ingresso Flake
├── .pre-commit-config.yaml            # Git hooks automatici
├── hosts/
│   └── desktop/
│       ├── configuration.nix          # Configurazione NixOS globale
│       └── hardware-configuration.nix # Hardware (generato da nixos-generate-config)
└── modules/
    └── home/
        ├── default.nix                # Home Manager entry point
        ├── shell.nix                  # Bash + Starship
        ├── nvim.nix                   # Neovim + LSP dichiarativo
        ├── niri.nix                   # Niri Wayland compositor
        ├── kitty.nix                  # Kitty terminal
        ├── dunst.nix                  # Notifiche
        ├── scripts.nix                # Utility scripts
        ├── formatters.nix             # prettier, black, rustfmt, stylua, etc.
        ├── starship.nix               # Prompt custom
        ├── precommit.nix              # Pre-commit framework
        └── config/
            ├── niri/                  # File di config KDL
            ├── nvim/                  # init.lua, lazy-lock.json
            ├── kitty/                 # kitty.conf
            ├── waybar-niri/           # Waybar config + script
            ├── dunst/                 # dunstrc
            └── fuzzel/                # Launcher config
```

---

## Installazione su NixOS

### Prerequisiti

- NixOS già installato
- Git

### Setup

> **Scorciatoia**: dopo aver clonato il repo puoi eseguire `./install.sh` (abilita i
> flake, imposta l'hostname `lynx` e lancia `nixos-rebuild switch --flake .#lynx`).
> Uso: `./install.sh [HOSTNAME] [AZIONE]` (default `lynx switch`). I passi manuali
> equivalenti sono qui sotto.

```bash
# 1. Clona il repo nella posizione corretta
sudo mkdir -p /etc/nixos
cd /etc/nixos
sudo git clone https://github.com/debusercccp/myconfig-nix.git .

# 2. Verifica l'hostname
hostname
# Deve essere "lynx" (configurato in hosts/desktop/configuration.nix)
# Se diverso, modifica configuration.nix o cambia hostname:
sudo hostnamectl set-hostname lynx

# 3. Abilita Flakes (se non abilitato)
sudo mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf

# 4. Applica la configurazione
sudo nixos-rebuild switch --flake .#lynx

# 5. Ricarica la shell
exec $SHELL
```

### Primo avvio

```bash
# Dev shells disponibili
nix develop --impure                 # Default (Rust, Python, Node, C/C++)
nix develop --impure .#rust          # Solo Rust
nix develop --impure .#python        # Solo Python
nix develop --impure .#node          # Solo Node

# Formatter globali disponibili
which prettier black rustfmt shfmt stylua eslint shellcheck yamllint

# Pre-commit hooks
init-precommit    # Inizializza nel repo corrente
```

---

## Installazione su Debian (Home Manager Standalone)

### Prerequisiti

- Debian/Ubuntu
- Nix installato

### Setup

```bash
# 1. Installa Nix (se non presente)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Abilita Flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# 3. Ricarica la shell
exec $SHELL

# 4. Clona il repo
git clone https://github.com/debusercccp/myconfig-nix.git ~/myconfig-nix
cd ~/myconfig-nix

# 5. Applica la configurazione
home-manager switch --flake .#noya@orion

# 6. Ricarica la shell
exec $SHELL
```

### Note Debian

Su Debian **non** si applica la configurazione di sistema (kernel, bootloader, etc.). Solo i dotfiles dell'utente vengono configurati.

Layout tastiera, pacchetti di sistema, e altri setting globali vanno configurati manualmente:

```bash
# Esempio: layout tastiera GB
sudo localectl set-keymap gb

# Pacchetti di sistema
sudo apt install git curl ripgrep fd-find fzf bat
```

---

## Feature

### 1. Dev Shells (Ambienti Isolati)

Ogni progetto può usare un dev shell isolato senza inquinare il sistema globale.

```bash
# Rust environment
nix develop --impure .#rust
rustc --version
cargo build
exit

# Python environment
nix develop --impure .#python
python3 -m venv venv
source venv/bin/activate
pip install numpy pandas
exit

# Default (tutto insieme)
nix develop --impure
```

**Vantaggi:**
- Versioni tools isolate per progetto
- No conflitti globali
- Reproducibile su tutte le macchine
- Cleanup automatico (exit)

---

### 2. Formatters Dichiarativi

Tutti i formatter sono installati globalmente e dichiarativi in `modules/home/formatters.nix`.

Disponibili:
- **Python**: `black`, `pylint`, `flake8`, `mypy`
- **Rust**: `rustfmt`, `clippy`
- **JavaScript/TypeScript**: `prettier`, `eslint`
- **Shell**: `shfmt`, `shellcheck`
- **YAML**: `yamllint`
- **Lua**: `stylua`
- **C/C++**: `clang-tools`

Uso manuale:

```bash
black myfile.py
rustfmt main.rs
prettier --write app.js
shfmt -i 2 -w script.sh
```

Integrazione Neovim (in `init.lua`):

```lua
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    python = { "black" },
    rust = { "rustfmt" },
    javascript = { "prettier" },
    bash = { "shfmt" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})
```

Poi in Neovim: `:Format` o auto-save su `:w`.

---

### 3. Starship Prompt

Prompt dichiarativo e performante, senza conflitti Nix.

**Visualizzazione:**
```
noya@lynx ~/myconfig-nix [git:master] >
```

Colori:
- Username: **bold purple**
- Hostname: **bold white**
- Directory: **bold yellow**
- Git branch: **bold cyan**

Configurazione: `modules/home/starship.nix`

Personalizzazione:

```nix
username.style_user = "bold purple";
hostname.style = "bold white";
directory.style = "bold yellow";
git_branch.style = "bold cyan";
```

---

### 4. Pre-commit Framework

Git hooks automatici che bloccano commit se il codice non passa i check.

**Configurazione:** `.pre-commit-config.yaml`

**Hooks attivi:**
- Black (Python formatting)
- Pre-commit-hooks (trailing whitespace, end-of-file, YAML, JSON checks)
- Shellcheck
- Prettier

**Uso:**

```bash
# Inizializza nel repo
init-precommit

# Adesso ogni commit è validato
git add myfile.py
git commit -m "fix: my changes"
# Se black fallisce, il file viene riformattato e devi rifare git add + commit

# Bypass (se necessario)
git commit --no-verify
```

---

### 5. Neovim + LSP Dichiarativo

Gli LSP sono iniettati da Nix, non da Mason (che crasherebbe su NixOS).

LSP disponibili (in `nvim.nix`):
- `pyright` (Python)
- `rust_analyzer` (Rust)
- `clangd` (C/C++)
- `lua_ls` (Lua)

Integrazione automatica in `init.lua` tramite lspconfig.

---

### 6. Niri Wayland Compositor

Wayland compositor moderno con keybinding e layout configurabili.

Configurazione: `modules/home/config/niri/config.kdl`

```kdl
layout "dwindle" {
    fixedwidth false
    default-column-width { proportion 0.5; }
}

binds {
    Mod+Shift+E { close-window; }
    Mod+Return { spawn "kitty"; }
    Mod+D { spawn "fuzzel"; }
}
```

---

### 7. Utilities & Scripts

Script personalizzati salvati in `~/.local/bin`:

- `nix-switch` - Rebuild NixOS
- `nix-clean` - Garbage collection
- `init-precommit` - Inizializza pre-commit nel repo
- `backup-ssd` - Script backup custom

### 8. Pipeline Backup HDD (device-activated)

Backup automatico su HDD/USB esterno, dichiarato interamente in
`hosts/desktop/configuration.nix` (nessuna installazione manuale in `/usr/local/bin`):

- **Trigger udev**: all'inserimento di uno dei dischi noti (match per UUID) udev
  attiva `backup-hdd@<UUID>.service` via `SYSTEMD_WANTS` (device activation).
- **Servizio di sistema** `backup-hdd@.service`: esegue `backup_hdd.sh <UUID>` come
  utente `noya`, con `ionice` best-effort (classe 2, livello 7). Lo script è preso
  verbatim dallo store Nix (`hosts/desktop/backup_hdd.sh`, sync da
  `myconfig/backupHDD/backup_hdd.sh`); il `PATH` del servizio fornisce rsync,
  util-linux, libnotify, ecc.
- **Cosa fa lo script**: mirror della home su `backup_automatico/` (rsync
  `--delete`), archiviazione incrementale di datasets/modelli/noya_packs, link
  simbolici di comodo nella home, `sync -f` finale e notifica desktop.
- **Adattatore JMicron JMS578** (`152d:0578`): escluso dall'autosuspend USB via
  regola udev, per mitigare i distacchi dell'HDD durante il backup.
- **Barra di avanzamento in Waybar**: `backup_hdd.sh` scrive il progresso in
  `/tmp/backup_hdd_progress`(+`.fase`); il modulo `custom/backup` lo legge con
  `scripts/backup-status.sh` mostrando percentuale e barra `█░` nel tooltip.

Per aggiungere un nuovo disco: aggiungi una regola udev con il suo UUID in
`configuration.nix` (l'aggiunta di un case in `backup_hdd.sh` serve solo per il
nome mostrato nelle notifiche).

Comandi utili:

```bash
# Avvio manuale (sostituisci l'UUID)
sudo systemctl start backup-hdd@84763b78-b0dc-4593-ba3b-cebc88d54dda.service
# Log del servizio
journalctl -u "backup-hdd@*" -f
# Log di debug dello script
cat /tmp/pipeline_debug.log
```

#### Note

- **Build-check da fare sulla macchina NixOS**: questa pipeline non è stata
  verificata con `nix`/`nixos-rebuild` (non disponibili nell'ambiente in cui è stata
  scritta). Applica e testa con:

  ```bash
  sudo nixos-rebuild switch --flake ~/dotfiles/myconfig-nix#lynx
  # test manuale:
  sudo systemctl start backup-hdd@84763b78-b0dc-4593-ba3b-cebc88d54dda.service
  journalctl -u "backup-hdd@*" -f
  ```

- **`notify-send` richiede la sessione utente attiva (D-Bus)**: lo script imposta da
  sé `DBUS_SESSION_BUS_ADDRESS=/run/user/1000/bus`, identico a `myconfig`. Il backup
  rsync funziona comunque anche senza sessione grafica attiva; solo le notifiche
  desktop no.

---

## Aggiornamenti

### Aggiorna nixpkgs

```bash
cd /etc/nixos  # (NixOS) o ~/myconfig-nix (Debian)
nix flake update
sudo nixos-rebuild switch --flake .#lynx  # NixOS
# o
home-manager switch --flake .#noya@debian  # Debian
```

### Aggiungi nuovo pacchetto

Modifica il modulo appropriato:

```nix
# Globale (NixOS)
# hosts/desktop/configuration.nix
environment.systemPackages = with pkgs; [
  ripgrep
  fd
];

# User-level
# modules/home/default.nix
home.packages = with pkgs; [
  git
  jq
];
```

Applica:

```bash
sudo nixos-rebuild switch --flake .#lynx
```

---

## Troubleshooting

**Dev shell esce subito:**
```bash
nix flake update
nix develop --impure --show-trace
```

**Starship non appare:**
```bash
grep "starship init" ~/.bashrc
# Se non c'è:
eval "$(starship init bash)"
exec $SHELL
```

**Pre-commit non parte:**
```bash
rm -rf .git/hooks/pre-commit
init-precommit
```

**Formatter non trovato:**
```bash
which prettier
nix shell nixpkgs#prettier
which prettier
```

**Niri non si avvia:**
```bash
niri --version
niri  # Avvia manualmente
```

---

## Struttura dei Moduli

Ogni modulo in `modules/home/` è indipendente:

- **shell.nix** - Bash configurazione, alias, variabili
- **nvim.nix** - Neovim + lazy.nvim + LSP
- **niri.nix** - Niri compositor + swaybg
- **kitty.nix** - Kitty terminal
- **dunst.nix** - Notifiche
- **formatters.nix** - Formatter tools
- **starship.nix** - Prompt
- **precommit.nix** - Pre-commit hooks
- **scripts.nix** - Utility script

Ogni modulo è abilitabile/disabilitabile in `modules/home/default.nix`:

```nix
imports = [
  ./shell.nix       # Abilita
  # ./tmux.nix      # Disabilita (commentato)
  ./nvim.nix
];
```

---

## Git Workflow

```bash
# Modifica un file
echo 'console.log("test")' > app.js

# Aggiungi
git add app.js

# Commit (pre-commit hooks girano automaticamente)
git commit -m "feat: add console log"
# Se prettier fallisce, il file viene riformattato
# Rifare: git add app.js && git commit -m "..."

# Push
git push origin master
```

---

## Support

Per bug, feature request, o domande:

```bash
# Apri un issue su GitHub
# https://github.com/debusercccp/myconfig-nix/issues

# Oppure modifica e proponi un PR
git checkout -b feature/my-feature
# ... modifche ...
git push origin feature/my-feature
```

---

## License

MIT - Vedi LICENSE per dettagli.
