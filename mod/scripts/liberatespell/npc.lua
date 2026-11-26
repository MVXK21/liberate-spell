-- Liberate Spell: runs on every NPC and reports when the Liberate effect lands on it.
local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')

local EFFECT_ID = 'liberate_effect'
local CHECK_INTERVAL = 0.25

local timer = 0
local handled = {} -- activeSpellIds already reported

local function hasLiberate(spell)
    for _, effect in pairs(spell.effects) do
        if effect.id == EFFECT_ID then
            return true
        end
    end
    return false
end

local function onUpdate(dt)
    timer = timer + dt
    if timer < CHECK_INTERVAL then
        return
    end
    timer = 0

    local seen = {}
    for _, spell in pairs(types.Actor.activeSpells(self)) do
        if hasLiberate(spell) then
            local id = spell.activeSpellId
            seen[id] = true
            if not handled[id] then
                handled[id] = true
                core.sendGlobalEvent('LiberateSpell_Hit', { npc = self.object, caster = spell.caster })
            end
        end
    end
    -- forget spells that have ended
    for id in pairs(handled) do
        if not seen[id] then
            handled[id] = nil
        end
    end
end

-- Imperial Cult members who sell spells get Liberate added to their stock.
local SPELL_ID = 'liberate_spell'
local SELLER_FACTION = 'imperial cult'

local function sellsSpells()
    local services = types.NPC.record(self).servicesOffered
    return services and services.Spells
end

local function inSellerFaction()
    for _, factionId in pairs(types.NPC.getFactions(self)) do
        if factionId:lower() == SELLER_FACTION then
            return true
        end
    end
    return false
end

local function stockSpell()
    if not (sellsSpells() and inSellerFaction()) then
        return
    end
    local spells = types.Actor.spells(self)
    for _, spell in pairs(spells) do
        if spell.id == SPELL_ID then
            return
        end
    end
    spells:add(SPELL_ID)
end

return {
    engineHandlers = {
        onActive = stockSpell,
        onUpdate = onUpdate,
    },
}
