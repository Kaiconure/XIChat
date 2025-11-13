-- ========================================================================= --
-- EVENT HANDLERS
-- ========================================================================= --

function addon_onLoad()
    addon_state.player = windower.ffxi.get_player()
    --print('addon_onLoad: Player=%s':format(addon_state.player and addon_state.player.name or 'nil'))

    loadSettings()

    -- Start the background threads
    coroutine.schedule(MessageSenderCoRoutine, 0)
    coroutine.schedule(QueryLinkshellStateCoRoutine, 5)

    showWelcomeMessage()

    --print('addon_onLoad: Has settings? %s':format(addon_state.settings and 'Yes' or 'No'))

    queryEquippedLinkshells('load', true)
end

function addon_onUnload()
    addon_state.unloading = true

    addon_state.server_id = nil
    addon_state.server_name = nil
    addon_state.player = nil
    addon_state.settings = nil
end

function addon_onLogin(name)
    addon_state.player = windower.ffxi.get_player()
    --print('addon_onLogin: Player=%s':format(addon_state.player and addon_state.player.name or 'nil'))

    loadSettings()
    showWelcomeMessage()

    --print('addon_onLogin: Has settings? %s':format(addon_state.settings and 'Yes' or 'No'))

    queryEquippedLinkshells('login', true)
end

function addon_onLogout(name)
    http.disable_logging()

    addon_state.server_id = nil
    addon_state.server_name = nil
    addon_state.player = nil
    addon_state.settings = nil
end

function addon_onLinkshellChange(new_name, old_name)
    queryEquippedLinkshells('linkshell_change', false)
end

function addon_onStatusChange(new_status_id, old_status_id)
    if type(new_status_id) == 'number' then
        -- Relevant Status values:
        --  0: Idle
        --  1: Engaged
        --  2: Dead
        --  3: Engaged Dead
        if 
            (new_status_id == 2 or new_status_id == 3) and  -- To: KO
            (old_status_id ~= 2 and old_status_id ~= 3)     -- From: non-KO
        then
            if not isPersonalMessageTypeAllowed('defeat') then
                return
            end

            local info = windower.ffxi.get_info()
            local zone = info and info.zone and resources.zones[info.zone]

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = '%s has been defeated%s.':format(
                    addon_state.player.name,
                    zone and ' in %s':format(zone.name) or ''
                ),
                mode = 'defeat'
            })
        elseif
            (new_status_id ~= 2 and new_status_id ~= 3) and -- To: non-KO
            (old_status_id == 2 or old_status_id == 3)      -- From: KO
        then
            if not isPersonalMessageTypeAllowed('defeat') then
                return
            end

            local info = windower.ffxi.get_info()
            local zone = info and info.zone and resources.zones[info.zone]

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = '%s has returned from defeat%s.':format(
                    addon_state.player.name,
                    zone and ' in %s':format(zone.name) or ''
                ),
                mode = 'defeat'
            })
        end
    end
end

function addon_onZoneChange(new_zone_id, old_zone_id)

    -- Exit early of this message type is not allowed
    if not isPersonalMessageTypeAllowed('zone') then
        return
    end

    addon_state.zone_time = os.clock()

    local old_zone = old_zone_id and resources.zones and resources.zones[old_zone_id]
    local zone = resources.zones and resources.zones[new_zone_id]

    if zone then
        local me = windower.ffxi.get_player()
        local info = windower.ffxi.get_info()

        local message = nil
        if old_zone then
            message = '%s has zoned into %s from %s.':format(
                me and me.name or 'Player',
                zone.name,
                old_zone.name
            )
        else
            message = '%s has Zoned into %s.':format(
                me and me.name or 'Player',
                zone.name
            )
        end

        message_queue:enqueue({
            timestamp = makePortableTimestamp(),
            player_name = addon_state.player.name,
            server_name = addon_state.server_name,
            message = message,
            mode = 'zone'
        })
    end
end

function addon_onExamined(examined_by, examined_by_index)
    -- Exit early of this message type is not allowed
    if not isPersonalMessageTypeAllowed('examine') then
        return
    end

    if type(examined_by) == 'string' then
        local me = windower.ffxi.get_mob_by_target('me')

        message_queue:enqueue({
            timestamp = makePortableTimestamp(),
            player_name = addon_state.player.name,
            server_name = addon_state.server_name,
            message = '%s has examined %s.':format(examined_by, me and me.name or 'you'),
            mode = 'interaction',
            sub_mode = 'examine',
            sender = examined_by
        })
    end
end

