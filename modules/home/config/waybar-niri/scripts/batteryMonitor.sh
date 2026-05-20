#!/usr/bin/env bash
# Monitora la batteria principale e avvisa se < 20%

while true; do
  # Estrae solo i numeri prima del simbolo % e prende rigorosamente il primo intero isolato
  battery=$(acpi -b | grep -oP '\d+(?=%)' | awk '{print $1; exit}')

  if [ -n "$battery" ]; then
    if [ "$battery" -lt 20 ]; then
      notify-send "Batteria Bassa" "Carica: $battery%"
    fi
  fi

  sleep 60
done
