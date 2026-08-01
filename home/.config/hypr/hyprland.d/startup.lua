local startup_commands = {
    "~/.scripts/hypr-service.sh waybar waybar",
    "~/.scripts/hypr-service.sh wallpaper $HOME/.scripts/hypr-live-wallpaper.sh",
    "~/.scripts/hypr-service.sh hypridle hypridle",
    "~/.scripts/hypr-service.sh polkit \"systemctl --user start hyprpolkitagent\"",
    "~/.scripts/hypr-service.sh mako mako",
    "~/.scripts/hypr-service.sh clipse \"clipse -listen\"",
    "~/.scripts/hypr-service.sh nm-applet nm-applet",
    "~/.scripts/hypr-service.sh swayosd swayosd-server",
    "~/.scripts/hypr-service.sh blueman blueman-applet",
    "~/.scripts/hypr-service.sh plugins $HOME/.config/hypr/loadHyprlandPlugins.sh",
    "sleep 3 && ~/.scripts/hypr-service.sh waybar-peek $HOME/.scripts/waybar-peek.py",
    "~/.scripts/hypr-service.sh animations \"$HOME/.scripts/hypr-animations.sh > /dev/null\"",
}

hl.on("hyprland.start", function()
    for _, command in ipairs(startup_commands) do
        hl.exec_cmd(command)
    end
end)

