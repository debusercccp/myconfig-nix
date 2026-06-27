#!/usr/bin/env python3
"""Menu WiFi con fuzzel per waybar – usa nmcli (NetworkManager)."""

import re
import subprocess
import sys


def nm(*args):
    return subprocess.run(["nmcli"] + list(args), capture_output=True, text=True)


def notify(msg):
    subprocess.run(["notify-send", "Wi-Fi", msg], check=False)


def _split(line):
    """Divide output nmcli -t su ':' non preceduti da '\\' (escape NM)."""
    return re.split(r"(?<!\\):", line)


def _unescape(s):
    return s.replace(r"\:", ":")


def get_current_ssid():
    r = nm("-t", "-f", "ACTIVE,SSID", "device", "wifi")
    for line in r.stdout.splitlines():
        parts = _split(line)
        if len(parts) >= 2 and parts[0] == "yes":
            return _unescape(parts[1])
    return None


def get_known_connections():
    """Restituisce {ssid: conn_name} dai profili WiFi salvati in NM."""
    r = nm("-t", "-f", "NAME,TYPE", "connection", "show")
    known = {}
    for line in r.stdout.splitlines():
        parts = _split(line)
        if len(parts) >= 2 and parts[1].strip() == "802-11-wireless":
            conn_name = _unescape(parts[0])
            r2 = nm("--get-values", "802-11-wireless.ssid", "connection", "show", conn_name)
            ssid = r2.stdout.strip()
            if ssid:
                known[ssid] = conn_name
    return known


def scan_networks():
    """Restituisce lista di reti uniche ordinate per segnale."""
    r = nm("-t", "-f", "SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes")
    if r.returncode != 0:
        return None, r.stderr.strip()

    networks = []
    seen = set()
    for line in r.stdout.splitlines():
        parts = _split(line)
        if len(parts) < 3:
            continue
        ssid = _unescape(parts[0])
        if not ssid or ssid in seen:
            continue
        seen.add(ssid)
        try:
            sig = int(parts[1])
        except ValueError:
            sig = 0
        security = _unescape(":".join(parts[2:]))
        networks.append({
            "ssid": ssid,
            "signal": sig,
            "secured": bool(security.strip()),
        })

    return networks, None


def format_line(n, current_ssid):
    marker = "●" if n["ssid"] == current_ssid else "○"
    sig = n["signal"]
    bars = (
        "▂▄▆█"
        if sig >= 75
        else "▂▄▆_"
        if sig >= 50
        else "▂▄__"
        if sig >= 25
        else "▂___"
    )
    lock = " 󰌾" if n["secured"] else ""
    return f"{marker} {n['ssid']}  {bars} {sig}%{lock}"


def fuzzel_pick(items, prompt="Wi-Fi  "):
    r = subprocess.run(
        [
            "fuzzel",
            "--dmenu",
            "--prompt",
            prompt,
            "--width",
            "40",
            "--lines",
            str(len(items)),
        ],
        input="\n".join(items),
        capture_output=True,
        text=True,
    )
    return r.stdout.strip()


def ask_password(ssid):
    r = subprocess.run(
        [
            "fuzzel",
            "--dmenu",
            "--prompt",
            f"Password per {ssid}:  ",
            "--width",
            "40",
            "--lines",
            "0",
            "--password",
        ],
        capture_output=True,
        text=True,
    )
    return r.stdout.strip()


def main():
    networks, err = scan_networks()

    if networks is None:
        notify(f"Errore nmcli:\n{err}")
        sys.exit(1)

    if not networks:
        notify("Nessuna rete trovata")
        sys.exit(1)

    current_ssid = get_current_ssid()
    known = get_known_connections()

    networks.sort(key=lambda n: (-(n["ssid"] == current_ssid), -n["signal"]))
    display_lines = [format_line(n, current_ssid) for n in networks]

    result = subprocess.run(
        ["fuzzel", "--dmenu", "--prompt", "Wi-Fi  ", "--width", "40", "--lines", "12"],
        input="\n".join(display_lines),
        capture_output=True,
        text=True,
    )

    choice = result.stdout.strip()
    if not choice:
        sys.exit(0)

    selected = next(
        (networks[i] for i, line in enumerate(display_lines) if line == choice), None
    )
    if not selected:
        sys.exit(0)

    ssid = selected["ssid"]
    secured = selected["secured"]

    if ssid in known:
        conn_name = known[ssid]
        if secured:
            action = fuzzel_pick(
                [f"  Connetti a «{ssid}»", f"  Nuova password per «{ssid}»..."],
                prompt="Wi-Fi  ",
            )
            if not action:
                sys.exit(0)
            if "Nuova password" in action:
                pwd = ask_password(ssid)
                if not pwd:
                    sys.exit(0)
                nm("connection", "modify", conn_name, "wifi-sec.psk", pwd)
        # nmcli connection up è sincrono: aspetta fino a connesso o timeout
        notify(f'Connessione a "{ssid}"…')
        r = nm("connection", "up", conn_name)
        if r.returncode == 0:
            notify(f'Connesso a "{ssid}"')
        else:
            notify(f'Impossibile connettersi a "{ssid}"')
    else:
        # Rete nuova: nmcli device wifi connect è sincrono
        if secured:
            pwd = ask_password(ssid)
            if not pwd:
                sys.exit(0)
        else:
            pwd = None

        args = ["device", "wifi", "connect", ssid]
        if pwd:
            args += ["password", pwd]

        notify(f'Connessione a "{ssid}"…')
        r = nm(*args)
        if r.returncode == 0:
            notify(f'Connesso a "{ssid}"')
        else:
            notify(f'Impossibile connettersi a "{ssid}" (password errata?)')
            # NM salva il profilo anche se la connessione fallisce; rimuovilo
            nm("connection", "delete", ssid)


if __name__ == "__main__":
    main()
