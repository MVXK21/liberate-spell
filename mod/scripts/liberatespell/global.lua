-- Liberate Spell: decides whether the target can be freed and hands the player
-- a temporary token that unlocks the "go free" dialogue choice.
local world = require('openmw.world')
local types = require('openmw.types')

local TOKEN_ID = 'liberate_token'
local TOKEN_LIFETIME = 60 -- seconds of game time (pauses while in menus/dialogue)

-- Slaves whose freedom is tied to a quest. Free them the normal way.
local EXCLUDED = {
    ['eleedal_lei'] = true,    -- Abebaal slave rebellion
    ['dahleena'] = true,       -- Caldera mine disruption
    ['hides_his_foot'] = true, -- Twin Lamps escort
    ['llaals ores'] = true,    -- Twin Lamps
}

local tokenTimeLeft = 0
local tokenOwner = nil

local function message(player, text)
    player:sendEvent('LiberateSpell_Message', { text = text })
end

-- Returns the NPC's slaveStatus, or nil if its mwscript has no such variable.
-- The name must be lowercase: OpenMW 0.51 stores local names in lowercase and
-- its existence check is case-sensitive, so 'slaveStatus' reads as missing.
local function slaveStatus(npc)
    local script = world.mwscript.getLocalScript(npc)
    if not script then
        return nil
    end
    return script.variables.slavestatus
end

local function tokenCount(player)
    return types.Actor.inventory(player):countOf(TOKEN_ID)
end

local function removeTokens(player)
    for _, item in ipairs(types.Actor.inventory(player):findAll(TOKEN_ID)) do
        item:remove()
    end
end

local function onHit(data)
    local npc, caster = data.npc, data.caster
    if not (npc and npc:isValid() and caster and caster:isValid()) then
        return
    end
    if caster.type ~= types.Player then
        return
    end

    local status = slaveStatus(npc)
    if status == nil then
        message(caster, 'There are no bonds here for your magic to break.')
        return
    end
    if EXCLUDED[npc.recordId] then
        message(caster, 'Something stronger than enchantment binds this one. They must be freed another way.')
        return
    end
    if status >= 3 then
        message(caster, 'This one is already free.')
        return
    end
    if types.Actor.isDead(npc) then
        return
    end

    if tokenCount(caster) == 0 then
        world.createObject(TOKEN_ID, 1):moveInto(types.Actor.inventory(caster))
    end
    tokenTimeLeft = TOKEN_LIFETIME
    tokenOwner = caster
    message(caster, 'The bracers\' enchantment wavers. Speak to the slave to set them free.')
end

local function onUpdate(dt)
    if tokenTimeLeft <= 0 then
        return
    end
    tokenTimeLeft = tokenTimeLeft - dt
    if tokenTimeLeft <= 0 and tokenOwner and tokenOwner:isValid() then
        if tokenCount(tokenOwner) > 0 then
            removeTokens(tokenOwner)
            message(tokenOwner, 'The Liberate spell fades.')
        end
        tokenOwner = nil
    end
end

local function onSave()
    return { tokenTimeLeft = tokenTimeLeft, tokenOwner = tokenOwner }
end

local function onLoad(data)
    if data then
        tokenTimeLeft = data.tokenTimeLeft or 0
        tokenOwner = data.tokenOwner
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        LiberateSpell_Hit = onHit,
    },
}
