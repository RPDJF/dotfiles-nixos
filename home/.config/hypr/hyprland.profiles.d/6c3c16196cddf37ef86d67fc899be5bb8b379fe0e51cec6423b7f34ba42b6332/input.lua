local hl = rawget(_G, "hl")

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.config({
    input = {
        kb_layout = "ch",
        kb_variant = "fr",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
    gestures = {
        workspace_swipe_touch = true,
    },
})
