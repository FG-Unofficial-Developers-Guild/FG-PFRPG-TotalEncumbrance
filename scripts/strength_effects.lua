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
--Argument: databasenode nodeWin representing effects or PC sheet
--Return: nodeEffects and nodePC databasenodes if provided with either. If input is neither, return what it sees.
local function nodeConcierge(nodeWin)
	local nodeEffects
	local nodePC
	local sPlayerID

	if nodeWin.getChild('...').getName() == 'effects' then
		nodeEffects = nodeWin.getChild('...')
		sPlayerID = nodeEffects.getParent().getName()
		nodePC = nodeEffects.getChild('.....').getChild('charsheet').getChild(sPlayerID)
		rActor = ActorManager.getActor('pc', nodePC)
		rActor.sCTNode = nodeEffects.getChild('..').getPath()
		rActor.sCreatureNode = nodePC.getPath()
	elseif nodeWin.getName() == 'effects' then
		nodeEffects = nodeWin
		sPlayerID = nodeEffects.getParent().getName()
		nodePC = nodeEffects.getChild('.....').getChild('charsheet').getChild(sPlayerID)
		rActor = ActorManager.getActor('pc', nodePC)
		rActor.sCTNode = nodeEffects.getChild('..').getPath()
	elseif nodeWin.getParent().getName() == 'charsheet' then
		nodePC = nodeWin
		sPlayerID = nodeWin.getName()
		nodeEffects = nodePC.getChild('...').getChild('combattracker').getChild('list').getChild(sPlayerID).getChild('effects')
		rActor = ActorManager.getActor('pc', nodePC)
		rActor.sCTNode = nodeEffects.getChild('..').getPath()
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
	end

	return nodeEffects, nodePC, rActor
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode nodeWin representing effects or label
function applyStrengthEffects(nodeWin)
	local nodeEffects, nodePC, rActor = nodeConcierge(nodeWin)

	local nEffectMod = getEffectsBonus(rActor, 'strength')

	Debug.chat('nEffectMod: ',nEffectMod)
	Debug.chat(nodePC)

	DB.setValue(nodePC, 'encumbrance.strbonusfromeffects', 'number', nEffectMod)

	local nTotalEncStrAdj = combineSTRCarryModifiers(nodePC, nEffectMod)

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

	local nEffectMod, nAbilityEffects = EffectManager35E.getEffectsBonus(rActor, 'STR', true)

	if EffectManager35E.hasEffectCondition(rActor, "Exhausted") then
		nEffectMod = nEffectMod - 6
		nAbilityEffects = nAbilityEffects + 1
	elseif EffectManager35E.hasEffectCondition(rActor, "Fatigued") then
		nEffectMod = nEffectMod - 2
		nAbilityEffects = nAbilityEffects + 1
	end

	return nEffectMod
end

function combineSTRCarryModifiers(nodePC, nEffectMod)
	local nodeEffects, nodePC = nodeConcierge(nodePC)

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