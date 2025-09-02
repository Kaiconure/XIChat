local manager = {}

local files = require('files')      -- Lets us work with files
local json  = require('jsonlua')    -- Lets us work with JSON

function manager:empty(player_name)
    return {
        player_name = player_name,
        linkshells = {},
        config = {}
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
        if type(_linkshell) == 'string' then
            local separator = string.find(_linkshell, '@') or 0
            if separator > 1 then
                local linkshell = string.sub(_linkshell, 1, separator - 1)
                local server = string.sub(_linkshell, separator + 1)

                linkshell = string.gsub(tostring(linkshell) or '', '[^A-Za-z]', '')
                server = string.gsub(tostring(server) or '', '[^A-Za-z]', '')
                local api_key = lsconfig.api_key
                if
                    (linkshell and linkshell ~= '') and
                    (server and server ~= '') and
                    type(api_key) == 'string' 
                then
                    
                    -- Api keys always start with the player name, case-sensitive
                    local name_match = '^' .. player_name .. '%-'
                    if string.match(api_key, name_match) then                
                        result.linkshells[linkshell] = {
                            linkshell = linkshell,
                            server_name = server,
                            api_key = api_key
                        }
                        num_results = num_results + 1

                        --print('API key detected for linkshell [%s] on [%s]':format(linkshell, server))
                    end
                end
            end
        end
    end

    result.linkshell_count = num_results
    result.service_host = type(settings.service_host) == 'string' and settings.service_host or 'xichat.kaikaiju.com'

    result.config = { verbose = false }
    local config_file_name = './config/main.json'
    local config_file = files.new(config_file_name)
    if config_file:exists() then
       local config_text = config_file:read()
       if config_text then
            result.config = json.parse(config_text)
            if type(result.config) ~= 'table' then
                result.config = {}
            end
        end
    end

    return result
end

return manager