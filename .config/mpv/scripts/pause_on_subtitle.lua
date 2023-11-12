-- pause_on_subtitle.lua

local is_paused = false

function on_event(name, value)
    if name == "sub-text" and not is_paused then
        mp.set_property("pause", "yes")
    end
end

function toggle_pause()
    is_paused = not is_paused
    mp.set_property("pause", is_paused and "yes" or "no")
    show_message(is_paused and "pause on subtitle OFF" or "pause on subtitle ON")
end

function show_message(text)
    mp.osd_message(text, 2)  -- Display the message for 2 seconds
end

mp.add_key_binding("Ctrl+o", "toggle_pause", toggle_pause)

mp.observe_property("sub-text", "string", on_event)

