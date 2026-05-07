#!/bin/bash
source ./game_logic.sh

CONFIG_FILE="emojis.cfg"

# --- Odczyt symboli z pliku ---
UNIQUE_SYMBOLS=$(get_config_info "$CONFIG_FILE")

if [ "$UNIQUE_SYMBOLS" -eq -1 ]; then
    zenity --error --text="Błąd: Nie znaleziono pliku $CONFIG_FILE"
    exit 1
fi

# --- Odczyt liczby kart w grze ---
PAIRS=$(zenity --scale \
    --title="Wielkość gry" \
    --text="Wybierz liczbę par do znalezienia (Max: $UNIQUE_SYMBOLS):" \
    --min-value=2 \
    --max-value="$UNIQUE_SYMBOLS" \
    --value=2 \
    --step=1)

[[ -z "$PAIRS" ]] && exit

TOTAL_CARDS=$((PAIRS * 2))

# --- Konfiguracja planszy ---
if (( TOTAL_CARDS > 8 )); then
    if (( TOTAL_CARDS % 4 == 0 )); then
        COLS=4
    elif (( TOTAL_CARDS % 3 == 0 )); then
        COLS=3
    else
        COLS=2
    fi
else
    if (( TOTAL_CARDS % 3 == 0 )); then
        COLS=3
    else
        COLS=2
    fi
fi

ROWS=$((TOTAL_CARDS / COLS))

TOTAL_CARDS=$((ROWS * COLS))
DECK=( $(create_deck "$CONFIG_FILE" "$TOTAL_CARDS") )
MATCHES_FOUND=0
MATCHES_NEEDED=$((TOTAL_CARDS / 2))
TURNS=0

DECK_MASK=()
for ((i=0; i<TOTAL_CARDS; i++)); do
    DECK_MASK+=("❓")
done

COLUMN_ARGS=("--column=ID") 
for ((i=1; i<=COLS; i++)); do
    COLUMN_ARGS+=( "--column=Col $i" )
done

# --- Pętla gry ---
game_loop

zenity --info --text="Gratulacje! Wszystkie pary znalezione w $TURNS tur!"

if zenity --question --title="Zapisz wynik" --text="Czy chcesz zapisać swój wynik ($TURNS tur)?" --ok-label="Tak" --cancel-label="Nie"; then
    
    PLAYER_NAME=$(zenity --entry --title="Twoje imię" --text="Podaj swoje imię, aby zapisać wynik:")
    
    if [[ -n "$PLAYER_NAME" ]]; then
        echo "$TURNS|$PLAYER_NAME|$(date '+%Y-%m-%d %H:%M')|$COLS x $ROWS" >> highscores.txt
        zenity --info --text="Wynik został zapisany!"
    else
        zenity --info --text="Nie podano imienia. Wynik nie został zapisany."
    fi
fi