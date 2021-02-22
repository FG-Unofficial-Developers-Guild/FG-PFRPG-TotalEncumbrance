--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function onEffectChanged(node)
	local nodeCT = node.getParent()
	if node.getName() ~= 'effects' then
		nodeCT = node.getChild('....')
	end
	local rActor = ActorManager.resolveActor(nodeCT)
	if ActorManager.isPC(rActor) then
		updateEncumbrance_new(ActorManager.getCreatureNode(rActor))
	end
end

local function onHealthChanged(node)
	calcItemArmorClass_new(node.getParent())
end

local function onSpeedChanged(node)
	calcItemArmorClass_new(node.getChild('...'))
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
local function hasSpecialAbility(nodeChar, sSpecAbil)
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
	local rActor = ActorManager.resolveActor(nodeChar)
	if not rActor then
		return 0, false
	end

	local bSpeedHalved = false
	local bSpeedZero = false

	if EffectManager35EDS.hasEffectCondition(rActor, 'Exhausted') or EffectManager35EDS.hasEffectCondition(rActor, 'Entangled') then
		bSpeedHalved = true
	end

	if
		EffectManager35EDS.hasEffectCondition(rActor, 'Grappled')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Paralyzed')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Petrified')
		or EffectManager35EDS.hasEffectCondition(rActor, 'Pinned')
	then
		bSpeedZero = true
	end

	--	Check if the character is disabled (at zero remaining hp)
	if DB.getValue(nodeChar, 'hp.total', 0) == DB.getValue(nodeChar, 'hp.wounds', 0) then
		bSpeedHalved = true
	end

	local nSpeedAdjFromEffects = EffectManager35EDS.getEffectsBonus(rActor, 'SPEED', true)

	return nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero
end

function calcItemArmorClass_new(nodeChar)
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
		bApplySpeedPenalty = nil
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

	local nSpeedArmor = 0

	if bApplySpeedPenalty == true then
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

local function spairs(t, order)
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

local function build_containers(node_pc)
	local table_containers_mundane = {}
	local table_containers_extraplanar = {}
	for _,node_item in pairs(DB.getChildren(node_pc, 'inventorylist')) do
		local string_item_name = string.lower(DB.getValue(node_item, 'name', ''))
		local number_maxweight = DB.getValue(node_item, 'capacityweight', 0);
		local table_dimensions = {
			['nLength'] =  DB.getValue(node_item, 'internal_length', 0),
			['nWidth'] =  DB.getValue(node_item, 'internal_width', 0),
			['nDepth'] =  DB.getValue(node_item, 'internal_depth', 0),
				};
		local number_maxvolume = 0;
		for _,v in spairs(table_dimensions, function(t,a,b) return t[b] < t[a] end) do -- prepare to automatically 'lay flat'/intelligently position items
			number_maxvolume = number_maxvolume + v
		end

		if TEGlobals.isExtraplanarContainer(string_item_name) then -- this creates an array keyed to the names of any detected extraplanar storage containers
			table_containers_extraplanar[string_item_name] = {
					['nodeItem'] = node_item,
					['nTotalWeight'] = 0,
					['nMaxWeight'] = number_maxweight,
					['nTotalVolume'] = 0,
					['nMaxVolume'] = number_maxvolume,
					['nMaxLength'] = table_dimensions['nLength'],
					['nMaxWidth'] = table_dimensions['nWidth'],
					['nMaxDepth'] = table_dimensions['nDepth'],
					['bTooBig'] = 0,
				};
		elseif TEGlobals.isContainer(string_item_name) then -- this creates an array keyed to the names of any detected mundane storage containers
			table_containers_mundane[string_item_name] = {
					['nodeItem'] = node_item,
					['nTotalWeight'] = 0,
					['nMaxWeight'] = number_maxweight,
					['nTotalVolume'] = 0,
					['nMaxVolume'] = number_maxvolume,
					['nMaxLength'] = table_dimensions['nLength'],
					['nMaxWidth'] = table_dimensions['nWidth'],
					['nMaxDepth'] = table_dimensions['nDepth'],
					['bTooBig'] = 0,
				};
		end
	end

	return table_containers_mundane, table_containers_extraplanar
end

