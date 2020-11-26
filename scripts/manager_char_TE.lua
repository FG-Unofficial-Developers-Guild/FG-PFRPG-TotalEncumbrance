-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath('combattracker.list.*.effects.*.label'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath('combattracker.list.*.effects.*.isactive'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildDeleted', onEffectChanged)
		DB.addHandler(DB.getPath('charsheet.*.hp'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.wounds'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.speed.base'), 'onUpdate', onSpeedChanged)
	end
end

function onEffectChanged(node)
	local nodeCT = node.getParent()
	if node.getName() ~= 'effects' then
		nodeCT = node.getChild('....')
	end
	local rActor = ActorManager.getActor('ct', nodeCT)
	local sActorType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sActorType == 'pc' then
		updateEncumbrance(nodeChar)
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
	local total = DB.getValue(nodeChar, 'encumbrance.load', 0)

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
function hasSpecialAbility(nodeChar, sSpecAbil)
	if not nodeChar or not sSpecAbil then
		return false
	end

	local sLowerSpecAbil = string.lower(sSpecAbil)
	for _,vNode in pairs(DB.getChildren(nodeChar, 'specialabilitylist')) do
		local vLowerSpecAbilName = StringManager.trim(DB.getValue(vNode, 'name', ''):lower());
		if vLowerSpecAbilName and string.match(vLowerSpecAbilName, sLowerSpecAbil .. ' %d+', 1) or string.match(vLowerSpecAbilName, sLowerSpecAbil, 1) then
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

				local nFighterLevel = DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), 'level', 0)
				local bArmorTraining = (hasSpecialAbility(nodeChar, 'Armor Training') and nFighterLevel >= 3)
				local bArmorTrainingH = (bArmorTraining and nFighterLevel >= 7)
				local bAdvArmorTraining = (hasSpecialAbility(nodeChar, 'Advanced Armor Training'))
				
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
				
					local bArmorLM = (sSubtypeLower == 'light' or sSubtypeLower == 'medium')
					local bArmorH = (sSubtypeLower == 'heavy')
					
					local nItemSpeed30 = DB.getValue(vNode, 'speed30', 0)
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if bArmorLM and bArmorTraining then nItemSpeed30 = 30 end
						if bArmorH and bArmorTrainingH then nItemSpeed30 = 30 end
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30)
						else
							nMainSpeed30 = nItemSpeed30
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, 'speed20', 0)
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if bArmorLM and bArmorTraining then nItemSpeed20 = 20 end
						if bArmorH and bArmorTrainingH then nItemSpeed20 = 20 end
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20)
						else
							nMainSpeed20 = nItemSpeed20
						end
					end
				end
					
				local nMaxStatBonus = DB.getValue(vNode, 'maxstatbonus', 0)
				if nMaxStatBonus > 0 then
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nMaxStatBonus = nMaxStatBonus + 2
						else
							nMaxStatBonus = nMaxStatBonus + 1
						end
					end
					
					if nMaxStatBonus and nMainMaxStatBonus < 999 then
						nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus)
					else
						nMainMaxStatBonus = nMaxStatBonus
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
					if not bIsShield and bArmorTraining then
						if nFighterLevel >= 15 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 4
						elseif nFighterLevel >= 11 and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 3
						elseif bArmorTrainingH and not bAdvArmorTraining then
							nCheckPenalty = nCheckPenalty + 2
						else
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

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function updateEncumbrance(nodeChar)
	local aContainers = {}
	local aExtraplanarContainers = {}
	for _,nodeItem in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local sItemName = string.lower(DB.getValue(nodeItem, 'name', ''))
		local nMaxWeight = DB.getValue(nodeItem, 'capacityweight', 0);
		local tDimensions = {
			['nLength'] =  DB.getValue(nodeItem, 'internal_length', 0),
			['nWidth'] =  DB.getValue(nodeItem, 'internal_width', 0),
			['nDepth'] =  DB.getValue(nodeItem, 'internal_depth', 0)
				};
		local nMaxVolume = 0;
		for _,v in spairs(tDimensions, function(t,a,b) return t[b] < t[a] end) do -- prepare to automatically 'lay flat'/intelligently position items
			nMaxVolume = nMaxVolume + v
		end
		
		if TEGlobals.isExtraplanarContainer(sItemName) then -- this creates an array keyed to the names of any detected extraplanar storage containers
			aExtraplanarContainers[sItemName] = {
				['nodeItem'] = nodeItem,
				['nTotalWeight'] = 0,
				['nMaxWeight'] = nMaxWeight,
				['nTotalVolume'] = 0,
				['nMaxVolume'] = nMaxVolume,
				['nMaxLength'] = tDimensions['nLength'],
				['nMaxWidth'] = tDimensions['nWidth'],
				['nMaxDepth'] = tDimensions['nDepth'],
				['bTooBig'] = 0
					};
		elseif TEGlobals.isContainer(sItemName) then -- this creates an array keyed to the names of any detected mundane storage containers
			aContainers[sItemName] = {
				['nodeItem'] = nodeItem,
				['nTotalWeight'] = 0,
				['nMaxWeight'] = nMaxWeight,
				['nTotalVolume'] = nVolume,
				['nMaxLength'] = tDimensions['nLength'],
				['nMaxWidth'] = tDimensions['nWidth'],
				['nMaxDepth'] = tDimensions['nDepth'],
				['bTooBig'] = 0
					};
		end
	end

	local nEncTotal = 0 -- this will cointain a running total of all items carried by the character
	
	for _,nodeItem in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local nItemCarried = DB.getValue(nodeItem, 'carried', 0)
		if nItemCarried ~= 0 then
			local nCount = DB.getValue(nodeItem, 'count', 0);
			local nItemWeight = DB.getValue(nodeItem, 'weight', 0);
			local sItemLoc = string.lower(DB.getValue(nodeItem, 'location', ''))

			local tItemDimensions = {
				['nLength'] =  DB.getValue(nodeItem, 'length', 0),
				['nWidth'] =  DB.getValue(nodeItem, 'width', 0),
				['nDepth'] =  DB.getValue(nodeItem, 'depth', 0)
					};
			local nItemVolume = 0;
			for _,v in spairs(tItemDimensions, function(t,a,b) return t[b] < t[a] end) do -- prepare to automatically 'lay flat'/intelligently position items
				nItemVolume = nItemVolume + v
			end
			
			if TEGlobals.isExtraplanarContainer(sItemLoc, nItemCarried) then
				if aExtraplanarContainers[sItemLoc] then
					aExtraplanarContainers[sItemLoc]['nTotalWeight'] = aExtraplanarContainers[sItemLoc]['nTotalWeight'] + (nCount * nItemWeight)
					aExtraplanarContainers[sItemLoc]['nTotalVolume'] = aExtraplanarContainers[sItemLoc]['nTotalVolume'] + (nCount * nItemVolume)
					if aExtraplanarContainers[sItemLoc]['nMaxLength'] < tItemDimensions['nLength'] then aExtraplanarContainers[sItemLoc]['bTooBig'] = 1 end
					if aExtraplanarContainers[sItemLoc]['nMaxWidth'] < tItemDimensions['nWidth'] then aExtraplanarContainers[sItemLoc]['bTooBig'] = 1 end
					if aExtraplanarContainers[sItemLoc]['nMaxDepth'] < tItemDimensions['nDepth'] then aExtraplanarContainers[sItemLoc]['bTooBig'] = 1 end
				end
			elseif TEGlobals.isContainer(sItemLoc, nItemCarried) then
				if aContainers[sItemLoc] then
					aContainers[sItemLoc]['nTotalWeight'] = aContainers[sItemLoc]['nTotalWeight'] + (nCount * nItemWeight)
					aContainers[sItemLoc]['nTotalVolume'] = aContainers[sItemLoc]['nTotalVolume'] + (nCount * nItemVolume)
					if aContainers[sItemLoc]['nMaxLength'] < tItemDimensions['nLength'] then aContainers[sItemLoc]['bTooBig'] = 1 end
					if aContainers[sItemLoc]['nMaxWidth'] < tItemDimensions['nWidth'] then aContainers[sItemLoc]['bTooBig'] = 1 end
					if aContainers[sItemLoc]['nMaxDepth'] < tItemDimensions['nDepth'] then aContainers[sItemLoc]['bTooBig'] = 1 end
				end
				nEncTotal = nEncTotal + (nCount * nItemWeight)
			else
				nEncTotal = nEncTotal + (nCount * nItemWeight)
			end
		end
	end
	
	for _,t in pairs(aContainers) do
		DB.setValue(t['nodeItem'], 'extraplanarcontents', 'number', t['nTotalWeight'])
		DB.setValue(t['nodeItem'], 'contentsvolume', 'number', t['nTotalVolume'])
		
		if t['nMaxWeight'] > 0 then
			if (t['nTotalWeight'] > t['nMaxWeight']) then
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')

				if not t['nodeItem'].getChild('announcedW') then
					DB.setValue(t['nodeItem'], 'announcedW', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), sHoldingPc, sItemName, 'weight'))
				end
			else
				if t['nodeItem'].getChild('announcedW') then t['nodeItem'].getChild('announcedW').delete() end
				if t['nodeItem'].getChild('announced') then t['nodeItem'].getChild('announced').delete() end
			end
		end
		if t['nMaxVolume'] > 0 then
			if t['bTooBig'] == 1 then
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				if not t['nodeItem'].getChild('announcedV') then
					DB.setValue(t['nodeItem'], 'announcedV', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), sHoldingPc, sItemName, 'maximum dimension'))
				end
			elseif t['nTotalVolume'] > t['nMaxVolume'] then
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				if not t['nodeItem'].getChild('announcedV') then
					DB.setValue(t['nodeItem'], 'announcedV', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), sHoldingPc, sItemName), 'volume')
				end
			else
				if t['nodeItem'].getChild('announcedV') then t['nodeItem'].getChild('announcedV').delete() end
				if t['nodeItem'].getChild('announced') then t['nodeItem'].getChild('announced').delete() end
			end
		end
	end
	for _,t in pairs(aExtraplanarContainers) do
		DB.setValue(t['nodeItem'], 'extraplanarcontents', 'number', t['nTotalWeight'])
		DB.setValue(t['nodeItem'], 'contentsvolume', 'number', t['nTotalVolume'])
		
		if t['nMaxWeight'] > 0 then
			if not DB.getValue(t['nodeItem'], 'weightbak') then DB.setValue(t['nodeItem'], 'weightbak', 'number', DB.getValue(t['nodeItem'], 'weight', 0)) end
			if (t['nTotalWeight'] > t['nMaxWeight']) and DB.getValue(t['nodeItem'], 'weightbak') then
				local nHeavyWeight = t['nTotalWeight'] - t['nMaxWeight'] + DB.getValue(t['nodeItem'], 'weightbak')
				DB.setValue(t['nodeItem'], 'weight', 'number', nHeavyWeight)

				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				if not t['nodeItem'].getChild('announcedW') then
					DB.setValue(t['nodeItem'], 'announcedW', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), sHoldingPc, sItemName, 'weight'))
				end
			elseif DB.getValue(t['nodeItem'], 'weightbak') then
				DB.setValue(t['nodeItem'], 'weight', 'number', DB.getValue(t['nodeItem'], 'weightbak', 0))
				if t['nodeItem'].getChild('announcedW') then t['nodeItem'].getChild('announcedW').delete() end
				if t['nodeItem'].getChild('announced') then t['nodeItem'].getChild('announced').delete() end
			end
		end
		if t['nMaxVolume'] > 0 then
			if t['bTooBig'] == 1 then
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				if not t['nodeItem'].getChild('announcedV') then
					DB.setValue(t['nodeItem'], 'announcedV', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), sHoldingPc, sItemName, 'maximum dimension'))
				end
			elseif t['nTotalVolume'] > t['nMaxVolume'] then
				local sItemName = DB.getValue(t['nodeItem'], 'name', 'extraplanar container')
				if not t['nodeItem'].getChild('announcedV') then
					DB.setValue(t['nodeItem'], 'announcedV', 'number', 1)
					local sHoldingPc = DB.getValue(nodeChar, 'name', Interface.getString("char_name_unknown"))
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), sHoldingPc, sItemName, 'volume'))
				end
			else
				if t['nodeItem'].getChild('announcedV') then t['nodeItem'].getChild('announcedV').delete() end
				if t['nodeItem'].getChild('announced') then t['nodeItem'].getChild('announced').delete() end
			end
		end
	end
	
	local nEqLoad = nEncTotal * TEGlobals.getEncWeightUnit()

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'kg-full') then
		nEqLoad = nEncTotal
	end

	local nTotal = nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.load', 'number', nTotalToSet)
	calcItemArmorClass(nodeChar)
end