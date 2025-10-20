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

function addon_onZoneChange(new_zone_id, old_zone_id)
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
    if type(examined_by) == 'string' then
        local me = windower.ffxi.get_mob_by_target('me')

        message_queue:enqueue({
            timestamp = makePortableTimestamp(),
            player_name = addon_state.player.name,
            server_name = addon_state.server_name,
            message = '%s has examined %s.':format(examined_by, me and me.name or 'you'),
            mode = 'interaction'
        })
    end
end

function addon_onEmote(emote_id, sender_id, target_id, is_motion_only)

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
            target.spawn_type == 13 -- 13 seems to be the spawn type for player party members
        then
            local message = '%s receved [%s] emote from %s.':format(
                target.name,
                emote and emote.command or 'unknown',
                sender and sender.name or 'unknown'
            )

            message_queue:enqueue({
                timestamp = makePortableTimestamp(),
                player_name = addon_state.player.name,
                server_name = addon_state.server_name,
                message = message,
                mode = 'interaction'
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
        message_queue:enqueue({
            timestamp = makePortableTimestamp(),
            player_name = addon_state.player.name,
            server_name = addon_state.server_name,
            message = original_message,
            mode = 'tell'
        })

        return
    end

    ---------------------------------------------------------------------------------
    -- Party incoming (13) or outgoing (5)
    if original_mode == 13 or original_mode == 5 then
        message_queue:enqueue({
            timestamp = makePortableTimestamp(),
            player_name = addon_state.player.name,
            server_name = addon_state.server_name,
            message = original_message,
            mode = 'party'
        })

        return
    end
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