local function measure_contents(node_pc, table_containers_mundane, table_containers_extraplanar)
	local number_total_weight = 0
	for _,node_item in pairs(DB.getChildren(node_pc, 'inventorylist')) do
		local state_item_carried = DB.getValue(node_item, 'carried', 0)
		if state_item_carried ~= 0 then
			local number_item_count = DB.getValue(node_item, 'count', 0);
			local number_item_weight = DB.getValue(node_item, 'weight', 0);
			local string_item_location = string.lower(DB.getValue(node_item, 'location', ''))

			local table_item_dimensions = {
				['nLength'] =  DB.getValue(node_item, 'length', 0),
				['nWidth'] =  DB.getValue(node_item, 'width', 0),
				['nDepth'] =  DB.getValue(node_item, 'depth', 0)
					};
			local number_item_volume = 0;
			for _,v in spairs(table_item_dimensions, function(t,a,b) return t[b] < t[a] end) do -- prepare to automatically 'lay flat'/intelligently position items
				number_item_volume = number_item_volume + v
			end

			if TEGlobals.isExtraplanarContainer(string_item_location, state_item_carried) then
				if table_containers_extraplanar[string_item_location] then
					table_containers_extraplanar[string_item_location]['nTotalWeight'] = table_containers_extraplanar[string_item_location]['nTotalWeight'] + (number_item_count * number_item_weight)
					table_containers_extraplanar[string_item_location]['nTotalVolume'] = table_containers_extraplanar[string_item_location]['nTotalVolume'] + (number_item_count * number_item_volume)
					if table_containers_extraplanar[string_item_location]['nMaxLength'] < table_item_dimensions['nLength'] then table_containers_extraplanar[string_item_location]['bTooBig'] = 1 end
					if table_containers_extraplanar[string_item_location]['nMaxWidth'] < table_item_dimensions['nWidth'] then table_containers_extraplanar[string_item_location]['bTooBig'] = 1 end
					if table_containers_extraplanar[string_item_location]['nMaxDepth'] < table_item_dimensions['nDepth'] then table_containers_extraplanar[string_item_location]['bTooBig'] = 1 end
				end
			elseif TEGlobals.isContainer(string_item_location, state_item_carried) then
				if table_containers_mundane[string_item_location] then
					table_containers_mundane[string_item_location]['nTotalWeight'] = table_containers_mundane[string_item_location]['nTotalWeight'] + (number_item_count * number_item_weight)
					table_containers_mundane[string_item_location]['nTotalVolume'] = table_containers_mundane[string_item_location]['nTotalVolume'] + (number_item_count * number_item_volume)
					if table_containers_mundane[string_item_location]['nMaxLength'] < table_item_dimensions['nLength'] then table_containers_mundane[string_item_location]['bTooBig'] = 1 end
					if table_containers_mundane[string_item_location]['nMaxWidth'] < table_item_dimensions['nWidth'] then table_containers_mundane[string_item_location]['bTooBig'] = 1 end
					if table_containers_mundane[string_item_location]['nMaxDepth'] < table_item_dimensions['nDepth'] then table_containers_mundane[string_item_location]['bTooBig'] = 1 end
				end
				number_total_weight = number_total_weight + (number_item_count * number_item_weight)
			else
				number_total_weight = number_total_weight + (number_item_count * number_item_weight)
			end
		end
	end

	return number_total_weight
end

