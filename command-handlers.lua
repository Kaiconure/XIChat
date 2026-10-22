CommandHandlers = {}

---------------------------------------------------------------------
-- TODO: Implement command handlers, which will execute when
-- corresponding commands are passed to your addon via the 
-- Windower console or the FFXI chat.
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Handler for the colortest command
--
CommandHandlers['colortest'] = function (...)
    local output = '\n'
    for i = 1, 144 do
        if i > 1 and i % 12 == 1 then
            output = output .. '\n'
        end

        output = output .. colorize(i, '%03d ':format(i))
    end

    windower.add_to_chat(1, output)
end

CommandHandlers['lslist'] = function(...)
    writeMessage('Tracked Linkshells on %s':format(colorize(ChatColors.green, addon_state.server_name or '<unknown server>')))
    writeMessage('  Slot #1: %s %s':format(
        colorize(ChatColors.green, addon_state.ls1 and addon_state.ls1.name or '<none>'),
        colorize(ChatColors.yellow, addon_state.ls1 and addon_state.ls1.type or '')))
    writeMessage('  Slot #2: %s %s':format(
        colorize(ChatColors.green, addon_state.ls2 and addon_state.ls2.name or '<none>'),
        colorize(ChatColors.yellow, addon_state.ls2 and addon_state.ls2.type or '')))
end

CommandHandlers['list'] = CommandHandlers['lslist']

CommandHandlers['routing'] = function (...)
    local args = {...}
    if #args ~= 2 or args[1] ~= '-name' or not args[2]:match('^%a+$') then
        writeColoredMessage(ChatColors.red, 'Usage: //xic routing -name <player>')
        return
    end
    local player = addon_state.player
    if not player or not player.name then
        writeColoredMessage(ChatColors.red, 'A logged-in character is required to configure routing.')
        return
    end
    local recipient = capitalizeFirst(args[2]:lower())
    if recipient:lower() == player.name:lower() then
        writeColoredMessage(ChatColors.red, 'The routing recipient must be another character.')
        return
    end
    local ok, err = pcall(settings_manager.saveRoutingRecipient, settings_manager, player.name, recipient)
    if not ok then
        writeColoredMessage(ChatColors.red, 'Failed to save routing settings: %s', tostring(err))
        return
    end
    if addon_state.settings then addon_state.settings.routing_recipient = recipient end
    writeMessage('Routing recipient set to: %s', colorize(ChatColors.green, recipient))
end

CommandHandlers['notify'] = function (...)
    local message = table.concat({...}, ' ')
    if message == '' then
        writeColoredMessage(ChatColors.red, 'Usage: //xic notify <message>')
        return
    end

    if not addon_state.player or not addon_state.player.name or not addon_state.server_name then
        print('XIChat: A logged-in character and server are required to send a notification.')
        return
    end

    message_queue:enqueue({
        timestamp = makePortableTimestamp(),
        player_name = addon_state.player.name,
        server_name = addon_state.server_name,
        message = message,
        sender = 'XIChat',
        mode = 'notification'
    })
end

CommandHandlers['reload'] = function(...)
    local settings = loadSettings(true)
    if settings then
        writeMessage(colorize(ChatColors.green, 'XIChat Settings reloaded!'))
    else
        print('XIChat: Warning: Failed to reload settings!')
    end
end
CommandHandlers['r'] = CommandHandlers['reload']
