local environment_variables = {
    XCURSOR_SIZE = "24",
    HYPRCURSOR_SIZE = "24",
    HYPRCURSOR_THEME = "Bibata-Modern-Ice",
    BROWSER = "librewolf",
    XDG_CURRENT_DESKTOP = "Hyprland",
    XDG_SESSION_TYPE = "wayland",
    XDG_SESSION_DESKTOP = "Hyprland",
    XKBLAYOUT = "ch",
    XKB_DEFAULT_LAYOUT = "ch",
    XKBVARIANT = "fr",
    XKB_DEFAULT_VARIANT = "fr",
}

for name, value in pairs(environment_variables) do
    hl.env(name, value)
end

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

