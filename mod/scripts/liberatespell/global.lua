-- Liberate Spell: decides whether the target can be freed and, if so, turns on
-- the global variable that unlocks the "go free" dialogue choice for a while.
local world = require('openmw.world')
local types = require('openmw.types')

-- Defined in LiberateSpell.esp. 1 while the spell is in effect, 0 otherwise.
-- The dialogue resets it to 0 when a slave is freed.
local ACTIVE_GLOBAL = 'liberatespell_active'
-- Real seconds of unpaused play (the timer stops in menus and dialogue).
-- This is not the in-game clock, which runs much faster.
local ACTIVE_SECONDS = 60

-- Slaves whose freedom is tied to a quest. Free them the normal way.
-- Keep in sync with EXCLUDED in tools/build_esp.py.
local EXCLUDED = {
    ['eleedal_lei'] = true,    -- Abebaal slave rebellion
    ['dahleena'] = true,       -- Caldera mine disruption
    ['hides_his_foot'] = true, -- Twin Lamps escort
    ['llaals ores'] = true,    -- Twin Lamps
}

local timeLeft = 0
local caster = nil

local function message(player, text)
    player:sendEvent('LiberateSpell_Message', { text = text })
end

local function globals()
    return world.mwscript.getGlobalVariables()
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

local function onHit(data)
    local npc, from = data.npc, data.caster
    if not (npc and npc:isValid() and from and from:isValid()) then
        return
    end
    if from.type ~= types.Player then
        return
    end

    local status = slaveStatus(npc)
    if status == nil then
        message(from, 'There are no bonds here for your magic to break.')
        return
    end
    if EXCLUDED[npc.recordId] then
        message(from, 'Something stronger than enchantment binds this one. They must be freed another way.')
        return
    end
    if status >= 3 then
        message(from, 'This one is already free.')
        return
    end
    if types.Actor.isDead(npc) then
        return
    end

    globals()[ACTIVE_GLOBAL] = 1
    timeLeft = ACTIVE_SECONDS
    caster = from
    message(from, 'The bracers\' enchantment wavers. Speak to the slave to set them free.')
end

local function onUpdate(dt)
    if timeLeft <= 0 then
        return
    end
    timeLeft = timeLeft - dt
    if timeLeft > 0 then
        return
    end
    local vars = globals()
    -- Still 1 means nobody was freed in time (freeing resets it to 0).
    if vars[ACTIVE_GLOBAL] == 1 and caster and caster:isValid() then
        message(caster, 'The Liberate spell fades.')
    end
    vars[ACTIVE_GLOBAL] = 0
    caster = nil
end

local function onSave()
    return { timeLeft = timeLeft, caster = caster }
end

local function onLoad(data)
    if data then
        timeLeft = data.timeLeft or 0
        caster = data.caster
    end
    -- A save made while the spell was active keeps the global at 1; if the
    -- timer is gone (for example after a 1.0.0 save), turn it off.
    if timeLeft <= 0 then
        globals()[ACTIVE_GLOBAL] = 0
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
