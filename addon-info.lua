-- ========================================================================= --
-- ADDON INFORMATION
--  This is where we provide information about the addon. Note that you should
--  change the version, name, shortname, and author when you decide to create
--  a new addon. You should also move the addon into a folder which matches the
--  addon name, and rename this Lua file to match that as well.
-- ========================================================================= --

---------------------------------------------------------------------
-- This is optional information about the addon, which Windower
-- will show in the console when loaded.
ADDON_VERSION    = '1.2.6'
ADDON_NAME       = 'XIChat'
ADDON_SHORT_NAME = 'xic'
ADDON_AUTHOR     = '@Kaiconure'
ADDON_COMMANDS   = {ADDON_SHORT_NAME, ADDON_NAME}

---------------------------------------------------------------------
-- This is where we send the above info to Windower. You shouldn't
-- ever have to modify the following five lines.
_addon.name         = ADDON_NAME
_addon.version      = ADDON_VERSION
_addon.shortName    = ADDON_SHORT_NAME
_addon.author       = ADDON_AUTHOR
_addon.commands     = ADDON_COMMANDS