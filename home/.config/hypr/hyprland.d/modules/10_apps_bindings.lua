local app_bindings = {
    [mainMod .. " + Q"] = terminal,
    [mainMod .. " + D"] = discord,
    [mainMod .. " + N"] = browser,
    [mainMod .. " + SHIFT + N"] = browser_private,
    [mainMod .. " + X"] = codeapp,
    [mainMod .. " + O"] = mail,
    [mainMod .. " + P"] = cloud,
    [mainMod .. " + A"] = aicompanion,
    [mainMod .. " + V"] = terminal .. " --class clipse -e clipse",
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

