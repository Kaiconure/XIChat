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
    print('LS1: %s %s':format(addon_state.ls1 and addon_state.ls1.name or '<none>', addon_state.ls1 and addon_state.ls1.type or ''))
    print('LS2: %s %s':format(addon_state.ls2 and addon_state.ls2.name or '<none>', addon_state.ls2 and addon_state.ls2.type or ''))
end