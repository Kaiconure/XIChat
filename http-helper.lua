local HTTP_DLL_VERSION  = '11'
local HTTP_DLL_NAME     = 'windower_http%s':format(HTTP_DLL_VERSION)
local ADDON_PATH        = windower.addon_path:gsub('\\', '/'):gsub('//', '/')

package.cpath = package.cpath .. ';' .. (ADDON_PATH .. 'dll/?.dll')

local helper = {}

helper.http = require(HTTP_DLL_NAME)

---------------------------------------------------------------------------------
-- Turn a table of name/value header pairs into a JSON string for use
-- with an HTTP request.
--
helper.make_headers = function(headers_table)
    if type(headers_table) == 'table' then
        return json.stringify(headers_table)
    end
end

---------------------------------------------------------------------------------
-- Turns a Lua object into a JSON string for use as the payload
-- sent with an HTTP request.
--
helper.make_payload = function(payload_object)
    if payload_object then
        return json.stringify(payload_object)
    end
end

---------------------------------------------------------------------------------
-- Sends an HTTP GET request to the specified URL, with optional
-- headers to be included in the request.
--
helper.get = function(url, headers_table)
    local request = {
        url = url,
        method = 'GET',
        headers = helper.make_headers(headers_table)
    }

    return helper.send_request(request)
end

---------------------------------------------------------------------------------
-- Sends a generic HTTP request, fully configured based on the provided
-- request object.
--
helper.send_request = function(request)

    --print('url: %s':format(request.url))

    success, status, payload, headers = helper.http.send_http_request(request)

    return {
        success = success,
        status = status or -1,
        payload = payload,
        headers = headers
    }
end

return helper