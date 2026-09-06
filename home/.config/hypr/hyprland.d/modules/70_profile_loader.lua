-- 70_profile_loader.lua
--
-- Automatically loads the Hyprland profile belonging to this machine.
--
-- machine-id + salt
--        ↓
--      SHA256
--        ↓
-- profile hash
--        ↓
-- ~/.config/hypr/hyprland.profiles.d/<hash>/
--
local function shell(command)
    local pipe = io.popen(command .. " 2>/dev/null")

    if not pipe then
        return nil
    end

    local result = pipe:read("*l")

    pipe:close()

    return result
end


local function source_directory(directory)
    local command = "find -L " .. string.format("%q", directory) .. " -maxdepth 1 -type f -name '*.lua' | sort"

    local handle = io.popen(command .. " 2>/dev/null")

    if not handle then
        return
    end

    for path in handle:lines() do
        local chunk = loadfile(path)

        if chunk then
            pcall(chunk)
        end
    end

    handle:close()
end

-- ============================================================
-- START
-- ============================================================

local HOME = os.getenv("HOME")

local profile_directory = shell(string.format("%q/.scripts/hypr-profile-dir", HOME))

if not profile_directory then
    return
end

-- ============================================================
-- Verify profile exists
-- ============================================================

local exists = shell("test -d " .. string.format("%q", profile_directory) .. " && echo yes")

if exists ~= "yes" then
    return
end

-- ============================================================
-- Load profile
-- ============================================================

source_directory(profile_directory)
