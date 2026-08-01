local app_commands = {
    mainMod = "SUPER",
    terminal = "kitty",
    fileManager = "nautilus",
    browser = "librewolf",
    browser_private = "librewolf --private-window",
    discord = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland",
    codeapp = "code --enable-features=UseOzonePlatform --ozone-platform=wayland",
    mail = "librewolf https://mail.proton.me",
    cloud = "librewolf https://proton.me/drive",
    aicompanion = "librewolf https://ai.local.lan",
}

for name, value in pairs(app_commands) do
    _G[name] = value
end
