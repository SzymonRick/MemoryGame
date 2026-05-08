#!/bin/bash

# Author           : Szymon Rick
# Created On       : 6.05.2026
# Last Modified On : 8.05.2026
# Version          : 1.0.2
#
# Description      :
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)
# 
# Generative AI statement (keep ONE line below, delete the others):
# * I used GenAI tools for support only (e.g., explanations, debugging, small snippets).

VERSION="1.0.2"
GAME_TITLE="Memory Game Master"

# --- GETOPTS ---
usage() {
    echo "Użycie: $0 [opcje]"
    echo ""
    echo "Opcje:"
    echo "  -h    Wyświetl pomoc opcji"
    echo "  -v    Wyświetl wersję programu"
    echo "  -m    Wyświetl instrukcje gry"
    echo ""
    exit 0
}

manual() {
    echo "====================================================="
    echo "          INSTRUKCJA GRY: MEMORY GAME MASTER         "
    echo "====================================================="
    echo ""
    echo "CEL GRY:"
    echo "  Znajdź wszystkie pary ukrytych symboli w jak najmniejszej"
    echo "  liczbie ruchów (tur)."
    echo ""
    echo "JAK GRAĆ:"
    echo "  1. Po uruchomieniu gry wybierz liczbę par (rozmiar planszy)."
    echo "  2. Zobaczysz tabelę z zakrytymi kartami (❓)."
    echo "  3. Wybierz rząd, a następnie kolumnę, aby odkryć pierwszą kartę."
    echo "  4. Powtórz czynność dla drugiej karty."
    echo "  5. Jeśli symbole są identyczne - zostają odkryte na stałe."
    echo "  6. Jeśli symbole są różne - zostaną ponownie zakryte"
    echo ""
    echo "ZAPISYWANIE WYNIKÓW:"
    echo "  Po odnalezieniu wszystkich par gra zapyta Cię o nazwę."
    echo "  Twoje osiągnięcie zostanie zapisane w pliku 'highscores.txt'."
    echo ""
    echo "KONFIGURACJA GRY:"
    echo "  W pliku 'emojis.cfg' znajdują się unikalne symbole używane w grze"
    echo "  W przypadku wielu jednakowych symboli są one używane tylko raz"
    echo "  Liczba tych symboli decyduje o maksymalnym rozmiarze planszy."
    echo ""
    echo "====================================================="
    exit 0
}

while getopts "hvm" opt; do
    case ${opt} in
        h)
            usage
            ;;
        v)
            echo "$GAME_TITLE wersja $VERSION"
            exit 0
            ;;
        m)
            manual
            exit 0
            ;;
        \?)
            echo "Nieprawidłowa opcja. Użyj -h dla pomocy."
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))


# --- CONFIGURACJA ---
GAME_SCRIPT="./memory_game.sh"
HIGHSCORE_FILE="highscores.txt"

touch "$HIGHSCORE_FILE"

# --- menu ---
show_menu() {
    zenity --list \
        --title="Memory Game Master" \
        --width=400 --height=300 \
        --text="Witaj w Memory Game! Wybierz opcję:" \
        --column="Akcja" \
        "Graj" \
        "Rekordy" \
        "Wyjdź" \
        --hide-header \
        --cancel-label="Wyjdź" --ok-label="Graj"
}

# --- głowna pętla programu ---
while true; do
    CHOICE=$(show_menu)

    case "$CHOICE" in
        "Graj")
            if [[ -f "$GAME_SCRIPT" ]]; then
                bash "$GAME_SCRIPT"
            else
                zenity --error --text="Nie znaleziono pliku gry: $GAME_SCRIPT"
            fi
            ;;

        "Rekordy")
            RAW_SCORES=$(sort -t'|' -k1 -n "$HIGHSCORE_FILE")
    
            FORMATTED_LIST=()
            while IFS='|' read -r TURNS NAME DATE BOARD; do
                FORMATTED_LIST+=("$TURNS" "$NAME" "$DATE" "$BOARD")
            done <<< "$RAW_SCORES"

            zenity --list \
                --title="Najlepsze Wyniki" \
                --width=600 --height=400 \
                --column="Tury" --column="Gracz" --column="Data" --column="Plansza" \
                "${FORMATTED_LIST[@]}"
            ;;

        "Wyjdź"|*)
            zenity --question --text="Czy na pewno chcesz wyjść?" && exit
            ;;
    esac
done