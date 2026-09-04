local hl = rawget(_G, "hl")
local mainMod = rawget(_G, "mainMod")
local terminal = rawget(_G, "terminal")
local fileManager = rawget(_G, "fileManager")

-- Dynamically find hyprcapture-ui using 'which'
local function get_helper_path()
    local handle = io.popen("which hyprcapture-ui 2>/dev/null")
    if handle then
        local path = handle:read("*a"):gsub("%s+", "")
        handle:close()
        if path ~= "" then
            return path
        end
    end
    return "/run/current-system/sw/bin/hyprcapture-ui" -- safe fallback
end

-- Load the plugin
hl.plugin.load("/run/current-system/sw/lib/libhyprcapture.so")

-- Configure HyprCapture with the dynamically found helper path
hl.config({
    plugin = {
        hyprcapture = {
            helper = get_helper_path()
        }
    }
})

--

local menu = "rofi -modi drun,run -show drun -show-icons"
local gotoscript = "bash ~/.scripts/goto.sh"

local bindings = { { mainMod .. " + ALT + B", hl.dsp.exec_cmd("~/.scripts/hypr-toggle-hdr.sh toggle") },

    -- Replaced hyprshot with native HyprCapture region mode
    { "print", function()
        hl.plugin.hyprcapture.open("region")
    end },                                                     -- Optional: Add extra capture shortcuts if you want them handy
    { mainMod .. " + SHIFT + S", hl.plugin.hyprcapture.open }, -- opens default/fusion
    { mainMod .. " + SHIFT + W", function()
        hl.plugin.hyprcapture.open("window")
    end }, { mainMod .. " + L", hl.dsp.exec_cmd("hyprlock") }, { mainMod .. " + F", hl.dsp.window.fullscreen({
    mode = "maximized",
    action = "toggle"
}) }, { mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({
    mode = "fullscreen",
    action = "toggle"
}) },
    { mainMod .. " + ESCAPE",
        hl.dsp.exec_cmd(terminal .. " --class shutdown_confirm -e ~/.scripts/shutdown-confirm.sh") },
    { mainMod .. " + C", hl.dsp.window.close() },
    { mainMod .. " + E", hl.dsp.exec_cmd(fileManager .. " --new-window") },
    { mainMod .. " + R", hl.dsp.exec_cmd(menu) }, { mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(gotoscript) },
    { mainMod .. " + J",       hl.dsp.layout("togglesplit") }, { mainMod .. " + left", hl.dsp.focus({
    direction = "left"
}) }, { mainMod .. " + right", hl.dsp.focus({
    direction = "right"
}) }, { mainMod .. " + up", hl.dsp.focus({
    direction = "up"
}) }, { mainMod .. " + down", hl.dsp.focus({
    direction = "down"
}) }, { mainMod .. " + 1", hl.dsp.focus({
    workspace = 1
}) }, { mainMod .. " + 2", hl.dsp.focus({
    workspace = 2
}) }, { mainMod .. " + 3", hl.dsp.focus({
    workspace = 3
}) }, { mainMod .. " + 4", hl.dsp.focus({
    workspace = 4
}) }, { mainMod .. " + 5", hl.dsp.focus({
    workspace = 5
}) }, { mainMod .. " + 6", hl.dsp.focus({
    workspace = 6
}) }, { mainMod .. " + 7", hl.dsp.focus({
    workspace = 7
}) }, { mainMod .. " + 8", hl.dsp.focus({
    workspace = 8
}) }, { mainMod .. " + 9", hl.dsp.focus({
    workspace = 9
}) }, { mainMod .. " + 0", hl.dsp.focus({
    workspace = 10
}) }, { mainMod .. " + SHIFT + 1", hl.dsp.window.move({
    workspace = 1
}) }, { mainMod .. " + SHIFT + 2", hl.dsp.window.move({
    workspace = 2
}) }, { mainMod .. " + SHIFT + 3", hl.dsp.window.move({
    workspace = 3
}) }, { mainMod .. " + SHIFT + 4", hl.dsp.window.move({
    workspace = 4
}) }, { mainMod .. " + SHIFT + 5", hl.dsp.window.move({
    workspace = 5
}) }, { mainMod .. " + SHIFT + 6", hl.dsp.window.move({
    workspace = 6
}) }, { mainMod .. " + SHIFT + 7", hl.dsp.window.move({
    workspace = 7
}) }, { mainMod .. " + SHIFT + 8", hl.dsp.window.move({
    workspace = 8
}) }, { mainMod .. " + SHIFT + 9", hl.dsp.window.move({
    workspace = 9
}) }, { mainMod .. " + SHIFT + 0", hl.dsp.window.move({
    workspace = 10
}) }, -- Note: Changed special workspace toggle key to avoid colliding with SHIFT + S capture bind
    { mainMod .. " + ALT + S", hl.dsp.workspace.toggle_special("magic") },
    { mainMod .. " + ALT + SHIFT + S", hl.dsp.window.move({
        workspace = "special:magic"
    }) }, { mainMod .. " + mouse_down", hl.dsp.focus({
    workspace = "e+1"
}) }, { mainMod .. " + mouse_up", hl.dsp.focus({
    workspace = "e-1"
}) }, { mainMod .. " + mouse:272", hl.dsp.window.drag() }, { mainMod .. " + mouse:273", hl.dsp.window.resize() },
    { "XF86AudioRaiseVolume",    hl.dsp.exec_cmd("~/.scripts/swayosd-wrapper.sh volume up") },
    { "XF86AudioLowerVolume",    hl.dsp.exec_cmd("~/.scripts/swayosd-wrapper.sh volume down") },
    { "XF86AudioMute",           hl.dsp.exec_cmd("~/.scripts/swayosd-wrapper.sh volume mute") },
    { "XF86MonBrightnessUp",     hl.dsp.exec_cmd("~/.scripts/swayosd-wrapper.sh brightness up") },
    { "XF86MonBrightnessDown",   hl.dsp.exec_cmd("~/.scripts/swayosd-wrapper.sh brightness down") },
    { "XF86AudioPlay",
        hl.dsp.exec_cmd("playerctl play-pause && ~/.scripts/swayosd-wrapper.sh media play-pause") },
    { "XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous && ~/.scripts/swayosd-wrapper.sh media prev") },
    { "XF86AudioNext", hl.dsp.exec_cmd("playerctl next && ~/.scripts/swayosd-wrapper.sh media next") } }

for _, binding in ipairs(bindings) do
    hl.bind(binding[1], binding[2])
end

hl.window_rule({
    match = {
        class = "^(shutdown_confirm)$"
    },
    float = true,
    size = "300 100"
})
