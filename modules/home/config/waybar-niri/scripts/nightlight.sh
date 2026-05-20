#!/usr/bin/env bash
# Script per Waybar: Controllo dinamico di Gammastep + GeoClue2 via Systemd

is_running() {
    # Controlla se il servizio di Home Manager è attivo
    systemctl --user is-active gammastep.service > /dev/null
}

case "$1" in
    toggle)
        if is_running; then
            # Spegne il servizio
            systemctl --user stop gammastep.service
        else
            # Avvia il servizio (che interrogherà GeoClue2 in base a dove ti trovi)
            systemctl --user start gammastep.service
        fi
        ;;
    status)
        if is_running; then
            echo '{"text": "󰛑", "class": "on", "tooltip": "Luce Notturna: ATTIVA\nPosizione: Dinamica (GeoClue2)"}'
        else
            echo '{"text": "󰛨", "class": "off", "tooltip": "Luce Notturna: DISATTIVATA\nClick per attivare"}'
        fi
        ;;
esac
