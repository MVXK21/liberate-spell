-- Liberate Spell: shows the mod's messages to the player.
-- The spell itself is sold by Imperial Cult spell merchants (see npc.lua).
local ui = require('openmw.ui')

return {
    eventHandlers = {
        LiberateSpell_Message = function(data)
            ui.showMessage(data.text)
        end,
    },
}
