-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath('charsheet.*.hp'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.wounds'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.speed.base'), 'onUpdate', onSpeedChanged)
	end
end

function onHealthChanged(node)
	calcItemArmorClass(node.getParent())
end

function onSpeedChanged(node)
	calcItemArmorClass(node.getChild('...'))
end

--	Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--	Argument: number light is medium encumbrance threshold for PC
--	Argument: number medium is heavy encumbrance threshold for PC
--	Argument: number total is current total encumbrance for PC
--	Return: number for max stat penalty based solely on encumbrance (max stat, check penalty)
--	Return: number for check penalty penalty based solely on encumbrance (max stat, check penalty)
local function encumbrancePenalties(nodeChar)
	local light = DB.getValue(nodeChar, 'encumbrance.lightload', 0)
	local medium = DB.getValue(nodeChar, 'encumbrance.mediumload', 0)
	local total = DB.getValue(nodeChar, 'encumbrance.total', 0)

	if total > medium then -- heavy load
		DB.setValue(nodeChar, 'encumbrance.encumbrancelevel', 'number', 2)
		return TEGlobals.nHeavyMaxStat, TEGlobals.nHeavyCheckPenalty
	elseif total > light then -- medium load
		DB.setValue(nodeChar, 'encumbrance.encumbrancelevel', 'number', 1)
		return TEGlobals.nMediumMaxStat, TEGlobals.nMediumCheckPenalty
	else -- light load
		DB.setValue(nodeChar, 'encumbrance.encumbrancelevel', 'number', 0)
		return nil, nil
	end
end

---	This function checks for special abilities.
local function hasSpecialAbility(nodeChar, sSpecAbil)
	if not sSpecAbil then
		return false
	end

	local sLowerSpecAbil = string.lower(sSpecAbil)
	
	for _,vNode in pairs(DB.getChildren(nodeChar, 'specialabilitylist')) do
		if string.match(StringManager.trim(DB.getValue(vNode, 'name', ''):lower()), sLowerSpecAbil .. ' %d', 1) then
			return true
		end
	end
	
	return false
end

--	Summary: Determine the total bonus to character's speed from effects
--	Argument: rActor containing the PC's charsheet and combattracker nodes
--	Return: total bonus to speed from effects formatted as 'SPEED: n' in the combat tracker
local function getSpeedEffects(nodeChar)
	local rActor = ActorManager.getActor('pc', nodeChar)

	if not rActor then
		return 0, false
	end

	local bSpeedHalved = false
	local bSpeedZero = false

	if
		EffectManagerTE.hasEffectCondition(rActor, 'Exhausted')
		or EffectManagerTE.hasEffectCondition(rActor, 'Entangled')
	then
		bSpeedHalved = true
	end

	if
		EffectManagerTE.hasEffectCondition(rActor, 'Grappled')
		or EffectManagerTE.hasEffectCondition(rActor, 'Paralyzed')
		or EffectManagerTE.hasEffectCondition(rActor, 'Petrified')
		or EffectManagerTE.hasEffectCondition(rActor, 'Pinned')
	then
		bSpeedZero = true
	end

	--	Check if the character is disabled (at zero remaining hp)
	if DB.getValue(nodeChar, 'hp.total', 0) == DB.getValue(nodeChar, 'hp.wounds', 0) then
		bSpeedHalved = true
	end

	local nSpeedAdjFromEffects = EffectManagerTE.getEffectsBonus(rActor, 'SPEED', true)

	return nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero
end

