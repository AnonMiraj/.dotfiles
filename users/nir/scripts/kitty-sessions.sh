#!/usr/bin/env bash

SESSION_DIR="$HOME/.config/kitty"
OPTIONS=$(find "$SESSION_DIR" -maxdepth 1 -type f -name "*.kitty-session" -printf "%f\n" | sort)

if [ -z "$OPTIONS" ]; then
    notify-send "No Kitty sessions found in $SESSION_DIR"
    exit 1
fi

CHOICE=$(echo -e "$OPTIONS" | vicinae dmenu --placeholder "Choose Kitty session:")

if [ -z "$CHOICE" ]; then
    echo "No session selected, exiting."
    exit 0
fi

SESSION_PATH="$SESSION_DIR/$CHOICE"

kitty --session "$SESSION_PATH" &
