#!/usr/bin/env bash

STATE_FILE="/tmp/niri_nightlight_status"

is_running() {
    [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "on" ]
}

case "$1" in
    toggle)
        if is_running; then
            # RIPRISTINA COLORI NORMALI
            niri msg action set-output-color-transform eDP-1 "off"
            echo "off" > "$STATE_FILE"
        else
            # APPLICA LUCE CALDA
            niri msg action set-output-color-transform eDP-1 "temperature=3500"
            echo "on" > "$STATE_FILE"
        fi
        ;;
    status)
        if is_running; then
            echo '{"text": "󰛑", "class": "on", "tooltip": "Filtro Attivo\nTemperatura: 3500K"}'
        else
            echo '{"text": "󰛨", "class": "off", "tooltip": "Filtro Disattivato"}'
        fi
        ;;
esac
