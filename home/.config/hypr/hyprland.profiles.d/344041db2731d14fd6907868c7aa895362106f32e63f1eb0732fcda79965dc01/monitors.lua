hl.monitor({
    output = "desc:ASUSTek COMPUTER INC XG32UCWMG T7LMQS112894",
    mode = "3840x2160@240.02",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    supports_hdr = 0,
    supports_wide_color = 1,
    cm = "srgb",
    sdrbrightness = 1.05,
    sdrsaturation = 1.05,
})

hl.monitor({
    output = "desc:ASUSTek COMPUTER INC VG27A R1LMQS086730",
    mode = "2560x1440@165",
    position = "3840x0",
    scale = 1,
})

hl.workspace_rule({
    workspace = "1",
    monitor = "desc:ASUSTek COMPUTER INC XG32UCWMG T7LMQS112894",
    default = true,
})
