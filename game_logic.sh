#!/bin/bash

create_deck() {
    local FILE="$1"
    local TOTAL_REQUIRED=$2
    local UNIQUE_REQUIRED=$((TOTAL_REQUIRED / 2))
    
    if [[ -f "$FILE" ]]; then
        # Read all symbols into an array
        read -r -a ALL_SYMBOLS < "$FILE"
    else
        echo "Error: Config file not found" >&2
        return 1
    fi

    # Check if we have enough unique symbols in the file
    if [[ ${#ALL_SYMBOLS[@]} -lt $UNIQUE_REQUIRED ]]; then
        echo "Error: Not enough symbols in $FILE. Need $UNIQUE_REQUIRED." >&2
        return 1
    fi

    # Take only the number of unique symbols we need
    local SELECTED_SYMBOLS=("${ALL_SYMBOLS[@]:0:$UNIQUE_REQUIRED}")

    local DECK=()
    for SYMBOL in "${SELECTED_SYMBOLS[@]}"; do
        # Add twice to make a pair
        DECK+=("$SYMBOL" "$SYMBOL")
    done

    # Shuffle and return
    printf "%s\n" "${DECK[@]}" | shuf
}

game_loop(){
    while [ $MATCHES_FOUND -lt $MATCHES_NEEDED ]; do
    
    # We will store the indices of the two cards picked this turn
    PICKED_INDICES=()

    while [ ${#PICKED_INDICES[@]} -lt 2 ]; do
        # 1. Build the Grid Data based on current DECK_MASK
        grid_data=()
        for ((i=0; i<ROWS; i++)); do
            grid_data+=("$i") 
            for ((j=0; j<COLS; j++)); do
                idx=$((i * COLS + j))
                grid_data+=("${DECK_MASK[$idx]}")
            done
        done

        # 2. SELECT THE ROW
        selected_row_raw=$(zenity --list \
            --title="Memory Game - Ruch $((${#PICKED_INDICES[@]} + 1))/2" \
            --text="Wybierz rząd kart (Znaleziono par: $MATCHES_FOUND/$MATCHES_NEEDED   Liczba tur: $TURNS):" \
            --width=600 --height=500 \
            "${column_args[@]}" --hide-column=1 --print-column=ALL --separator="|" \
            "${grid_data[@]}")

        [[ -z "$selected_row_raw" ]] && exit

        IFS='|' read -r -a row_array <<< "$selected_row_raw"
        ROW_NUM=${row_array[0]}

        # 3. SELECT THE COLUMN
        # Formatting row content for the question dialog
        row_display=""
        for ((i=1; i<${#row_array[@]}; i++)); do row_display+="[Kol $i]: ${row_array[$i]}  "; done

        cmd=(zenity --question --title="Wybierz kolumnę" \
            --text="Wybrany rząd: $((ROW_NUM + 1))\nZawartość: $row_display\n\nKtórą kolumnę odkrywasz?" \
            --cancel-label="Anuluj" --ok-label="Wyjdź")

        for ((j=1; j<=COLS; j++)); do cmd+=( "--extra-button=Kolumna $j" ); done

        raw_btn=$("${cmd[@]}" 2>&1)
        exit_status=$?

        # Exit logic
        if [[ $exit_status -ne 0 && -z "$raw_btn" ]]; then exit; fi
        
        COL_CHOICE=$(echo "$raw_btn" | grep -o '[0-9]\+')
        [[ -z "$COL_CHOICE" ]] && continue # If they clicked 'Wyjdź' but not a column
        
        COL_NUM=$((COL_CHOICE - 1))
        CURRENT_IDX=$(( (ROW_NUM * COLS) + COL_NUM ))

        # --- UNCOVER LOGIC ---
        # Prevent picking the same card twice or picking an already matched card
        if [[ "${DECK_MASK[$CURRENT_IDX]}" != "❓" ]]; then
            zenity --warning --text="Ta karta jest już odkryta! Wybierz inną."
            continue
        fi

        # Update the mask to show the actual card
        DECK_MASK[$CURRENT_IDX]="${DECK[$CURRENT_IDX]}"
        PICKED_INDICES+=("$CURRENT_IDX")

        # Show a quick confirmation of what was uncovered
        zenity --info --text="Odkryłeś: ${DECK[$CURRENT_IDX]}" --timeout=1
    done

    # --- MATCH CHECKING ---
    IDX1=${PICKED_INDICES[0]}
    IDX2=${PICKED_INDICES[1]}

    if [[ "${DECK[$IDX1]}" == "${DECK[$IDX2]}" ]]; then
        zenity --info --text="Para! Znalazłeś: ${DECK[$IDX1]}"
        ((MATCHES_FOUND++))
    else
        # Show both cards for a moment so the player can see them
        zenity --warning --text="Nie pasują!\n\nKarta 1: ${DECK[$IDX1]}\nKarta 2: ${DECK[$IDX2]}" 
        
        # Hide them again in the mask
        DECK_MASK[$IDX1]="❓"
        DECK_MASK[$IDX2]="❓"
    fi

    TURNS=$((TURNS+1))
done
}