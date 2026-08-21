local environment_variables = {
    XKBLAYOUT = "ch",
    XKB_DEFAULT_LAYOUT = "ch",
    XKBVARIANT = "fr",
    XKB_DEFAULT_VARIANT = "fr"
}

for name, value in pairs(environment_variables) do
    hl.env(name, value)
end