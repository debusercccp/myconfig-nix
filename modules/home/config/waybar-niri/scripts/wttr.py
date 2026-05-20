#!/usr/bin/env python3

import json
from datetime import datetime
import requests

WEATHER_CODES = {
    "113": "",
    "116": "",
    "119": "",
    "122": "",
    "143": "",
    "176": "󰼳",
    "179": "󰼴",
    "182": "󰼵",
    "185": "󰖗",
    "200": "",
    "227": "",
    "230": "",
    "248": "",
    "260": "",
    "263": "",
    "266": "",
    "281": "",
    "284": "",
    "293": "󰖗",
    "296": "󰖗",
    "299": "",
    "302": "",
    "305": "",
    "308": "",
    "311": "",
    "314": "",
    "317": "",
    "320": "",
    "323": "",
    "326": "",
    "329": "",
    "332": "",
    "335": "",
    "338": "",
    "350": "󰼩",
    "353": "",
    "356": "",
    "359": "",
    "362": "",
    "365": "",
    "368": "󰖘",
    "371": "",
    "374": "",
    "377": "",
    "386": "",
    "389": "",
    "392": "",
    "395": "",
}

data = {}

# Richiesta JSON a wttr.in (Località impostata su Roma, cambiala se preferisci)
try:
    weather = requests.get("https://wttr.in/Bari?format=j1").json()
except Exception as e:
    data["text"] = "󰖪 --°"
    data["tooltip"] = f"Errore di connessione: {str(e)}"
    print(json.dumps(data))
    exit(1)


def format_time(time_str):
    return time_str.replace("00", "").zfill(2)


def format_temp(temp):
    return (str(temp) + "°").ljust(3)


def format_chances(hour_data):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind",
    }

    conditions = []
    for event in chances.keys():
        if int(hour_data[event]) > 0:
            conditions.append(f"{chances[event]} {hour_data[event]}%")
    return ", ".join(conditions)


current = weather["current_condition"][0]
tempint = int(current["FeelsLikeC"])
extrachar = ""

if 0 < tempint < 10:
    extrachar = "+"

# Output principale sulla barra di Waybar
data["text"] = (
    f"{WEATHER_CODES[current['weatherCode']]} {extrachar}{current['FeelsLikeC']}°"
)

# Tooltip (Finestra pop-up al passaggio del mouse)
data["tooltip"] = f"<b>{current['weatherDesc'][0]['value']} {current['temp_C']}°</b>\n"
data["tooltip"] += f"Feels like: {current['FeelsLikeC']}°\n"
data["tooltip"] += f"Wind: {current['windspeedKmph']} Km/h\n"
data["tooltip"] += f"Humidity: {current['humidity']}%\n"

for i, day in enumerate(weather["weather"]):
    data["tooltip"] += "\n<b>"
    if i == 0:
        data["tooltip"] += "Today, "
    elif i == 1:
        data["tooltip"] += "Tomorrow, "

    data["tooltip"] += f"{day['date']}</b>\n"
    data["tooltip"] += f" {day['maxtempC']}°  {day['mintempC']}° "
    data[
        "tooltip"
    ] += f" {day['astronomy'][0]['sunrise']}  {day['astronomy'][0]['sunset']}\n"

    for hour in day["hourly"]:
        hour_time = int(format_time(hour["time"]))
        if i == 0 and hour_time < datetime.now().hour - 2:
            continue

        # FIX: Sostituito FeelsLikeF con FeelsLikeC per coerenza con il sistema metrico europeo
        data["tooltip"] += (
            f"{str(hour_time).zfill(2)}:00 {WEATHER_CODES[hour['weatherCode']]} "
            f"{format_temp(hour['FeelsLikeC'])} {hour['weatherDesc'][0]['value']}"
        )

        chances_str = format_chances(hour)
        if chances_str:
            data["tooltip"] += f", {chances_str}\n"
        else:
            data["tooltip"] += "\n"

print(json.dumps(data))
