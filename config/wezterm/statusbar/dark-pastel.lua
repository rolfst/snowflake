local wez = require("wezterm")

wez.on("update-right-status", function(window, pane)
    local datetime = "   " .. wez.strftime("%B %e, %H:%M  ")

    window:set_right_status(wez.format({
        -- { Attribute = { Underline = "Single" } },
        { Attribute = { Italic = true } },
        { Foreground = { Color = "#55ff55" } },
        { Text = datetime },
    }))

    window:set_left_status(wez.format({
        { Background = { Color = "#5555ff" } },
        { Foreground = { Color = "#ffffff" } },
        { Text = "     " },
    }))
end)

wez.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background = "#000000"
    local foreground = "#5555ff"
    local symbolic = " ○ "

    if tab.is_active then
        background = "#000000"
        foreground = "#ff55ff"
        symbolic = " 綠 "
    elseif hover then
        background = "#333333"
        foreground = "#55ffff"
    end

    local edge_background = background
    local edge_foreground = "#555555"
    local separator = " | "

    -- ensure that the titles fit in the available space,
    -- and that we have room for the edges.
    local title = wez.truncate_right(tab.active_pane.title, max_width - 5)
        .. "…"

    return {
        -- Separator
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        -- Active / Inactive
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = symbolic .. " " .. title },
        -- Separator
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = separator },
    }
end)

return {}
