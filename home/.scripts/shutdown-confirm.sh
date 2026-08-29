#!/usr/bin/env bash

echo
echo -e ' \033[1;31mSHUTDOWN IN 10 SECONDS\033[0m'
echo
echo -e ' \033[1;33m(press Ctrl+C or Esc to cancel)\033[0m'
echo

# Function to check for escape key press without echoing input
check_escape() {
    local old_stty=$(stty -g)
    stty -echo -icanon min 0 time 1
    
    if read -t 0.1 -n 1 key; then
        # Check if it's ESC (ASCII 27)
        if [ "$key" = $'\033' ]; then
            echo -e " \n\033[1;31mSHUTDOWN CANCELLED\033[0m"
            stty "$old_stty"
            exit 0
        fi
    fi
    
    stty "$old_stty"
}

for i in {10..1}; do
    echo -ne "\r\033[1;33m  $i\033[0m "
    sleep 1
    echo -ne "\r\033[2K"
    
    # Check for escape key press after each second
    check_escape
done

echo -e ' \n\033[1;32mSHUTDOWN PROCEEDING...\033[0m'
systemctl poweroff
