#!/usr/bin/env bash

# Shutdown menu.

HYPRCMDS=$(hyprctl -j clients | jq -j '.[] | "dispatch hl.dsp.window.close({ window = \"address:\(.address)\" }); "')
hyprctl --batch "$HYPRCMDS"
sleep 0.25
eww close powermenu

if [[ $(hyprctl -j clients | jq length) -gt 0 ]]; then
		notify-send -a Warning "Some clients haven't quit!"
		exit
fi

COMMAND=""
MESSAGE=""

case $1 in
	"shutdown")
		MESSAGE="Shutting down."
		COMMAND="systemctl poweroff"
	;;
	"restart")
		MESSAGE="Restarting."
		COMMAND="systemctl reboot"
	;;
	"logout")
		MESSAGE="Logging Out."
		COMMAND="hyprctl dispatch 'hl.dsp.exit()'"
	;;
	*)
		notify-send -a Usage "powmenu <shutdown | restart | logout>"
		exit
	;;
esac

notify-send -a System "$MESSAGE"
sleep 0.25
# TODO: Kill volumed here
eval $COMMAND