local function write_contents_to_containers(node_pc, table_containers_mundane, table_containers_extraplanar)
	local string_player_name = DB.getValue(node_pc, 'name', Interface.getString("char_name_unknown"))
	for _,table_container in pairs(table_containers_mundane) do
		DB.setValue(table_container['nodeItem'], 'extraplanarcontents', 'number', table_container['nTotalWeight'])
		DB.setValue(table_container['nodeItem'], 'contentsvolume', 'number', table_container['nTotalVolume'])
		local string_item_name = DB.getValue(table_container['nodeItem'], 'name', 'container')

		if table_container['nMaxWeight'] > 0 then
			if (table_container['nTotalWeight'] > table_container['nMaxWeight']) then

				if not table_container['nodeItem'].getChild('announcedW') then
					DB.setValue(table_container['nodeItem'], 'announcedW', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), string_player_name, string_item_name, 'weight'))
				end
			else
				if table_container['nodeItem'].getChild('announcedW') then table_container['nodeItem'].getChild('announcedW').delete() end
				if table_container['nodeItem'].getChild('announced') then table_container['nodeItem'].getChild('announced').delete() end
			end
		end
		if OptionsManager.isOption('ITEM_VOLUME', 'on') and table_container['nMaxVolume'] > 0 then
			if table_container['bTooBig'] == 1 then
				if not table_container['nodeItem'].getChild('announcedV') then
					DB.setValue(table_container['nodeItem'], 'announcedV', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), string_player_name, string_item_name, 'maximum dimension'))
				end
			elseif table_container['nTotalVolume'] > table_container['nMaxVolume'] then
				if not table_container['nodeItem'].getChild('announcedV') then
					DB.setValue(table_container['nodeItem'], 'announcedV', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_overfull"), string_player_name, string_item_name), 'volume')
				end
			else
				if table_container['nodeItem'].getChild('announcedV') then table_container['nodeItem'].getChild('announcedV').delete() end
				if table_container['nodeItem'].getChild('announced') then table_container['nodeItem'].getChild('announced').delete() end
			end
		end
	end
	for _,table_container_extraplanar in pairs(table_containers_extraplanar) do
		DB.setValue(table_container_extraplanar['nodeItem'], 'extraplanarcontents', 'number', table_container_extraplanar['nTotalWeight'])
		DB.setValue(table_container_extraplanar['nodeItem'], 'contentsvolume', 'number', table_container_extraplanar['nTotalVolume'])
		local string_item_name = DB.getValue(table_container_extraplanar['nodeItem'], 'name', 'extraplanar container')

		if table_container_extraplanar['nMaxWeight'] > 0 then
			if not DB.getValue(table_container_extraplanar['nodeItem'], 'weightbak') then DB.setValue(table_container_extraplanar['nodeItem'], 'weightbak', 'number', DB.getValue(table_container_extraplanar['nodeItem'], 'weight', 0)) end
			if (table_container_extraplanar['nTotalWeight'] > table_container_extraplanar['nMaxWeight']) and DB.getValue(table_container_extraplanar['nodeItem'], 'weightbak') then
				local string_excess_weight = table_container_extraplanar['nTotalWeight'] - table_container_extraplanar['nMaxWeight'] + DB.getValue(table_container_extraplanar['nodeItem'], 'weightbak')
				DB.setValue(table_container_extraplanar['nodeItem'], 'weight', 'number', string_excess_weight)

				if not table_container_extraplanar['nodeItem'].getChild('announcedW') then
					DB.setValue(table_container_extraplanar['nodeItem'], 'announcedW', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), string_player_name, string_item_name, 'weight'))
				end
			elseif DB.getValue(table_container_extraplanar['nodeItem'], 'weightbak') then
				DB.setValue(table_container_extraplanar['nodeItem'], 'weight', 'number', DB.getValue(table_container_extraplanar['nodeItem'], 'weightbak', 0))
				if table_container_extraplanar['nodeItem'].getChild('announcedW') then table_container_extraplanar['nodeItem'].getChild('announcedW').delete() end
				if table_container_extraplanar['nodeItem'].getChild('announced') then table_container_extraplanar['nodeItem'].getChild('announced').delete() end
			end
		end
		if OptionsManager.isOption('ITEM_VOLUME', 'on') and table_container_extraplanar['nMaxVolume'] > 0 then
			if table_container_extraplanar['bTooBig'] == 1 then
				if not table_container_extraplanar['nodeItem'].getChild('announcedV') then
					DB.setValue(table_container_extraplanar['nodeItem'], 'announcedV', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), string_player_name, string_item_name, 'maximum dimension'))
				end
			elseif table_container_extraplanar['nTotalVolume'] > table_container_extraplanar['nMaxVolume'] then
				if not table_container_extraplanar['nodeItem'].getChild('announcedV') then
					DB.setValue(table_container_extraplanar['nodeItem'], 'announcedV', 'number', 1)
					ChatManager.SystemMessage(string.format(Interface.getString("item_self_destruct"), string_player_name, string_item_name, 'volume'))
				end
			else
				if table_container_extraplanar['nodeItem'].getChild('announcedV') then table_container_extraplanar['nodeItem'].getChild('announcedV').delete() end
				if table_container_extraplanar['nodeItem'].getChild('announced') then table_container_extraplanar['nodeItem'].getChild('announced').delete() end
			end
		end
	end
end

function updateEncumbrance_new(nodeChar)
	local table_containers_mundane, table_containers_extraplanar = build_containers(nodeChar)

	-- this will cointain a running total of all items carried by the character
	local nEncTotal = measure_contents(nodeChar, table_containers_mundane, table_containers_extraplanar)

	write_contents_to_containers(nodeChar, table_containers_mundane, table_containers_extraplanar)

	local nEqLoad = nEncTotal * TEGlobals.getEncWeightUnit()

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'kg-full') then
		nEqLoad = nEncTotal
	end

	local nTotal = nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.load', 'number', nTotalToSet)
	calcItemArmorClass_new(nodeChar)
end

local calcItemArmorClass_old = nil
local updateEncumbrance_old = nil

function onInit()
	if Session.IsHost then
		DB.addHandler(DB.getPath('combattracker.list.*.effects.*.label'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath('combattracker.list.*.effects.*.isactive'), 'onUpdate', onEffectChanged)
		DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildDeleted', onEffectChanged)
		DB.addHandler(DB.getPath('charsheet.*.hp'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.wounds'), 'onChildUpdate', onHealthChanged)
		DB.addHandler(DB.getPath('charsheet.*.speed.base'), 'onUpdate', onSpeedChanged)
	end

	calcItemArmorClass_old = CharManager.calcItemArmorClass;
	CharManager.calcItemArmorClass = calcItemArmorClass_new;
	updateEncumbrance_old = CharManager.updateEncumbrance;
	CharManager.updateEncumbrance = updateEncumbrance_new;
end

function onClose()
	CharManager.calcItemArmorClass = calcItemArmorClass_old;
	CharManager.updateEncumbrance = updateEncumbrance_old;
end
