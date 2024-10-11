#!/bin/bash

battery="/sys/class/power_supply/BAT1"

while true; do
    capacity=$(cat "$battery/capacity" 2>/dev/null)
    status=$(cat "$battery/status" 2>/dev/null)

    if [[ $capacity -lt 10 && $status == "Discharging" ]]; then
        notify-send "Battery Low" "Battery level is very low!" -u critical
        paplay ~/.local/bin/lowbattary.mp3
    fi

    sleep 60  
done

