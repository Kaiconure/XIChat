require('helpers')

default_settings = {
    service_host = 'xichat.kaikaiju.com',
    linkshells = {}
}

addon_state =
{
    processor_running = false,
    player = nil,
    ls1name = nil,
    ls2name = nil,
    settings = nil,
    zone_time = 0,
    last_ls_check = 0,
    items_initialized = windower.ffxi.get_info().logged_in
}

---------------------------------------------------------------------
--  TODO: You can use this file as the jumping off ponit for your
--  custom addon code.
---------------------------------------------------------------------

function showWelcomeMessage()
    -- We'll get the player object for two reasons:
    --  1. So we can welcome the player by name, and
    --  2. So we don't try to write chat messages if we're not signed in 
    --      as a player. This can happen when signed in to FFXI without
    --      selecting a character yet, or between switching characters.
    --
    local player = windower.ffxi.get_player()
    if not player then
        return
    end

    writeColoredMessage(ChatColors.green, 'Welcome to [%s], %s!':format(
        colorize(ChatColors.yellow, ADDON_NAME, ChatColors.green),
        colorize(ChatColors.blue, player.name, ChatColors.green)
    ))
    writeColoredMessage(ChatColors.gray,
        'Valid API keys are required to use this addon. Refer to our GitHub for details:')
    writeColoredMessage(ChatColors.gray,
        '  https://github.com/Kaiconure/XIChat')
end

---------------------------------------------------------------------
-- Loads settings from a file. If no file name is provided,
-- the default settings file name is used.
---------------------------------------------------------------------
function loadSettings(fileName)
    if addon_state.player and addon_state.player.name then
        addon_state.settings = settings_manager:load(addon_state.player.name)
        --writeJsonToFile('./licenses/%s.processed.json':format(addon_state.player.name), addon_state.settings)
    else
        addon_state.settings = nil
    end
end

