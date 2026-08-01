-- Hyprland Lua entrypoint.
-- This file keeps the existing include behavior intact while making the loader more robust.

local function expand_home(path)
    if not path then
        return nil
    end
    if path:sub(1, 2) == "~" then
        return os.getenv("HOME") .. path:sub(2)
    end
    return path
end

local function source_glob(pattern)
    local expanded = expand_home(pattern)
    if not expanded then
        return
    end

    local handle = io.popen("ls " .. expanded .. " 2>/dev/null")
    if not handle then
        return
    end

    for path in handle:lines() do
        local chunk, err = loadfile(path)
        if chunk then
            chunk()
        else
            io.stderr:write("hyprland.lua: failed to load " .. path .. ": " .. tostring(err) .. "\n")
        end
    end

    handle:close()
end

source_glob("~/.config/hypr/hyprland.d/*.lua")
source_glob("~/.config/hypr/hyprland.profiles.d/current/*.lua")
