#!/bin/bash

source ./game_logic.sh
CONFIG_FILE="emojis.cfg"

# --- CONFIGURATION ---
COLS=2
ROWS=2
TOTAL_CARDS=$((ROWS * COLS))
DECK=( $(create_deck "$CONFIG_FILE" "$TOTAL_CARDS") )
MATCHES_FOUND=0
MATCHES_NEEDED=$((TOTAL_CARDS / 2))
TURNS=0

# Initialize Mask
DECK_MASK=()
for ((i=0; i<TOTAL_CARDS; i++)); do
    DECK_MASK+=("❓")
done

# Prepare Column Headers
column_args=("--column=ID") 
for ((i=1; i<=COLS; i++)); do
    column_args+=( "--column=Col $i" )
done

# --- MAIN GAME LOOP ---
game_loop

# Final Victory Message
zenity --info --text="Gratulacje! Wszystkie pary znalezione w $TURNS tur!"

# Ask to save score
if zenity --question --title="Zapisz wynik" --text="Czy chcesz zapisać swój wynik ($TURNS tur)?" --ok-label="Tak" --cancel-label="Nie"; then
    
    # Prompt for Player Name
    PLAYER_NAME=$(zenity --entry --title="Twoje imię" --text="Podaj swoje imię, aby zapisać wynik:")
    
    if [[ -n "$PLAYER_NAME" ]]; then
        # Append score to a file
        echo "$(date '+%Y-%m-%d %H:%M') - $PLAYER_NAME: $TURNS tur - plansza $COLS x $ROWS" >> highscores.txt
        
        zenity --info --text="Wynik został zapisany dla $PLAYER_NAME!"
    else
        zenity --info --text="Nie podano imienia. Wynik nie został zapisany."
    fi
fi