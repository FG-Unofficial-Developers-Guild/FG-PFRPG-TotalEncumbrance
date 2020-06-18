--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects.*.isactive'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('combattracker.list.*.effects.*.label'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildDeleted', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode node representing effects or PC sheet
--Return: nodeEffects and nodePC databasenodes if provided with either. If input is neither, return what it sees.
local function nodeConcierge(node)
	local rActor = ActorManager.getActor('pc', node)
	local nodePC
	local nodeEffects
	local nodeCT
	local sPlayerID

	if rActor.sCreatureNode then
		nodePC = rActor.sCreatureNode
	end
	if rActor.sCTNode then
		nodeEffects = DB.getPath(rActor.sCTNode)..'.effects'
	end

	return nodeEffects, nodePC, rActor
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode node representing effects or label
function applyStrengthEffects(node)
	local nodeEffects, nodePC = nodeConcierge(node)
	local rActor = ActorManager.getActor('pc', nodePC)
	rActor.sCTNode = nodeEffects.getChild('..').getPath()

	local nEffectMod = getEffectsBonus(rActor, 'strength')

	DB.setValue(nodePC, 'encumbrance.strbonusfromeffects', 'number', nEffectMod)

	local nTotalEncStrAdj = combineSTRCarryModifiers(nodePC, nodeEffects, nEffectMod)

	if nTotalEncStrAdj == nil then
		DB.setValue(nodePC, 'encumbrance.stradj', 'number', 0)
	end
	if nTotalEncStrAdj ~= nil then
		DB.setValue(nodePC, 'encumbrance.stradj', 'number', nTotalEncStrAdj)
	end
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

function combineSTRCarryModifiers(nodePC, nodeEffects, nEffectMod)
	local nManualStrAdj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local tStrAdj = {}

	if nManualStrAdj ~= nil and nManualStrAdj ~= 0 then
		table.insert(tStrAdj, nManualStrAdj)
	end
	if nEffectMod ~= nil and nEffectMod ~= 0 then
		table.insert(tStrAdj, nEffectMod)
	end

	local nTotalEncStrAdj = TotalEncumbranceLib.tableSum(tStrAdj)

	return nTotalEncStrAdj
end