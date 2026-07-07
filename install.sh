#!/usr/bin/env bash
#
# install.sh — Applica l'intero flake NixOS di questo repo (hostname: lynx).
#
# Uso:
#   ./install.sh [HOSTNAME] [AZIONE]
#
#   HOSTNAME   Attributo di nixosConfigurations da applicare (default: lynx)
#   AZIONE     switch | boot | test | build | dry-activate (default: switch)
#
# Esempi:
#   ./install.sh                 # nixos-rebuild switch --flake .#lynx
#   ./install.sh lynx test       # prova senza rendere persistente
#   ./install.sh lynx boot       # applica al prossimo avvio
#
set -euo pipefail

HOST="${1:-lynx}"
ACTION="${2:-switch}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Output colorato -------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'; C_BLUE=$'\033[1;34m'; C_YELLOW=$'\033[1;33m'; C_RED=$'\033[1;31m'; C_GREEN=$'\033[1;32m'
else
    C_RESET=''; C_BLUE=''; C_YELLOW=''; C_RED=''; C_GREEN=''
fi
info()  { printf '%s==>%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
warn()  { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
error() { printf '%s[x]%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
ok()    { printf '%s[✓]%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }

# --- Preflight -------------------------------------------------------------
if ! command -v nixos-rebuild >/dev/null 2>&1; then
    error "'nixos-rebuild' non trovato: questo script va eseguito su NixOS."
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/flake.nix" ]]; then
    error "flake.nix non trovato in $SCRIPT_DIR."
    exit 1
fi

info "Flake:    $SCRIPT_DIR"
info "Host:     $HOST"
info "Azione:   nixos-rebuild $ACTION"

# --- Abilita i flake se necessario -----------------------------------------
NIX_CONF="/etc/nix/nix.conf"
if ! grep -qs "experimental-features.*flakes" "$NIX_CONF"; then
    warn "Flake non abilitati in $NIX_CONF: li abilito ora (richiede sudo)."
    sudo mkdir -p /etc/nix
    echo "experimental-features = nix-command flakes" | sudo tee -a "$NIX_CONF" >/dev/null
    ok "Flake abilitati."
fi

# --- Avvisi (non bloccanti) ------------------------------------------------
# hardware-configuration.nix è specifico della macchina originale.
HW="$SCRIPT_DIR/hosts/desktop/hardware-configuration.nix"
if [[ -f "$HW" ]]; then
    warn "hosts/desktop/hardware-configuration.nix è specifico della macchina originale."
    warn "Su un PC diverso rigeneralo prima di procedere:"
    warn "    sudo nixos-generate-config --show-hardware-config > \"$HW\""
fi

# I flake usano l'albero git: le modifiche NON committate a file tracked passano
# (con warning), ma i file NON tracked sono invisibili alla valutazione.
if command -v git >/dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    if [[ -n "$(git -C "$SCRIPT_DIR" status --porcelain)" ]]; then
        warn "Ci sono modifiche git non committate: i file NON tracked non verranno"
        warn "inclusi nel build del flake. Fai 'git add' dei nuovi file se necessario."
    fi
else
    warn "$SCRIPT_DIR non è un repo git: i flake potrebbero non trovare i file attesi."
fi

# --- Hostname --------------------------------------------------------------
# Il flake dichiara già networking.hostName = "lynx"; impostarlo qui evita
# disallineamenti prima del primo rebuild ed è idempotente.
if command -v hostnamectl >/dev/null 2>&1 && [[ "$(hostname)" != "$HOST" ]]; then
    info "Imposto l'hostname a '$HOST' (richiede sudo)."
    sudo hostnamectl set-hostname "$HOST"
fi

# --- Rebuild ---------------------------------------------------------------
info "Avvio: sudo nixos-rebuild $ACTION --flake \"$SCRIPT_DIR#$HOST\""
sudo nixos-rebuild "$ACTION" --flake "$SCRIPT_DIR#$HOST"

ok "Configurazione '$HOST' applicata ($ACTION)."
