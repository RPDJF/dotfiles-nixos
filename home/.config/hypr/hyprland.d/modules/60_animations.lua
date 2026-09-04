local hl = rawget(_G, "hl")

local curves = {
    { "easeOutQuint",   { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } } },
    { "easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } } },
    { "linear",         { type = "bezier", points = { { 0, 0 }, { 1, 1 } } } },
    { "almostLinear",   { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } } },
    { "quick",          { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } } },
}

for _, curve in ipairs(curves) do
    hl.curve(curve[1], curve[2])
end

local animations = {
    { leaf = "global",        enabled = true, speed = 1,    bezier = "default" },
    { leaf = "border",        enabled = true, speed = 2,    bezier = "easeOutQuint" },
    { leaf = "windows",       enabled = true, speed = 1,    bezier = "easeOutQuint" },
    { leaf = "windowsIn",     enabled = true, speed = 1,    bezier = "easeOutQuint", style = "popin 87%" },
    { leaf = "windowsOut",    enabled = true, speed = 1,    bezier = "linear",       style = "popin 87%" },
    { leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" },
    { leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" },
    { leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" },
    { leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" },
    { leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" },
    { leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" },
    { leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" },
    { leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" },
    { leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" },
    { leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
}

for _, animation in ipairs(animations) do
    hl.animation(animation)
end

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 20,
        border_size = 3,
        col = {
            active_border = { colors = { "rgba(8aadf4ee)", "rgba(c6a0f6ee)" }, angle = 0 },
            inactive_border = "rgba(363a4faa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 10,
        active_opacity = 0.9,
        inactive_opacity = 0.8,
        shadow = {
            enabled = false,
            range = 10,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
})
