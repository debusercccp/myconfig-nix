#!/usr/bin/env bash
# Script per Waybar: Gestione dischi rimovibili (NixOS / Debian)

ICON_HDD="󰋊"

notify() {
    notify-send -u "$1" -t 3000 "USB Tool" "$2"
}

get_removable_devices() {
    lsblk -dno NAME,RM,TRAN | awk '$2=="1" || $3=="usb" {print "/dev/"$1}'
}

is_mounted() {
    if lsblk -rpo MOUNTPOINT "$1" | grep -q /; then echo "true"; else echo "false"; fi
}

toggle_device() {
    local dev=$(get_removable_devices | head -1)
    if [ -z "$dev" ]; then
        notify "critical" "Nessun disco USB trovato"
        exit 1
    fi

    sync

    if [ "$(is_mounted "$dev")" = "true" ]; then
        local partitions=$(lsblk -rpo NAME,TYPE,MOUNTPOINT "$dev" | awk '$2=="part" && $3!="" {print $1}')

        for part in $partitions; do
            udisksctl unmount -b "$part" &> /dev/null || { notify "critical" "Errore: Disco occupato!"; exit 1; }
        done

        udisksctl power-off -b "$dev" &> /dev/null
        notify "normal" "Disco rimosso in sicurezza"
    else
        local part=$(lsblk -rpo NAME,TYPE "$dev" | awk '$2=="part" {print $1}' | head -1)
        if [ -n "$part" ]; then
            udisksctl mount -b "$part" &> /dev/null && notify "normal" "Disco montato con successo 󰋊"
        else
            notify "critical" "Errore: Nessuna partizione trovata"
        fi
    fi
}

waybar_output() {
    local dev=$(get_removable_devices | head -1)

    if [ -z "$dev" ]; then
        echo "{\"text\": \"$ICON_HDD\", \"class\": \"empty\", \"tooltip\": \"Nessun dispositivo USB\"}"
    else
        if [ "$(is_mounted "$dev")" = "true" ]; then
            echo "{\"text\": \"$ICON_HDD USB\", \"class\": \"mounted\", \"tooltip\": \"Montato: $dev\"}"
        else
            echo "{\"text\": \"$ICON_HDD USB\", \"class\": \"unmounted\", \"tooltip\": \"Rilevato: $dev\nClick per montare\"}"
        fi
    fi
}

case "$1" in
    waybar) waybar_output ;;
    toggle) toggle_device ;;
    *) echo "Usa waybar o toggle" ;;
esac
