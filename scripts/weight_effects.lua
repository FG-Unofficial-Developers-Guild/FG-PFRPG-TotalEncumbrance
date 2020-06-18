--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', combineCarryModifiers)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeField representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleApplyStrengthEffectsArgs(node)

	if node.getName() == 'effects' then
	elseif node.getParent().getName() == 'charsheet' then
		nodePC = node
	else
		Debug.chat('Node error. Unrecognized Node '..node.getPath())
	end

	local rActor = ActorManager.getActor('pc', nodePC)

	return nodePC, rActor
end

function combineCarryModifiers(node)
	local nodePC, rActor = handleApplyStrengthEffectsArgs(node)
	local nEffectMod = getEffectsBonus(rActor, 'strength')
	local nManualStrAdj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local tStrAdj = {}
	local nStrAdjToSet = 0

	if nEffectMod then
		table.insert(tStrAdj, nEffectMod)
	end
	if nManualStrAdj then
		table.insert(tStrAdj, nManualStrAdj)
	end

	nStrAdjToSet = LibTotalEncumbrance.tableSum(tStrAdj)

	DB.setValue(nodePC, 'encumbrance.stradj', 'number', nStrAdjToSet)
	DB.setValue(nodePC, 'encumbrance.strbonusfromeffects', 'number', nEffectMod)
end

--	Determine the total bonus to STR from effects
function getEffectsBonus(rActor, sAbility)
	if not rActor or not sAbility then
		return 0, 0
	end

	local nEffectMod = EffectManager35E.getEffectsBonus(rActor, 'STR', true)

	if EffectManager35E.hasEffectCondition(rActor, "Exhausted") then
		nEffectMod = nEffectMod - 6
	elseif EffectManager35E.hasEffectCondition(rActor, "Fatigued") then
		nEffectMod = nEffectMod - 2
	end

	return nEffectMod
end