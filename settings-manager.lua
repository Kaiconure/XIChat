local manager = {}

local files = require('files')      -- Lets us work with files
local json  = require('jsonlua')    -- Lets us work with JSON

function manager:empty(player_name, server_name)
    return {
        player_name = player_name,
        server_name = server_name,
        linkshells = {},
        personal = {},
        config = {}
    }
end

function manager:load(player_name, server_name)
    -- Not a valid string
    if type(player_name) ~= 'string' or type(server_name) ~= 'string' then
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
        return self:empty(player_name, server_name)
    end

    -- 
    local text = file:read()
    if not text then
        return self:empty(player_name, server_name)
    end

    local settings = json.parse(text)
    if type(settings) ~= 'table' then
        return self:empty(player_name, server_name)
    end

    -- Bail if there are no configurations for either linkshells or tells
    if type(settings.linkshells) ~= 'table' and type(settings.personal) ~= 'table' then
        return self:empty(player_name, server_name)
    end

    -- Create empty tables for any missing chat configurations (at least one is present if we got to this point)
    if type(settings.linkshells) ~= 'table' then settings.linkshells = {} end
    if type(settings.personal) ~= 'table' then settings.personal = {} end

    local num_results = 0
    local result = self:empty(player_name, server_name)

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
                    (server and server == server_name) and
                    type(api_key) == 'string' 
                then
                    
                    -- Api keys always start with the player name, case-sensitive
                    local name_match = '^' .. player_name .. '%-'
                    if string.match(api_key, name_match) then                
                        result.linkshells[linkshell] = {
                            linkshell = linkshell,
                            server_name = server,
                            api_key = api_key,
                            player_name = player_name
                        }
                        num_results = num_results + 1

                        --print('API key detected for linkshell [%s] on [%s]':format(linkshell, server))
                    end
                end
            end
        end
    end
    result.linkshell_count = num_results
    
    -- NOTE: With the current schema, there can only ever be one personal api key per player/server combination
    num_results = 0
    for _personal, personalconfig in pairs(settings.personal) do
        if type(_personal) == 'string' then
            local separator = string.find(_personal, '@') or 0
            if separator > 1 then
                local personal = string.sub(_personal, 1, separator - 1)
                local server = string.sub(_personal, separator + 1)

                personal = string.gsub(tostring(personal) or '', '[^A-Za-z]', '')
                server = string.gsub(tostring(server) or '', '[^A-Za-z]', '')
                local api_key = personalconfig.api_key
                if
                    (personal and personal ~= '') and
                    (server and server == server_name) and
                    type(api_key) == 'string' 
                then
                    
                    -- Api keys always start with the player name, case-sensitive
                    local name_match = '^' .. player_name .. '%-'
                    if string.match(api_key, name_match) then
                        local excludes = {}

                        -- Create a keyed table based on the exclusion types
                        if type(personalconfig.exclude) == 'table' and #personalconfig.exclude > 0 then
                            for i, exclusion in ipairs(personalconfig.exclude) do
                                if type(exclusion) == 'string' then
                                    excludes[string.lower(exclusion)] = true
                                end
                            end
                        end

                        result.personal[player_name] = {
                            player_name = player_name,
                            server_name = server,
                            api_key = api_key,
                            exclude = excludes
                        }

                        num_results = num_results + 1
                    end
                end
            end
        end
    end
    result.personal_count = num_results

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