function calcItemArmorClass(nodeChar)
	local nMainArmorTotal = 0
	local nMainShieldTotal = 0
	local nMainMaxStatBonus = 999
	local nMainCheckPenalty = 0
	local nMainSpellFailure = 0
	local nMainSpeed30 = 0
	local nMainSpeed20 = 0

	for _,vNode in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		if DB.getValue(vNode, 'carried', 0) == 2 then
			local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode)
			if bIsArmor then
				local bID = LibraryData.getIDState('item', vNode, true)
				
				local bIsShield = (sSubtypeLower == 'shield')
				if bIsShield then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0)
					end
				else
					if bID then
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0)
					end
							
					local nItemSpeed30 = DB.getValue(vNode, 'speed30', 0)
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30)
						else
							nMainSpeed30 = nItemSpeed30
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, 'speed20', 0)
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20)
						else
							nMainSpeed20 = nItemSpeed20
						end
					end
				end
					
				local nMaxStatBonus = DB.getValue(vNode, 'maxstatbonus', 0)
				if nMaxStatBonus > 0 then
					if not bIsShield and hasSpecialAbility(nodeChar, 'Armor Training') then

						if DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 15 then
							nMaxStatBonus = nMaxStatBonus + 4
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 11 then
							nMaxStatBonus = nMaxStatBonus + 3
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 7 then
							nMaxStatBonus = nMaxStatBonus + 2
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 3 then
							nMaxStatBonus = nMaxStatBonus + 1
						end
					end
					
					if nMaxStatBonus and nMainMaxStatBonus < 999 then nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus)
					else nMainMaxStatBonus = nMaxStatBonus
					end
				else
					for _,v in pairs(TEGlobals.tClumsyArmorTypes) do
						if string.find(string.lower(DB.getValue(vNode, 'name', 0)), string.lower(v)) then
							nMainMaxStatBonus = 0					
							break
						end
					end
				end
								
				local nCheckPenalty = DB.getValue(vNode, 'checkpenalty', 0)
				if nCheckPenalty < 0 then
					if not bIsShield and CharManager.hasTrait(nodeChar, 'Armor Expert') then
						nCheckPenalty = nCheckPenalty + 1
					end
					if not bIsShield and hasSpecialAbility(nodeChar, 'Armor Training') then
						if DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 15 then
							nCheckPenalty = nCheckPenalty + 4
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 11 then
							nCheckPenalty = nCheckPenalty + 3
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 7 then
							nCheckPenalty = nCheckPenalty + 2
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 3 then
							nCheckPenalty = nCheckPenalty + 1
						end
					end
					
					if nCheckPenalty < 0 then nMainCheckPenalty = nMainCheckPenalty + nCheckPenalty end
				end
				
				local nSpellFailure = DB.getValue(vNode, 'spellfailure', 0)
				if nSpellFailure > 0 then nMainSpellFailure = nMainSpellFailure + nSpellFailure end
			end
		end
	end

	--	Bring in encumbrance penalties
	local nEncMaxStatBonus, nEncCheckPenalty = encumbrancePenalties(nodeChar)
	if nEncMaxStatBonus then
		nMainMaxStatBonus = math.min(nMainMaxStatBonus, nEncMaxStatBonus)
		DB.setValue(nodeChar, 'encumbrance.maxstatbonusfromenc', 'number', nEncMaxStatBonus)
	else
		DB.setValue(nodeChar, 'encumbrance.maxstatbonusfromenc', 'number', nil)
	end
	if nEncCheckPenalty then
		nMainCheckPenalty = math.min(nMainCheckPenalty, nEncCheckPenalty)
		DB.setValue(nodeChar, 'encumbrance.checkpenaltyfromenc', 'number', nEncCheckPenalty)
	else
		DB.setValue(nodeChar, 'encumbrance.checkpenaltyfromenc', 'number', nil)
	end
	
	DB.setValue(nodeChar, 'ac.sources.armor', 'number', nMainArmorTotal)
	DB.setValue(nodeChar, 'ac.sources.shield', 'number', nMainShieldTotal)
	DB.setValue(nodeChar, 'encumbrance.armormaxstatbonus', 'number', nMainMaxStatBonus)

	if nMainMaxStatBonus < 999 or nMainCheckPenalty < 0 then
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 0)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 1)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end
	DB.setValue(nodeChar, 'encumbrance.armorcheckpenalty', 'number', nMainCheckPenalty)
	DB.setValue(nodeChar, 'encumbrance.spellfailure', 'number', nMainSpellFailure)

	local bApplySpeedPenalty = true
	if CharManager.hasTrait(nodeChar, 'Slow and Steady') then
		bApplySpeedPenalty = false
	end
	
	local nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero = getSpeedEffects(nodeChar)
	
	local nSpeedBase = DB.getValue(nodeChar, 'speed.base', 0)

	--compute speed including total encumberance speed penalty
	local tEncumbranceSpeed = TEGlobals.tEncumbranceSpeed
	local nSpeedTableIndex = nSpeedBase / 5

	nSpeedTableIndex = nSpeedTableIndex + 0.5 - (nSpeedTableIndex + 0.5) % 1

	local nSpeedPenaltyFromEnc = 0

	if tEncumbranceSpeed[nSpeedTableIndex] then
		nSpeedPenaltyFromEnc = tEncumbranceSpeed[nSpeedTableIndex] - nSpeedBase
	end

	local bApplySpeedPenalty = true

	if CharManager.hasTrait(nodeChar, 'Slow and Steady') then
		bApplySpeedPenalty = false
	end

	local nSpeedArmor = 0

	if bApplySpeedPenalty then
		if (nSpeedBase >= 30) and (nMainSpeed30 > 0) then
			nSpeedArmor = nMainSpeed30 - 30
		elseif (nSpeedBase < 30) and (nMainSpeed20 > 0) then
			nSpeedArmor = nMainSpeed20 - 20
		end
	
		local nEncumbranceLevel = DB.getValue(nodeChar, 'encumbrance.encumbrancelevel', 0)

		if nEncumbranceLevel >= 1 then
			if (nSpeedArmor ~= 0) and (nSpeedPenaltyFromEnc ~= 0)
			then
				nSpeedArmor = math.min(nSpeedPenaltyFromEnc, nSpeedArmor)
			elseif nSpeedPenaltyFromEnc then
				nSpeedArmor = nSpeedPenaltyFromEnc
			end
		end
	end
	
	DB.setValue(nodeChar, 'speed.armor', 'number', nSpeedArmor)
	local nSpeedTotal = nSpeedBase + nSpeedArmor + DB.getValue(nodeChar, 'speed.misc', 0) + DB.getValue(nodeChar, 'speed.temporary', 0) + nSpeedAdjFromEffects
	if bSpeedHalved then nSpeedTotal = nSpeedTotal / 2 elseif bSpeedZero then nSpeedTotal = 0 end
	DB.setValue(nodeChar, 'speed.total', 'number', nSpeedTotal)
