local utils = require('mp.utils')
local msg = require('mp.msg')

local function request(action, params)
    return {
        action = action,
        params = params,
        version = 6
    }
end

local function make_request(action, params)
    local json_request = utils.format_json(request(action, params))
    local command = {
        "curl",
        "-s",
        "http://localhost:8765",
        "-X", "POST",
        "-H", "Content-Type: application/json",
        "-d", json_request
    }

    local result = utils.subprocess({
        args = command,
        capture_stdout = true
    })

    if result.status == 0 then
        local response = utils.parse_json(result.stdout)
        if response and response.error then
            msg.error("AnkiConnect error: " .. response.error)
            return nil
        end
        return response and response.result
    else
        msg.error("Failed to communicate with AnkiConnect")
        return nil
    end
end

local function get_last_added_card_id()
    local result = make_request("findNotes", { query = "added:1" })
    if result and #result > 0 then
        return result[#result]
    end
    return nil
end

local last_card_id = nil
local timer = nil

local function check_for_new_cards()
    local current_card_id = get_last_added_card_id()

    if current_card_id and current_card_id ~= last_card_id then
        msg.info("New card detected: " .. current_card_id)
        last_card_id = current_card_id

        mp.command("script-message mpvacious-update-last-note")
    end
end

local function start_monitoring()
    if timer then
        timer:kill()
    end

    last_card_id = get_last_added_card_id()
    msg.info("Starting Anki card monitoring...")

    timer = mp.add_periodic_timer(1, check_for_new_cards)
end

local function stop_monitoring()
    if timer then
        timer:kill()
        timer = nil
    end
    msg.info("Stopped Anki card monitoring")
end

mp.register_script_message("ankisync-start", start_monitoring)
mp.register_script_message("ankisync-stop", stop_monitoring)

mp.register_event("file-loaded", start_monitoring)

mp.register_event("end-file", stop_monitoring)
