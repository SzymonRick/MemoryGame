#!/bin/bash

source ./game_logic.sh

CONFIG_FILE="emojis.cfg"

DECK=( $(create_deck "$CONFIG_FILE") )

MAX_SIZE=${#DECK[@]}

ROWS=4
COLS=4
TOTAL_CARDS=$((ROWS * COLS))

column_args=()
for ((i=1; i<=COLS; i++)); do
    column_args+=( "--column=$i" )
done

selected=$(zenity --list \
    --title="Memory Game Grid" \
    --text="Pick a card to reveal it!" \
    "${column_args[@]}" \
    "${DECK[@]}" \
    --hide-header)

echo "Total items in array: ${#DECK[@]}"
echo "Total items in array: $selected"