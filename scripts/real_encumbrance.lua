--
--	Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.carried'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildDeleted', applyPenalties)
end

--	Summary: Handles arguments of applyPenalties()
--	Argument: potentially nil nodeField representing carried databasenode on newly carried / equipped / dropped item
--	Return: appropriate object databasenode - should represent node of PC
local function handleApplyPenaltiesArgs(nodeField)
	local nodePC

	if nodeField.getParent().getName() == 'charsheet' then
		nodePC = nodeField
	elseif nodeField.getName() == 'inventorylist' then
		nodePC = nodeField.getParent()
	elseif nodeField.getParent().getName() == 'inventorylist' then
		nodePC = nodeField.getChild( '...' )
	elseif nodeField.getName() == 'carried' then
		nodePC = nodeField.getChild( '....' )
	else
		local rActor = ActorManager.getActor("pc", nodeField)
		local nodePC = DB.findNode(rActor['sCreatureNode'])
	end

	return nodePC
end

--	Summary: Recomputes penalties and updates max stat and check penalty
--	Arguments: nodeField - node of 'carried' when called from handler
function applyPenalties(nodeField)
	local nodePC = handleApplyPenaltiesArgs(nodeField)

	local nMaxStatToSet
	local nCheckPenaltyToSet
	local nSpellFailureToSet

	nMaxStatToSet, nCheckPenaltyToSet, nSpellFailureToSet = computePenalties(nodePC)

	--enable armor encumbrance when needed
	if nMaxStatToSet ~= -1 or nCheckPenaltyToSet ~= 0 or nSpellFailureToSet ~= 0 then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end

	DB.setValue(nodePC, 'encumbrance.armormaxstatbonus', 'number', nMaxStatToSet)
	DB.setValue(nodePC, 'encumbrance.armorcheckpenalty', 'number', nCheckPenaltyToSet)
	DB.setValue(nodePC, 'encumbrance.armorspellfailure', 'number', nSpellFailureToSet)
end