end

function isWeightless(sItemName, nItemCarried)
	local tExtraPlanarContainers = {}
	table.insert(tExtraPlanarContainers, 'of holding')
	table.insert(tExtraPlanarContainers, 'portable hole')
	table.insert(tExtraPlanarContainers, 'efficient quiver')
	table.insert(tExtraPlanarContainers, 'handy haversack')
	for _,v in pairs(tExtraPlanarContainers) do
		if (not nItemCarried or (nItemCarried ~= 2)) and string.find(sItemName, v) then
			return true
		end
	end
end

function updateEncumbrance(nodeChar)
	local aExtraplanarContainers = {} -- this creates an array keyed to the names of any detected extraplanar storage containers
	for _,nodeItem in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local sItemName = string.lower(DB.getValue(nodeItem, 'name', ''))
		if isWeightless(sItemName) then
			aExtraplanarContainers[sItemName] = {['nodeItem'] = nodeItem, ['nTotal'] = 0}
		end
	end

	local nEncTotal = 0 -- this will cointain a running total of all items carried by the character
	
	for _,nodeItem in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local nItemCarried = DB.getValue(nodeItem, 'carried', 0)
		if nItemCarried ~= 0 then
			local nCount = DB.getValue(nodeItem, 'count', 0);
			local nWeight = DB.getValue(nodeItem, 'weight', 0);
			local sItemLoc = string.lower(DB.getValue(nodeItem, 'location', ''))
			
			if not isWeightless(sItemLoc, nItemCarried) then
				nEncTotal = nEncTotal + (nCount * nWeight)
			else
				if aExtraplanarContainers[sItemLoc] then
					aExtraplanarContainers[sItemLoc]['nTotal'] = aExtraplanarContainers[sItemLoc]['nTotal'] + (nCount * nWeight)
				end
			end
		end
	end
	
	for _,t in pairs(aExtraplanarContainers) do
		DB.setValue(t['nodeItem'], 'extraplanarcontents', 'number', t['nTotal'])
		
		local nItemCapacity = DB.getValue(t['nodeItem'], 'capacityweight', 0)
		if nItemCapacity > 0 then
			if not DB.getValue(t['nodeItem'], 'weightbak') then DB.setValue(t['nodeItem'], 'weightbak', 'number', DB.getValue(t['nodeItem'], 'weight', 0)) end
			if (t['nTotal'] > nItemCapacity) and DB.getValue(t['nodeItem'], 'weightbak') then
				local nHeavyWeight = t['nTotal'] - nItemCapacity + DB.getValue(t['nodeItem'], 'weightbak')
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				DB.setValue(t['nodeItem'], 'weight', 'number', nHeavyWeight)
				ChatManager.SystemMessage(DB.getValue(nodeChar, 'name', 'A player') .. "'s " .. sItemName .. ' is full.')
			elseif DB.getValue(t['nodeItem'], 'weightbak') then
				DB.setValue(t['nodeItem'], 'weight', 'number', DB.getValue(t['nodeItem'], 'weightbak', 0))
			end
		end
	end
	
	DB.setValue(nodeChar, 'encumbrance.load', 'number', nEncTotal)
end