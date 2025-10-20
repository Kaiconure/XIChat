-- ========================================================================= --
-- IMPORTS
--  Imports are ways to leverage code that has already been written ("libraries"),
--  either by us or by others. In this case, the imports all come from the standard
--  Windower library folder at: Windower4/addons/libs
-- ========================================================================= --

---------------------------------------------------------------------
-- Our own imports go here

require('addon-info')

---------------------------------------------------------------------
-- Imports of standard Windower things go here

require('sets')         -- Gives us some extra helpers for finding specific elements within a set

resources   = require('resources')  -- Provides data on many different game object types
files       = require('files')      -- Lets us work with files
json        = require('jsonlua')    -- Lets us work with JSON
config      = require('config')     -- Gives us the ability to easily read and write standard Windower config files
extdata     = require('extdata')    -- Get extended resource information

socket = {}

http = require('http-helper')

require('main')
require('command-handlers')
require('event-handlers')

settings_manager    = require('settings-manager')
message_queue       = require('message-queue')

-- ========================================================================= --
-- EVENT REGISTRATION
-- ========================================================================= --

windower.register_event('load', addon_onLoad)
windower.register_event('unload', addon_onUnload)
windower.register_event('login', addon_onLogin)
windower.register_event('logout', addon_onLogout)
windower.register_event('linkshell change', addon_onLinkshellChange)
windower.register_event('zone change', addon_onZoneChange)
windower.register_event('examined', addon_onExamined)
windower.register_event('emote', addon_onEmote)
windower.register_event('incoming text', addon_onIncomingText)
windower.register_event('incoming chunk', addon_onIncomingChunk)
windower.register_event('addon command', addon_onAddonCommand)