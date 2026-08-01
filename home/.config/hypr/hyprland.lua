-- Hyprland Lua entrypoint.
-- This keeps the existing profile symlink behavior intact while loading the new modules layout deterministically.

local function expand_home(path)
    if not path then
        return nil
    end
    if path:sub(1, 2) == "~" then
        return os.getenv("HOME") .. path:sub(2)
    end
    return path
end

local function source_directory(directory)
    local expanded = expand_home(directory)
    if not expanded then
        return
    end

    local handle = io.popen("find -L " .. expanded .. " -maxdepth 1 -name '*.lua' 2>/dev/null | sort")
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

source_directory("~/.config/hypr/hyprland.d/modules")
source_directory("~/.config/hypr/hyprland.d")
source_directory("~/.config/hypr/hyprland.profiles.d/current")
