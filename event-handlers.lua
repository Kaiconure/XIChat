-- ========================================================================= --
-- EVENT HANDLERS
-- ========================================================================= --

function addon_onLoad()
    addon_state.player = windower.ffxi.get_player()

    loadSettings()

    -- Start the background threads
    coroutine.schedule(MessageSenderCoRoutine, 0)
    coroutine.schedule(QueryLinkshellStateCoRoutine, 5)

    showWelcomeMessage()
    queryEquippedLinkshells('load', true)
end

function addon_onUnload()
    addon_state.player = nil

    return
end

function addon_onLogin(name)
    addon_state.player = windower.ffxi.get_player()

    loadSettings()

    showWelcomeMessage()
    queryEquippedLinkshells('login', true)
end

function addon_onLogout(name)
    --
    -- An event handler for when a character logs in
    --

    return
end

function addon_onLinkshellChange(new_name, old_name)
    queryEquippedLinkshells('linkshell_change', false)
end

function addon_onZoneChange(new_zone_id, old_zone_id)
    addon_state.zone_time = os.clock()
end

function addon_onIncomingText(original_message, modified_message, original_mode, modified_mode, blocked)
    ---------------------------------------------------------------------------------
    -- Output from /lsmes (linkshell 1 info)
    if original_mode == 205 then
        local ls1name = string.match(original_message, '^%[1]< (%a+): %a+ >%s*$')
        if ls1name then
            addon_state.ls1name = ls1name
            addon_state.ls1 = nil

            local _, ls_by_name = findEquippedLinkshells()
            if ls_by_name and ls_by_name[ls1name] then
                addon_state.ls1 = ls_by_name[ls1name]
            end
        end
        
        return
    end

    ---------------------------------------------------------------------------------
    -- Output from /ls2mes (linkshell 2 info)
    if original_mode == 217 then
        local ls2name = string.match(original_message, '^%[2]< (%a+): %a+ >%s*$')
        if ls2name then
            addon_state.ls2name = ls2name
            addon_state.ls2 = nil

            local _, ls_by_name = findEquippedLinkshells()
            if ls_by_name and ls_by_name[ls2name] then
                addon_state.ls2 = ls_by_name[ls2name]
            end
        end

        return
    end

    ---------------------------------------------------------------------------------
    -- ls2 outgoing (6) or incoming (14)
    if original_mode == 6 or original_mode == 14 then
        if
            addon_state.ls1name and
            addon_state.player and addon_state.player.name
        then

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                linkshell_name = addon_state.ls1name,
                message = original_message
            })
        end

        return
    end

    ---------------------------------------------------------------------------------
    -- LS2 outgoing (213) or incoming (214)
    if original_mode == 213 or original_mode == 214 then
        if
            addon_state.ls2name and
            addon_state.player and addon_state.player.name
        then

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                linkshell_name = addon_state.ls2name,
                message = original_message
            })
        end

        return
    end
end

function addon_onAddonCommand(command, ...)
    --
    -- An event handler for when the addon receives a command
    --

    if command and CommandHandlers[command] then
        CommandHandlers[command](...)
    else
        writeColoredMessage(ChatColors.red, 'Unknown command: %s':format(command or 'nil'))
    end
end