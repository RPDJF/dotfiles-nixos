local environment_variables = {
    XKBLAYOUT = "us",
    XKB_DEFAULT_LAYOUT = "us",
    XKBVARIANT = "",
    XKB_DEFAULT_VARIANT = "",
}

for name, value in pairs(environment_variables) do
    hl.env(name, value)
end