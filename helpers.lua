-- ========================================================================= --
-- HELPERS
--  These are things that we might find ourselves using in more than one place,
--  but which are not part of any library.
-- ========================================================================= --

DEFAULT_COLOR     = 89  -- This will be a lavender/violet color

ChatColors = 
{
    white = 1,
    green = 2,
    blue = 6,
    magenta = 5,
    redbrick = 8,
    darkgray = 65,
    gray = 67,
    salmon = 68,
    yellow = 69,
    red = 76,
    aquamarine = 83,
    babyblue = 87,
    purple = 89,
    pink = 105,
    cornsilk = 109,
    royalblue = 112,

    linkshell = 88,
    linkshell2 = 110,
    party = 6,
    tell = 73,
}

---------------------------------------------------------------------
-- FFXI uses an "index based" coloring scheme. This function inserts
-- the correct data before and after the specified string to ensure 
-- that it will be rendered in the requested color in-game.
function colorize(color, message, returnColor)
    color = tonumber(color) or DEFAULT_COLOR
    returnColor = tonumber(returnColor) or DEFAULT_COLOR

    return string.char(0x1E, color) 
        .. (message or '')
        .. string.char(0x1E, returnColor)
end

---------------------------------------------------------------------
-- Writes a message that only you can see to the ffxi chat, using
-- the provided color index.
function writeColoredMessage(color, format, ...)
    windower.add_to_chat(1, colorize(color, string.format(format, ...)))
 end

---------------------------------------------------------------------
-- Writes a message that only you can see to the FFXI chat, using
-- the default color index.
function writeMessage(format, ...)
    writeColoredMessage(DEFAULT_COLOR, format, ...)
end

---------------------------------------------------------------------
-- Gets the index of a given search item within an array, or nil
-- if not found. An optional comparison function can be used if
-- the default equality operator is not appropriate.
function arrayIndexOf(array, search, fn)
    if type(array) == 'table' and #array > 0 then
        if type(fn) ~= 'function' then
            fn = function(a, b) return a == b end
        end

        for i = 1, #array do
            if fn(array[i], search) then
                return i
            end
        end
    end
end

---------------------------------------------------------------------
-- Gets the index of a given search string within an array of 
-- strings. The search is performed without case-sensitivity.
function arrayIndexOfStrI(array, search)
    if type(search) ~= 'string' then return end
    search = string.lower(search)

    for i = 1, #array do
        local item = array[i]
        if
            type(item) == 'string' and
            string.lower(item) == search
        then
            return i
        end
    end
end

---------------------------------------------------------------------
-- Writes an objet to a file as JSON
function writeJsonToFile(fileName, obj)
    local file = files.new(fileName)
    file:write(json.stringify(obj))
end

---------------------------------------------------------------------
-- Read an object from a JSON file
function loadJsonFromFile(fileName)
    local file = files.new(fileName)
    if not file:exists() then
        return nil
    end

    local text = file:read()
    if text then
        return json.parse(text)
    end
end

---------------------------------------------------------------------
-- Makes a UTC timestamp in the portable format based on the
-- current system time.
function makePortableTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local LINKSHELL_BAG_IDS         = { 0, 5, 6, 7 }
local LINKSHELL_BAG_NAMES_BY_ID = { [0] = 'inventory', [5] = 'satchel', [6] = 'sack', [7] = 'case' }

---------------------------------------------------------------------
-- Finds all equipped linkshells. Returns an array of up to two
-- elements, containing the following fields:
--
--   bagId          The id of the bag this linkshell was found in.
--   localId        The id/index of the linkshell within the bag.
--   linkshellId    The linkshell's unique id across all linkshells in ffxi
--   name           The linkshell's display name.
--   type           This will be either 'Linkshell' or 'Pearlsack'
--   can_create     Determines if this linkshell item allows for pearl creation.
--
-- Returns an array of equipped linkshells on success, or nil if none were found.
--
findEquippedLinkshells = function(player, items)
    local result = {}
    local results_by_name = {}

    if not addon_state.items_initialized then
        return
    end

    player = player or windower.ffxi.get_player()
    if player then
        items = items or windower.ffxi.get_items()        

        if items then
            local primary_linkshell = nil
            local secondary_linkshell = nil

            local primary_linkshell_name = player.linkshell

            for i, bagId in ipairs(LINKSHELL_BAG_IDS) do
                local bagName = LINKSHELL_BAG_NAMES_BY_ID[bagId]

                local bag = items[bagName]

                -- Only search bags that are enabled
                if bag and bag.enabled then
                    for localId, bagItem in pairs(bag) do

                        -- Only look at equipped linkshells
                        if type(bagItem) == 'table' and bagItem.status == 19 then
                            local ext = extdata.decode(bagItem)
                            if ext then
                                local info = {
                                    bagId = bagId,
                                    localId = localId,
                                    linkshellId = ext.linkshell_id,
                                    name = ext.name,
                                    type = ext.status,
                                    can_create = (ext.status == 'Pearlsack')
                                }

                                table.insert(result, info)

                                results_by_name[info.name] = info
                            end
                        end
                    end
                end
            end
        end
    end

    if #result == 0 then
        return
    end

    return result, results_by_name
end