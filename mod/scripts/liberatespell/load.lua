-- Liberate Spell: creates the Liberate magic effect and spell at game load.
local content = require('openmw.content')

local EFFECT_ID = 'liberate_effect'
local SPELL_ID = 'liberate_spell'

-- Based on Open (Alteration) so it borrows its icon, sounds and visuals.
-- The effect itself does nothing in the engine; the NPC script notices it.
content.magicEffects.records[EFFECT_ID] = {
    template = content.magicEffects.records['open'],
    name = 'Liberate',
    description = 'Weakens the enchantment binding slave bracers, allowing the slave to be set free.',
    hasDuration = true,
    hasMagnitude = false,
    harmful = false,
    onSelf = false,
    onTouch = true,
    onTarget = true,
    allowsSpellmaking = true,
    allowsEnchanting = true,
}

content.spells.records[SPELL_ID] = {
    name = 'Liberate',
    type = content.spells.TYPE.Spell,
    cost = 15,
    isAutocalc = false,
    effects = {
        {
            id = EFFECT_ID,
            range = content.RANGE.Target,
            area = 0,
            duration = 5,
            magnitudeMin = 0,
            magnitudeMax = 0,
        },
    },
}
