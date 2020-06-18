--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeWin representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleApplyStrengthEffectsArgs(nodeWin)
	local nodeEffects

	if nodeWin.getName() == 'effects' then
		nodeEffects = nodeWin
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
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
	if nodeWin.getParent().getName() == 'charsheet' then
		nodePC = nodeWin
	elseif nodeWin.getName() == 'encumbrance' then
		nodePC = nodeWin.getParent()
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
	end

	local manualstradj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local strbonusfromeffects = DB.getValue(nodePC, 'encumbrance.strbonusfromeffects')

	Debug.chat('manualstradj,strbonusfromeffects',manualstradj,strbonusfromeffects)

	if totalencstradj ~= nil then
		DB.setValue(nodePC, 'encumbrance.encstradj', totalencstradj)
	end
end