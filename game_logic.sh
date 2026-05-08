#!/bin/bash

# --- Odczyt liczby symboli ---
get_config_info() {
    local FILE="$1"
    if [[ -f "$FILE" ]]; then
        local SYMBOLS=($(tr ' ' '\n' < "$FILE" | sort -u))
        echo "${#SYMBOLS[@]}"
    else
        echo "-1"
    fi
}

# --- Tworzenie i sortowanie kart do gry ---
create_deck() {
    local FILE="$1"
    local TOTAL_REQUIRED=$2
    local UNIQUE_REQUIRED=$((TOTAL_REQUIRED / 2))
    
    if [[ -f "$FILE" ]]; then
        read -r -a ALL_SYMBOLS <<< "$(tr ' ' '\n' < "$FILE" | sort -u | tr '\n' ' ')"
    else
        echo "Błąd: Nie znaleziono pliku $FILE" >&2
        return 1
    fi

    local SELECTED_SYMBOLS=("${ALL_SYMBOLS[@]:0:$UNIQUE_REQUIRED}")

    local DECK=()
    for SYMBOL in "${SELECTED_SYMBOLS[@]}"; do
        DECK+=("$SYMBOL" "$SYMBOL")
    done

    printf "%s\n" "${DECK[@]}" | shuf
}

game_loop(){
    while [ $MATCHES_FOUND -lt $MATCHES_NEEDED ]; do
    
    PICKED_IDS=()

    # --- pętla wyboru ---
    while [ ${#PICKED_IDS[@]} -lt 2 ]; do

        # --- Tworzenie planszy na podstawie maski ---
        GRID_DATA=()
        for ((i=0; i<ROWS; i++)); do
            GRID_DATA+=("$i") 
            for ((j=0; j<COLS; j++)); do
                idx=$((i * COLS + j))
                GRID_DATA+=("${DECK_MASK[$idx]}")
            done
        done

        # --- okno wyboru wiersza ---
        SELECTED_ROW=$(zenity --list \
            --title="Memory Game - Ruch $((${#PICKED_IDS[@]} + 1))/2" \
            --text="Wybierz rząd kart (Znaleziono par: $MATCHES_FOUND/$MATCHES_NEEDED   Liczba tur: $TURNS):" \
            --width=600 --height=500 \
            --hide-header \
            "${COLUMN_ARGS[@]}" --hide-column=1 --print-column=ALL --separator="|" \
            "${GRID_DATA[@]}" \
            --cancel-label="Wyjdź" --ok-label="Wyjdź")

        [[ -z "$SELECTED_ROW" ]] && exit

        IFS='|' read -r -a ROW_ARRAY <<< "$SELECTED_ROW"
        ROW_NUM=${ROW_ARRAY[0]}

        # --- okno wyboru kolumny ---
        ROW_DISPLAY=""
        for ((i=1; i<${#ROW_ARRAY[@]}; i++)); do ROW_DISPLAY+="[Kol $i]: ${ROW_ARRAY[$i]}  "; done

        CMD=(zenity --question --title="Wybierz kolumnę" \
            --text="Wybrany rząd: $((ROW_NUM + 1))\nZawartość: $ROW_DISPLAY\n\nKtórą kolumnę odkrywasz?" \
            --cancel-label="Wyjdź" --ok-label="Wyjdź")

        for ((j=1; j<=COLS; j++)); do CMD+=( "--extra-button=Kolumna $j" ); done

        RAW_BTN=$("${CMD[@]}" 2>&1)
        EXIT_STATUS=$?

        if [[ $EXIT_STATUS -ne 0 && -z "$RAW_BTN" ]]; then exit; fi
        
        COL_CHOICE=$(echo "$RAW_BTN" | grep -o '[0-9]\+' | tail -n 1)
        [[ -z "$COL_CHOICE" ]] && continue
        
        COL_NUM=$((COL_CHOICE - 1))
        CURRENT_ID=$(( (ROW_NUM * COLS) + COL_NUM ))


        if [[ "${DECK_MASK[$CURRENT_ID]}" != "❓" ]]; then
            zenity --warning --text="Ta karta jest już odkryta! Wybierz inną."
            continue
        fi

        # --- odkrycie wybranej karty ---
        DECK_MASK[$CURRENT_ID]="${DECK[$CURRENT_ID]}"
        PICKED_IDS+=("$CURRENT_ID")

        zenity --info --text="Odkryłeś: ${DECK[$CURRENT_ID]}" --timeout=1
    done

    # --- Sprawdzanie kart ---
    ID_1=${PICKED_IDS[0]}
    ID_2=${PICKED_IDS[1]}

    if [[ "${DECK[$ID_1]}" == "${DECK[$ID_2]}" ]]; then
        zenity --info --text="Para! Znalazłeś: ${DECK[$ID_1]}"
        ((MATCHES_FOUND++))
    else
        zenity --warning --text="Nie pasują!\n\nKarta 1: ${DECK[$ID_1]}\nKarta 2: ${DECK[$ID_2]}" 
        
        DECK_MASK[$ID_1]="❓"
        DECK_MASK[$ID_2]="❓"

        TURNS=$((TURNS+1))
    fi
done
}