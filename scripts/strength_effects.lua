--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('charsheet.*.effects.*.label'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects.*.isactive'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects'), 'onChildDeleted', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeWin representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleApplyStrengthEffectsArgs(nodeWin)
	local nodeEffects

	if nodeWin.getName() == 'effects' then
		nodeEffects = nodeWin
	else
		nodeEffects = nodeWin.getChild('...') -- 3 dots or 2 for the onUpdate call on label / isactive?
	end

	return nodeEffects
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode nodeWin representing effects or label
function applyStrengthEffects(nodeWin)
	local nodeEffects = handleApplyStrengthEffectsArgs(nodeWin)
	
	Debug.chat(nodeEffects)

	local rActor = ActorManager.getActor('pc', nodeEffects)
	Debug.chat(rActor)
	nAbility = ActorManager2.getAbilityEffectsBonus(rActor, 'strength')
	Debug.chat('effects mod',nAbility)
	local nEffectMod, nAbilityEffects = EffectManager35E.getEffectsBonus(rActor, sAbilityEffect, true)
	Debug.chat('nEffectMod and nAbilityEffects',nEffectMod, nAbilityEffects)

--	DB.setValue(nodeEffects.getParent(), 'encumbrance.manualstradj') -- Just to write some code without knowing the xml stuff
--	DB.setValue(nodeEffects.getParent(), 'encumbrance.stradj_fromeffects') -- Just to write some code without knowing the xml stuff
end

function combineSTRCarryModifiers(nodeWin)
	Debug.chat('combine str!')

	if nodeWin.getParent().getName() == 'encumbrance' then
		nodePC = nodeWin
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
	end

	local light = DB.getValue(nodePC, 'encumbrance.lightload')
	local medium = DB.getValue(nodePC, 'encumbrance.mediumload')

end