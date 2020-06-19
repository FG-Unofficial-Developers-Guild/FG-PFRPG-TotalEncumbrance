--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	recalcCarryWeight()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', getStrEffectsBonus)
	DB.addHandler(DB.getPath(getDatabaseNode(), "abilities.strength.score"), "onUpdate", recalcCarryWeight)
	DB.addHandler(DB.getPath(getDatabaseNode(), "size"), "onUpdate", recalcCarryWeight)
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.stradj"), "onUpdate", recalcCarryWeight)
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.manualstradj"), "onUpdate", recalcCarryWeight)
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.carrymult"), "onUpdate", recalcCarryWeight)
end

function onClose()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', getStrEffectsBonus)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "abilities.strength.score"), "onUpdate", recalcCarryWeight)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "size"), "onUpdate", recalcCarryWeight)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.stradj"), "onUpdate", recalcCarryWeight)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.manualstradj"), "onUpdate", recalcCarryWeight)
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.carrymult"), "onUpdate", recalcCarryWeight)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeField representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleCombineCarryModifiersArgs(node)
	local rActor

	if node.getName() == 'effects' then
		rActor = ActorManager.getActor('pc', node.getParent())
	elseif node.getParent().getName() == 'charsheet' then
		rActor = ActorManager.getActor('pc', node)
		nodePC = node
	else
		Debug.chat('Node error. Unrecognized Node '..node.getPath())
	end

	Debug.chat(rActor)
	
	return nodePC, rActor
end

function getStrEffectsBonus(node)
	local nodePC, rActor = handleCombineCarryModifiersArgs(node)
	local nEffectMod = getEffectsBonus(rActor, 'strength')
	local nManualStrAdj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local tStrAdj = {}
	local nStrAdjToSet = 0

	if nEffectMod and OptionsManager.isOption('CARRY_CAPACITY_FROME_FFECTS', 'on') then -- if carrying capacity penalties from effects are enabled in options
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

function recalcCarryWeight()
	local nodeChar = getDatabaseNode()

	local nHeavy = 0
	local nStrength = DB.getValue(nodeChar, "abilities.strength.score", 10)
	nStrength = nStrength + DB.getValue(nodeChar, "encumbrance.stradj", 0)
	nStrength = nStrength + DB.getValue(nodeChar, "encumbrance.strbonusfromeffects", 0)
	if nStrength > 0 then
		if nStrength <= 10 then
			nHeavy = nStrength * 10
		else
			nHeavy = 1.25 * math.pow(2, math.floor(nStrength / 5)) * math.floor((20 * math.pow(2, math.fmod(nStrength, 5) / 5)) + 0.5)
		end
	end
	
	nHeavy = nHeavy * DB.getValue(nodeChar, "encumbrance.carrymult", 1)
	
	local nLight = math.floor(nHeavy / 3)
	local nMedium = math.floor((nHeavy / 3) * 2)
	local nLiftOver = nHeavy
	local nLiftOff = nHeavy * 2
	local nPushDrag = nHeavy * 5
	
	local nSize = ActorManager2.getSize(ActorManager.getActor("pc", nodeChar))
	if (nSize < 0) then
		local nMult = 0
		if (nSize == -1) then
			nMult = 0.75
		elseif (nSize == -2) then
			nMult = 0.5
		elseif (nSize == -3) then
			nMult = .25
		elseif (nSize == -4) then
			nMult = .125
		end
			
		nLight = math.floor(((nLight * nMult) * 100) + 0.5) / 100
		nMedium = math.floor(((nMedium * nMult) * 100) + 0.5) / 100
		nHeavy = math.floor(((nHeavy * nMult) * 100) + 0.5) / 100
		nLiftOver = math.floor(((nLiftOver * nMult) * 100) + 0.5) / 100
		nLiftOff = math.floor(((nLiftOff * nMult) * 100) + 0.5) / 100
		nPushDrag = math.floor(((nPushDrag * nMult) * 100) + 0.5) / 100
	elseif (nSize > 0) then
		local nMult = math.pow(2, nSize)
		
		nLight = nLight * nMult
		nMedium = nMedium * nMult
		nHeavy = nHeavy * nMult
		nLiftOver = nLiftOver * nMult
		nLiftOff = nLiftOff * nMult
		nPushDrag = nPushDrag * nMult
	end

	DB.setValue(nodeChar, "encumbrance.lightload", "number", nLight)
	DB.setValue(nodeChar, "encumbrance.mediumload", "number", nMedium)
	DB.setValue(nodeChar, "encumbrance.heavyload", "number", nHeavy)
	DB.setValue(nodeChar, "encumbrance.liftoverhead", "number", nLiftOver)
	DB.setValue(nodeChar, "encumbrance.liftoffground", "number", nLiftOff)
	DB.setValue(nodeChar, "encumbrance.pushordrag", "number", nPushDrag)
end