function addon_onEmote(emote_id, sender_id, target_id, is_motion_only)

    -- Exit early of this message type is not allowed
    if not isPersonalMessageTypeAllowed('emote') then
        return
    end

    local target = target_id and windower.ffxi.get_mob_by_id(target_id)
    if not target then
        return
    end

    local me = windower.ffxi.get_mob_by_target('me')
    if not me then
        return
    end

    local emote = emote_id and resources.emotes and resources.emotes[emote_id]
    local sender = sender_id and windower.ffxi.get_mob_by_id(sender_id)    

    if target then
        if 
            target.id == me.id or
            (sender and sender.id == me.id) or
            (sender and sender.spawn_type == 13) or -- 13 seems to be the spawn type for player party members
            target.spawn_type == 13
        then
            local message = '%s received a [%s] emote from %s.':format(
                target.name,
                capitalizeFirst(emote and emote.command or 'Unknown'),
                sender and sender.name or 'Unknown'
            )

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = message,
                mode = 'interaction',
                sub_mode = 'emote',
                sender = sender and sender.name
            })
        end
    end
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
    -- Output from /servmes (server info)
    -- if original_mode == 0x0C8 then
    --     local servername = string.match(original_message, '^<<< Welcome to (%a+)! >>>*$')
    --     if servername then
    --         addon_state.server_name = servername
    --         writeMessage(colorize(ChatColors.gray, 'Detected server name: %s':format(colorize(ChatColors.green, servername))))
    --     end

    --     return
    -- end

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
                server_name = addon_state.server_name,
                message = original_message,
                mode = 'linkshell'
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
                server_name = addon_state.server_name,
                message = original_message,
                mode = 'linkshell'
            })
        end

        return
    end

    ---------------------------------------------------------------------------------
    -- Tell incoming (12) or outgoing (4)
    if original_mode == 12 or original_mode == 4 then
        -- Exit early of this message type is not allowed
        if not isPersonalMessageTypeAllowed('tell') then
            return
        end

        -- We need to sanitize the message for this part, to strip control characters out of the first part at least.
        -- The purpose of this code is to identify *actual* tells rather than addons which annoying try to send
        -- fake tells to communicate with you.
        local sanitized = string.gsub(original_message, '[^%a%d%p ]', '')
        local is_valid_outgoing = 
            string.match(sanitized, '^>>(%a+) : ')    -- >>Kaladin : Hello, world!    [A tell to Kaladin]
        local is_valid_incoming = not is_valid_outgoing 
            and string.match(sanitized, '^(%a+)>> ')  -- Kaladin>> Hey to you!        [A tell from Kaladin]

        if is_valid_incoming or is_valid_outgoing then
            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = original_message,
                mode = 'tell',
                sender = is_valid_outgoing or is_valid_incoming -- Note: The match checks are set up so they will capture the other party's name
            })
        end

        return
    end

    ---------------------------------------------------------------------------------
    -- Party incoming (13) or outgoing (5)
    if original_mode == 13 or original_mode == 5 then
        -- Exit early of this message type is not allowed
        if not isPersonalMessageTypeAllowed('party') then
            return
        end

        -- We need to sanitize the message for this part, to strip control characters out of the first part at least.
        -- The purpose of this code is to identify *actual* party chat rather than addons which annoyingly try to
        -- send fake messages to communicate with you.
        local sanitized = string.gsub(original_message, '[^%a%d%p ]', '')
        local is_valid = string.match(sanitized, '^%((%a+)%) ') -- (Kaladin) Hello, World!

        if is_valid then
            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = original_message,
                mode = 'party',
                sender = is_valid -- Note: The match check is set up so it will capture the party member's name
            })
        end

        return
    end

    -- Error messages. Some of these should be sent as notifications.
    if original_mode == 123 then

        local is_failed_tell = string.find(original_message, 'Your tell was not received')
        if is_failed_tell then
            if not isPersonalMessageTypeAllowed('tell') then
                return
            end

            local sanitized = string.gsub(string.sub(original_message, is_failed_tell, -2), '[^%a%d%p ]', '')

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = sanitized,
                mode = 'tell'
            })

            return
        end
    end

    -- local test = string.find(original_message, 'Your tell was not received')
    -- if test then
    --     print('Found match with id=%d [%s]':format(original_mode, original_message))
    -- end
end

function addon_onIncomingChunk(id, original, modified, injected, blocked)
	if id == 0x00B then
        addon_state.items_initialized = false
    elseif id == 0x00A then
		addon_state.items_initialized = false
	elseif id == 0x01D and not addon_state.items_initialized then
        -- Items have been loaded
        addon_state.items_initialized = true
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