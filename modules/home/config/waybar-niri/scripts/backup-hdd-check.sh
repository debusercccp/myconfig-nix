#!/usr/bin/env bash
# Verifica se HDD esterno è collegato

if [ -d "/media/backup" ] || [ -d "/mnt/backup" ]; then
  notify-send "Backup HDD" "HDD rilevato, puoi fare backup"
  echo "HDD trovato"
else
  notify-send "Backup HDD" "HDD non trovato" -u critical
  echo "HDD non trovato"
fi