---------------------------------------------------------------------
-- Trigers the events that cause the equipped linkshell names
-- to be interrogated. This is an asynchronous operation.
---------------------------------------------------------------------
function queryEquippedLinkshells(context, force)
    -- Only perform the update if you actually have linkshells equipped. This deals
    -- with a few scenarios, including the "dead time" while items are being loaded
    -- between zones. Yes, we will miss detection of all linkshells being removed.
    -- However, this should be a non-issue because we double-check equipped linkshells
    -- before sending out messages.

    -- Don't mess with equipped linkshell state if items haven't been initialized yet
    if not addon_state.items_initialized then
        return
    end

    local player = windower.ffxi.get_player()
    if not player then
        return
    end

    local linkshells, by_name = findEquippedLinkshells()

    -- If there are no linkshells equipped, we'll just clear things out and
    -- return. This prevents some query spam during and after zoning.
    if not linkshells then
        addon_state.ls1name = nil
        addon_state.ls1 = nil

        addon_state.ls2name = nil
        addon_state.ls2 = nil

        --print('none equipped')

        return
    end

    --print('%d equipped':format(#linkshells))

    local ls1 = addon_state.ls1 and by_name and by_name[addon_state.ls1.name]
    local ls2 = addon_state.ls2 and by_name and by_name[addon_state.ls2.name]

    local ls1match = 
        (ls1 == nil and addon_state.ls1 == nil) or
        (ls1 and addon_state.ls1 and ls1.bagId == addon_state.ls1.bagId and ls1.localId == addon_state.ls1.localId and ls1.linkshell_id == addon_state.ls1.linkshell_id)

    local ls2match = 
        (ls2 == nil and addon_state.ls2 == nil) or
        (ls2 and addon_state.ls2 and ls2.bagId == addon_state.ls2.bagId and ls2.localId == addon_state.ls2.localId and ls2.linkshell_id == addon_state.ls2.linkshell_id)

    -- Reset ls1 on mismatch
    if not ls1match then
        addon_state.ls1name = nil
        addon_state.ls1 = nil
    end

    -- Reset ls2 on mismatch
    if not ls2match then
        addon_state.ls2name = nil
        addon_state.ls2 = nil
    end

    if ls1match and ls2match then
        if not force then
            return
        end
    end

    -- The query is unreliable shortly after zoning
    addon_state.last_ls_check = os.clock()
    writeMessage(colorize(ChatColors.gray, 'Querying equipped linkshells...'))
    windower.send_command('input /lsmes; wait 0.5; input /ls2mes;')
end

function queueMessage(player, linkshell, message)
    player = player or windower.ffxi.get_player()

    if 
        player and player.name and
        linkshell and
        message
    then
        local entry = {
            player = player.name,
            linkshell = linkshell,
            message = message
        }
    end
end

AUTOTRANSLATE_START   = string.char(239, 39)
AUTOTRANSLATE_END     = string.char(239, 40)

AUTOTRANSLATE_START_GSUB  = AUTOTRANSLATE_START
AUTOTRANSLATE_END_GSUB    = string.char(239) .. '%('   -- Character 40 is a control character for gsub (open paren), so it needs special handling

function QueryLinkshellStateCoRoutine()
    while true do
        if addon_state.items_initialized then
            local player = windower.ffxi.get_player()
            if player then
                local force = false
                local clear = false
                local linkshells, by_name = findEquippedLinkshells()

                if linkshells ~= nil then
                    local count = #linkshells
                    local count_tracked = 0

                    if addon_state.ls1 ~= nil and addon_state.ls2 ~= nil then
                        -- Both are set, two are tracked
                        count_tracked = 2
                    elseif addon_state.ls1 == nil and addon_state.ls2 == nil then
                        -- Both are nil, none tracked
                        count_tracked = 0
                    else
                        -- The only option is that one or the other is set, one tracked
                        count_tracked = 1
                    end

                    force = count ~= count_tracked

                    queryEquippedLinkshells('query_worker', force)
                else
                    addon_state.ls1name = nil
                    addon_state.ls1 = nil
                    addon_state.ls2name = nil
                    addon_state.ls2 = nil
                end            
            end

            coroutine.sleep(10)
        else
            coroutine.sleep(2)
        end
    end
end

function MessageSenderCoRoutine()
    if addon_state.processor_running then
        print('ERROR: XIChat Message Sender Co-Routine is Already Running!')
        return
    end

    -- addon_state.processor_running = true

    while true do
        local settings = addon_state.settings
        local num_sent = 0

        while
            message_queue:size() > 0 and
            num_sent < 5
        do
            --print('queue size: %d':format(message_queue:size()))
            local item = message_queue:dequeue()

            if
                type(item) == 'table' and
                settings and
                addon_state.player and
                settings.player_name == addon_state.player.name and
                type(settings.service_host) == 'string'
            then
                local config = 
                    addon_state.settings and
                    addon_state.settings.linkshells and
                    addon_state.settings.linkshells[item.linkshell_name]

                local is_valid = 
                    config and
                    type(config.api_key) == 'string' and
                    type(config.linkshell) == 'string' and
                    config.linkshell == item.linkshell_name

                if is_valid then
                    local sanitized_message = item.message

                    -- writeJsonToFile(
                    --     '/data/messages/%.2f-linkshell.json':format(os.clock()),
                    --     { message = sanitized_message }
                    -- )

                    sanitized_message = string.gsub(sanitized_message, AUTOTRANSLATE_START_GSUB, '{')
                    sanitized_message = string.gsub(sanitized_message, AUTOTRANSLATE_END_GSUB, '}')
                    sanitized_message = string.gsub(sanitized_message, '[^%a%d%p ]', '')

                    item.message = sanitized_message

                    local request = {
                        url = 'https://%s/api/messages/ls':format(settings.service_host),
                        method = 'POST',
                        headers = http.make_headers({
                                ['Authorization'] = 'Bearer ' .. config.api_key
                            }),
                        payload = http.make_payload(item),
                        immediate = true
                    }

                    local response = http.send_request(request)
                    if settings.config.verbose then
                        print('%s queued payload:\r\n  Player: %s\r\n  Linkshell: %s\r\n  Message: [%s]':format(
                            response and response.success and 'Successfully' or 'Unsuccessfully',
                            item.player_name,
                            item.linkshell_name,
                            item.message
                        ))
                    end
                end
            end

            num_sent = num_sent + 1
            coroutine.sleep(0.5)
        end

        coroutine.sleep(1)
    end

    addon_state.processor_running = false
end