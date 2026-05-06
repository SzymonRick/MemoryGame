#!/bin/bash

create_deck() {
    local FILE="$1"
    
    if [[ -f "$FILE" ]]; then
        read -r -a SYMBOLS < "$FILE"
    else
        zenity --error \
        --title="Error" \
        --text="Config file $FILE not found"
        return 1
    fi

    local DECK=()
    for SYMBOL in "${SYMBOLS[@]}"; do
        DECK+=("$SYMBOL" "$SYMBOL")
    done

    echo $(printf "%s\n" "${DECK[@]}" | shuf)
}