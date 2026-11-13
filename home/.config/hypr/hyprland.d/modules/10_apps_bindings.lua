local hl = rawget(_G, "hl")
local mainMod = rawget(_G, "mainMod")
local terminal = rawget(_G, "terminal")
local discord = rawget(_G, "discord")
local browser = rawget(_G, "browser")
local browser_private = rawget(_G, "browser_private")
local codeapp = rawget(_G, "codeapp")
local mail = rawget(_G, "mail")
local cloud = rawget(_G, "cloud")
local aicompanion = rawget(_G, "aicompanion")

local app_bindings = {
    [mainMod .. " + Q"] = terminal,
    [mainMod .. " + D"] = PIN_EVAL(discord, 'frequency'),
    [mainMod .. " + N"] = PIN_EVAL(browser, 'frequency'),
    [mainMod .. " + SHIFT + N"] = PIN_EVAL(browser_private, 'frequency'),
    [mainMod .. " + X"] = PIN_EVAL(codeapp, 'frequency'),
    [mainMod .. " + O"] = PIN_EVAL(mail, 'frequency'),
    [mainMod .. " + P"] = PIN_EVAL(cloud, 'frequency'),
    [mainMod .. " + A"] = PIN_EVAL(aicompanion, 'frequency'),
    [mainMod .. " + V"] = PIN_EVAL(terminal .. " --class clipse -e clipse", 'frequency')
}

for key, command in pairs(app_bindings) do
    hl.bind(key, hl.dsp.exec_cmd(command))
end

hl.window_rule({
    match = {
        class = "^(clipse)$",
    },
    float = true,
    size = "622 652",
    stay_focused = true,
})

hl.window_rule({
    match = {
        title = "^(vault\\.ruinformatique\\.ch_/)$",
    },
    float = true,
    size = "1100 800",
})
