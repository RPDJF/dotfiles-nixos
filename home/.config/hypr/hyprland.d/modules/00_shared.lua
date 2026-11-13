local app_commands = {
    mainMod = "SUPER",
    terminal = "kitty",
    fileManager = "nautilus",
    browser = "librewolf",
    browser_private = "librewolf --private-window",
    discord = "discord --enable-features=UseOzonePlatform --ozone-platform=wayland",
    codeapp = "code --enable-features=UseOzonePlatform --ozone-platform=wayland",
    mail = "librewolf https://mail.proton.me",
    cloud = "librewolf https://proton.me/drive",
    aicompanion = "librewolf https://ai.local.lan",
}

for name, value in pairs(app_commands) do
    _G[name] = value
end

---@param eval_content string The command or content to execute with taskset
---@param mode? 'default' | 'vcache' | 'frequency' The CPU affinity mode ("default", "vcache", or "frequency")
---@return string The formatted taskset command string
function PIN_EVAL(eval_content, mode)
    mode = mode or "default"

    local store_name = "cpu_default_affinity"
    if mode == "vcache" then
        store_name = "cpu_vcache_affinity"
    elseif mode == "frequency" then
        store_name = "cpu_frequency_affinity"
    end

    _G[store_name] = _G[store_name] or {}

    if not _G[store_name][mode] then
        local home = os.getenv("HOME") or "/home/ruipa"
        local cmd = "bash " .. home .. "/.scripts/get-cpu-affinity.sh"
        if mode ~= "default" then
            cmd = cmd .. " " .. mode
        end

        local handle = io.popen(cmd)
        if handle ~= nil then
            local result = handle:read("*a")
            handle:close()
            _G[store_name][mode] = result:gsub("%s+", "")
        else
            _G[store_name][mode] = ""
        end
    end

    local taskset_args = _G[store_name][mode]
    if taskset_args == "" then
        local handle = io.popen("nproc")
        if handle ~= nil then
            local total_cores = tonumber(handle:read("*a"):gsub("%s+", "")) or 1
            handle:close()
            taskset_args = "0-" .. tostring(total_cores - 1)
        else
            taskset_args = "0-0"
        end
    end

    return "taskset -c " .. taskset_args .. " " .. eval_content
end
