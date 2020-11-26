-- 
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	Locate the effects node within the relevant player character's node within combattracker
--	@param node the databasenode passed along when this file is initialized
--	@return nodeCharCT path to this PC's databasenode "effects" in the combat tracker
local function getNodeCharCT(node)
	local rActor
	local nodeCharCT
	if node.getParent().getName() == 'charsheet' then
		rActor = ActorManager.getActor('pc', node)
		nodeCharCT = DB.findNode(rActor['sCTNode'])
	elseif node.getChild('...').getName() == 'charsheet' then
		rActor = ActorManager.getActor('pc', node.getParent())
		nodeCharCT = DB.findNode(rActor['sCTNode'])
	elseif node.getChild('....').getName() == 'charsheet' then -- this might not be necessary
		rActor = ActorManager.getActor('ct', node.getChild('...'))
		nodeCharCT = DB.findNode(rActor['sCTNode'])
	end

	return nodeCharCT
end

function onInit()
	local node = getDatabaseNode()

	onEncumbranceChanged() -- this is now handled by char_invlist_TE

	local nodeCharCT = getNodeCharCT(node)

	DB.addHandler(DB.getPath(nodeCharCT, 'effects.*.label'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(nodeCharCT, 'effects.*.isactive'), 'onUpdate', onEffectChanged)
	DB.addHandler(DB.getPath(nodeCharCT, 'effects'), 'onChildDeleted', onEffectRemoved)
	DB.addHandler(DB.getPath(node, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(node, 'size'), 'onUpdate', onSizeChanged)
	DB.addHandler(DB.getPath(node, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
	DB.addHandler(DB.getPath(node, 'encumbrance.carrymult'), 'onUpdate', onEncumbranceChanged)
	DB.addHandler(DB.getPath('options.ENCUMBRANCE_UNIT'), 'onUpdate', onEncumbranceChanged)
end

function onClose()
	local node = getDatabaseNode()
	local nodeCharCT = getNodeCharCT(node)

	DB.removeHandler(DB.getPath(nodeCharCT, 'effects.*.label'), 'onUpdate', onEffectChanged)
	DB.removeHandler(DB.getPath(nodeCharCT, 'effects.*.isactive'), 'onUpdate', onEffectChanged)
	DB.removeHandler(DB.getPath(nodeCharCT, 'effects'), 'onChildDeleted', onEffectRemoved)
	DB.removeHandler(DB.getPath(node, 'abilities.strength'), 'onChildUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(node, 'size'), 'onUpdate', onSizeChanged)
	DB.removeHandler(DB.getPath(node, 'encumbrance.stradj'), 'onUpdate', onStrengthChanged)
	DB.removeHandler(DB.getPath(node, 'encumbrance.carrymult'), 'onUpdate', onEncumbranceChanged)
	DB.removeHandler(DB.getPath('options.ENCUMBRANCE_UNIT'), 'onUpdate', onEncumbranceChanged)
end

function onEffectChanged(node)
	onStrengthChanged()
end

function onEffectRemoved(node)
	onStrengthChanged()
end

---	Determine the total bonus to carrying capacity from effects STR or CARRY
--	@param rActor a table containing relevant paths and information on this PC
--	@return nStrEffectMod the PC's current strength score after all bonuses are applied
local function getStrEffectBonus(rActor)
	if not rActor then
		return 0
	end

	local nStrEffectMod = 0
	
	if EffectManagerTE.hasEffectCondition(rActor, 'Exhausted') then
		nStrEffectMod = nStrEffectMod - 6
	elseif EffectManagerTE.hasEffectCondition(rActor, 'Fatigued') then
		nStrEffectMod = nStrEffectMod - 2
	end

	if EffectManagerTE.hasEffectCondition(rActor, 'Paralyzed') then
		nStrEffectMod = -1 * nStrEffectMod
	end

	local nStrEffects = EffectManagerTE.getEffectsBonus(rActor, 'STR', true)
	if nStrEffects and not DataCommon.isPFRPG() then nStrEffectMod = nStrEffectMod + nStrEffects end

	local nCarryBonus = EffectManagerTE.getEffectsBonus(rActor, 'CARRY', true)
	if nCarryBonus then
		nStrEffectMod = nStrEffectMod + nCarryBonus
	end

	return nStrEffectMod
end

function onStrengthChanged()
	onEncumbranceChanged()
end

function onSizeChanged()
	onEncumbranceChanged()
end

function onEncumbranceChanged()
	local nodeChar
	local rActor

	if getDatabaseNode().getParent().getName() == 'charsheet' then
		nodeChar = getDatabaseNode()
		rActor = ActorManager.getActor('pc', nodeChar)
	elseif getDatabaseNode().getName() == 'effects' then
		rActor = ActorManager.getActor('ct', getDatabaseNode())
		nodeChar = DB.findNode(rActor['sCreatureNode'])
	end

	local nHeavy = 0
	local nStrength = DB.getValue(nodeChar, 'abilities.strength.score', 10)
	local nStrengthDamage = DB.getValue(nodeChar, 'abilities.strength.damage', 0)
	if nStrengthDamage and DataCommon.isPFRPG() then nStrengthDamage = 0 end

	if DB.getValue(nodeChar, 'encumbrance.stradj', 0) == 0 and CharManager.hasTrait(nodeChar, 'Muscle of the Society') then
		DB.setValue(nodeChar, 'encumbrance.stradj', 2)
	end

	local nStrengthAdj = DB.getValue(nodeChar, 'encumbrance.stradj', 0)

	nStrength = nStrength + nStrengthAdj
	
	local nStrEffectMod = getStrEffectBonus(rActor)
	DB.setValue(nodeChar, 'encumbrance.strbonusfromeffects', 'number', nStrEffectMod)

--	modify onEncumbranceChanged to include STR effects in calculating carrying capacity (only if CARRY_CAPACITY_FROM_EFFECTS is enabled in options)
--	if OptionsManager.isOption('CARRY_CAPACITY_FROM_EFFECTS', 'on') then
		nStrength = nStrength + nStrEffectMod - nStrengthDamage
--	end
	
	if nStrength > 0 then
		if nStrength <= 10 then
			nHeavy = nStrength * 10
		else
			nHeavy = 1.25 * math.pow(2, math.floor(nStrength / 5)) * math.floor((20 * math.pow(2, math.fmod(nStrength, 5) / 5)) + 0.5)
		end
	end
	
	nHeavy = math.floor(nHeavy * DB.getValue(nodeChar, 'encumbrance.carrymult', 1) * TEGlobals.getEncWeightUnit())

	-- Check for ant haul spell attached to PC on combat tracker. If found, triple their carrying capacity.
	if EffectManagerTE.hasEffectCondition(rActor, 'Ant Haul') then
		nHeavy = nHeavy * 3
	end
	
	local nLight = math.floor(nHeavy / 3)
	local nMedium = math.floor((nHeavy / 3) * 2)
	local nLiftOver = nHeavy
	local nLiftOff = nHeavy * 2
	local nPushDrag = nHeavy * 5

	local nSize = ActorManager2.getSize(ActorManager.getActor('pc', nodeChar))
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

	DB.setValue(nodeChar, 'encumbrance.lightload', 'number', nLight)
	DB.setValue(nodeChar, 'encumbrance.mediumload', 'number', nMedium)
	DB.setValue(nodeChar, 'encumbrance.heavyload', 'number', nHeavy)
	DB.setValue(nodeChar, 'encumbrance.liftoverhead', 'number', nLiftOver)
	DB.setValue(nodeChar, 'encumbrance.liftoffground', 'number', nLiftOff)
	DB.setValue(nodeChar, 'encumbrance.pushordrag', 'number', nPushDrag)
	
	-- This helps with automatically changing the weight units when the option is toggled
	CoinsWeight.onCoinsValueChanged(nodeChar)
	CharManagerTE.updateEncumbrance(nodeChar)
end
