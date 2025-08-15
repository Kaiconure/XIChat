local manager = {}

local files = require('files')      -- Lets us work with files
local json  = require('jsonlua')    -- Lets us work with JSON

function manager:empty(player_name)
    return {
        player_name = player_name,
        linkshells = {}
    }
end

function manager:load(player_name)
    -- Not a valid string
    if type(player_name) ~= 'string' then
        return self:empty()
    end

    -- Remove invalid characters, and ensure we have a valid string left
    player_name = string.gsub(player_name, '[^A-Za-z]', '')
    if player_name == '' then
        return self:empty()
    end

    -- Construct the player's settings file name and verify it exists
    local file_name = './licenses/%s.json':format(player_name)
    local file = files.new(file_name)
    if not file:exists() then
        return self:empty(player_name)
    end

    -- 
    local text = file:read()
    if not text then
        return self:empty(player_name)
    end

    local settings = json.parse(text)
    if type(settings) ~= 'table' then
        return self:empty(player_name)
    end

    if type(settings.linkshells) ~= 'table' then
        return self:empty(player_name)
    end

    local num_results = 0
    local result = self:empty(player_name)

    for _linkshell, lsconfig in pairs(settings.linkshells) do
        local linkshell = string.gsub(tostring(_linkshell) or '', '[^A-Za-z]', '')
        local api_key = lsconfig.api_key
        if linkshell ~= '' and type(api_key) == 'string' then
            
            -- Api keys always start with the player name, case-sensitive
            local name_match = '^' .. player_name .. '%-'
            if string.match(api_key, name_match) then                
                result.linkshells[linkshell] = {
                    linkshell = linkshell,
                    api_key = api_key
                }
                num_results = num_results + 1
            end
        end
    end

    result.linkshell_count = num_results
    result.service_host = type(settings.service_host) == 'string' and settings.service_host or 'xichat.kaikaiju.com'

    return result
end

return manager