hl.on("hyprland.start", function()
    hl.exec_cmd("nvidia-settings -a \"[gpu:0]/GpuPowerMizerMode=1\"")
end)

