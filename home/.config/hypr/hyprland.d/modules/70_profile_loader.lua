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

local function read_file(path)
    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local content = file:read("*a")

    file:close()

    return content:gsub("%s+$", "")
end

local function source_directory(directory)

    local command = "find -L " .. string.format("%q", directory) .. " -maxdepth 1 -type f -name '*.lua' | sort"

    local handle = io.popen(command .. " 2>/dev/null")

    if not handle then
        return
    end

    local found = false

    for path in handle:lines() do

        found = true

        local chunk, err = loadfile(path)

        if not chunk then

        else

            local ok, runtime_err = pcall(chunk)

            if not ok then

            else

            end
        end
    end

    handle:close()

    if not found then
    end
end

-- ============================================================
-- START
-- ============================================================

local HOME = os.getenv("HOME")

local profile_root = HOME .. "/.config/hypr/hyprland.profiles.d"

-- ============================================================
-- Read machine ID
-- ============================================================

local machine_id = read_file("/etc/machine-id")

if not machine_id then

    return
end

-- ============================================================
-- Read salt
-- ============================================================

local salt_path = "/etc/nixos/machine-id-salt.txt"

local salt = read_file(salt_path)

if not salt then

    return
end

-- ============================================================
-- Generate profile hash
--
-- Same algorithm as your original Bash:
--
-- printf "%s%s" "$salt" "$machine_id" | sha256sum
-- ============================================================

local command = string.format("printf '%%s%%s' %q %q | sha256sum", salt, machine_id)

local profile_hash = shell(command)

if not profile_hash or profile_hash == "" then

    return
end

-- sha256sum returns:
--
-- <hash>  -
--
-- shell() only reads the first line, so extract
-- the first whitespace-separated field.

profile_hash = profile_hash:match("^(%S+)")

if not profile_hash then

    return
end

-- ============================================================
-- Construct profile path
-- ============================================================

local profile_directory = profile_root .. "/" .. profile_hash

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

