local hl = rawget(_G, "hl")

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, disable\" && hyprlock"),
    { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1, 1920x1080@60, 0x0, 1\""),
    { locked = true })