--	Summary: Finds max stat / check penalty tables with appropriate nonzero values
--	Argument: databasenode nodePC is the PC node
--	Argument: table tMaxStat is empty table to represent max stat penalties
--	Argument: table tEqCheckPenalty is empty table to represent check penalty penalties
--	Argument: table tSpellFailure is empty table to represent spell failure penalties
--	Return: nil, however table arguments are directly updated
local function rawArmorPenalties(nodePC, tMaxStat, tEqCheckPenalty, tSpellFailure)
	local nItemCarried
	local nItemMaxStat
	local nItemCheckPenalty
	local nItemSpellFailure

	local tLtArmor = {}
	local tMedArmor = {}
	local tHeavyArmor = {}
	local tShield = {}

	local bClumsyArmor = false

	for _,v in pairs(DB.getChildren(nodePC, 'inventorylist')) do
		nItemCarried = DB.getValue(v, 'carried', 0)
		nItemMaxStat = DB.getValue(v, 'maxstatbonus', 0)
		nItemCheckPenalty = DB.getValue(v, 'checkpenalty', 0)
		nItemSpellFailure = DB.getValue(v, 'spellfailure', 0)
		sItemType = string.lower(DB.getValue(v, 'type', ''))
		sItemName = string.lower(DB.getValue(v, 'name', ''))
		sItemSubtype = string.lower(DB.getValue(v, 'subtype', ''))

		if nItemCarried == 2 then
			for _,v in pairs(TEGlobals.tClumsyArmorTypes) do
				if string.find(sItemName, v) then
					bClumsyArmor = true
					break
				end
			end
			if nItemMaxStat ~= 0 or bClumsyArmor then
				table.insert(tMaxStat, nItemMaxStat)
			end
			if nItemCheckPenalty ~= 0 then
				table.insert(tEqCheckPenalty, nItemCheckPenalty)
			end
			if nItemSpellFailure ~= 0 then
				table.insert(tSpellFailure, nItemSpellFailure)
			end
			if sItemType == 'armor' then
				if sItemSubtype == 'light' then
					table.insert(tLtArmor, '1')
				elseif sItemSubtype == 'medium' then
					table.insert(tMedArmor, '2')
				elseif sItemSubtype == 'heavy' then
					table.insert(tHeavyArmor, '3')
				end
				if sItemName == 'tower' then
					table.insert(tHeavyArmor, '3')
				elseif sItemSubtype == 'shield' or sItemSubtype == 'magic shield' then
					table.insert(tShield, 'i like turtles')
				end
			end
		end
	end

	local nMaxStatFromArmor
	local nCheckPenaltyFromArmor

	if table.getn(tMaxStat) ~= 0 then
		nMaxStatFromArmor = LibTotalEncumbrance.tableSum(tMaxStat) -- this would sum penalties on multi-equipped armor
	else
		nMaxStatFromArmor = 0
	end
	if table.getn(tEqCheckPenalty) ~= 0 then
		nCheckPenaltyFromArmor = LibTotalEncumbrance.tableSum(tEqCheckPenalty) -- this would sum penalties on multi-equipped armor
	else
		nCheckPenaltyFromArmor = 0
	end

	DB.setValue(nodePC, 'encumbrance.maxstatbonusfromarmor', 'number', nMaxStatFromArmor ~= nil and nMaxStatFromArmor or -1)
	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromarmor', 'number', nCheckPenaltyFromArmor ~= nil and nCheckPenaltyFromArmor or 0)

	local nHeavyArmorCount = table.getn(tHeavyArmor)
	local nMedArmorCount = table.getn(tMedArmor)
	local nLtArmorCount = table.getn(tLtArmor)
	local nShieldCount = table.getn(tShield)

	if nHeavyArmorCount ~= 0 and nHeavyArmorCount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 3)
	elseif nMedArmorCount ~= 0 and nMedArmorCount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 2)
	elseif nLtArmorCount ~= 0 and nLtArmorCount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 1)
	else 
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 0)
	end
	if nShieldCount ~= 0 and nShieldCount ~= nil then
		DB.setValue(nodePC, 'encumbrance.shieldequipped', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.shieldequipped', 'number', 0)
	end
end

--	Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--	Argument: number light is medium encumbrance threshold for PC
--	Argument: number medium is heavy encumbrance threshold for PC
--	Argument: number total is current total encumbrance for PC
--	Return: number for max stat penalty based solely on encumbrance (max stat, check penalty, spell failure chance)
--	Return: number for check penalty penalty based solely on encumbrance (max stat, check penalty, spell failure chance)
--	Return: number for spell failure chance based solely on encumbrance (max stat, check penalty, spell failure chance)
local function encumbrancePenalties(light, medium, total)
	if total > medium then -- heavy load
		return TEGlobals.nHeavyMaxStat, TEGlobals.nHeavyCheckPenalty, nil
	elseif total > light then -- medium load
		return TEGlobals.nMediumMaxStat, TEGlobals.nMediumCheckPenalty, nil
	else -- light load
		return nil, nil, nil
	end
end

--	Summary: Appends encumbrance-based penalties to respective penalty tables
--	Argument: databasenode nodePC is the PC node
--	Argument: table holding nonzero max stat penalties from armor / shields
--	Argument: table holding nonzero check penalty penalties from armor / shields
--	Argument: table holding nonzero spell failure penalties from armor / shields
--	Return: nil, however table arguments are directly updated
local function rawEncumbrancePenalties(nodePC, tMaxStat, tCheckPenalty, tSpellFailure)
	local light = DB.getValue(nodePC, 'encumbrance.lightload')
	local medium = DB.getValue(nodePC, 'encumbrance.mediumload')
	local total = DB.getValue(nodePC, 'encumbrance.total')

	local nMaxStatFromEnc
	local NCheckPenaltyFromEnc
	local nSpellFailureFromEnc

	if light ~= nil then
		nMaxStatFromEnc, NCheckPenaltyFromEnc, nSpellFailureFromEnc = encumbrancePenalties(light, medium, total)
	end

	DB.setValue(nodePC, 'encumbrance.maxstatbonusfromenc', 'number', nMaxStatFromEnc ~= nil and nMaxStatFromEnc or 0)
	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromenc', 'number', NCheckPenaltyFromEnc ~= nil and NCheckPenaltyFromEnc or 0)

	if OptionsManager.isOption('WEIGHT_ENCUMBRANCE', 'on') then -- if weight encumbrance penalties are enabled in options
		if nMaxStatFromEnc ~= nil then
			table.insert(tMaxStat, nMaxStatFromEnc)
		end

		if NCheckPenaltyFromEnc ~= nil then
			table.insert(tCheckPenalty, NCheckPenaltyFromEnc)
		end
		--[[ I think we could support spell failure by encumbrance with this pending using a value of a setting in encumbrancePenalties.
		For now, it can be removed

		if nSpellFailureFromEnc ~= nil then
			table.insert(tSpellFailure, nSpellFailureFromEnc)
		end --]]
	end
end

--	Summary: Finds max stat and check penalty based on current enc / armor / shield data
--	Argument: databasenode nodePC is the PC node
--	Return: number holding armor max stat penalty
--	Return: number holding armor check penalty
--	Return: number holding armor spell failure penalty
function computePenalties(nodePC)
	local tMaxStat = {}
	local tEqCheckPenalty = {}
	local tCheckPenalty = {}
	local tSpellFailure = {}

	local nMaxStatToSet
	local nCheckPenaltyToSet
	local nSpellFailureToSet

	rawArmorPenalties(nodePC, tMaxStat, tEqCheckPenalty, tSpellFailure)

	if table.getn(tEqCheckPenalty) ~= 0 then
		table.insert(tCheckPenalty, LibTotalEncumbrance.tableSum(tEqCheckPenalty)) -- add equipment total to overall table for comparison with encumbrance
	end

	rawEncumbrancePenalties(nodePC, tMaxStat, tCheckPenalty, tSpellFailure)

	if table.getn(tMaxStat) ~= 0 then
		nMaxStatToSet = math.min(unpack(tMaxStat))
	else
		nMaxStatToSet = -1
	end

	if table.getn(tCheckPenalty) ~= 0 then
		nCheckPenaltyToSet = math.min(unpack(tCheckPenalty)) -- this would sum penalties on multi-equipped shields / armor & encumbrance
	else
		nCheckPenaltyToSet = 0
	end

	if table.getn(tSpellFailure) ~= 0 then
		nSpellFailureToSet = LibTotalEncumbrance.tableSum(tSpellFailure) -- this would sum penalties on multi-equipped armor

		if nSpellFailureToSet > 100 then
			nSpellFailureToSet = 100
		end
	else
		nSpellFailureToSet = 0
	end

	return nMaxStatToSet, nCheckPenaltyToSet, nSpellFailureToSet
end