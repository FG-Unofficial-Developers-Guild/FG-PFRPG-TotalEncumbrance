--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.carried'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildDeleted', applyPenalties)
end

--Summary: Handles arguments of applyPenalties()
--Argument: potentially nil nodeField representing carried databasenode on newly carried / equipped / dropped item
--Return: appropriate object databasenode - should represent node of PC
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
		local rActor = ActorManager.getActor("pc", nodeWin)
		local nodePC = DB.findNode(rActor['sCreatureNode'])
	end

	return nodePC
end

--Summary: Recomputes penalties and updates max stat and check penalty
--Arguments: nodeField - node of 'carried' when called from handler
function applyPenalties(nodeField)
	local nodePC = handleApplyPenaltiesArgs(nodeField)

	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset

	maxstattoset, checkpenaltytoset, spellfailuretoset = computePenalties(nodePC)

	--enable armor encumbrance when needed
	if maxstattoset ~= 0 or checkpenaltytoset ~= 0 or spellfailuretoset ~= 0 then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end

	DB.setValue(nodePC, 'encumbrance.armormaxstatbonus', 'number', maxstattoset)
	DB.setValue(nodePC, 'encumbrance.armorcheckpenalty', 'number', checkpenaltytoset)
	DB.setValue(nodePC, 'encumbrance.armorspellfailure', 'number', spellfailuretoset)
end

--Summary: Finds max stat / check penalty tables with appropriate nonzero values
--Argument: databasenode nodePC is the PC node
--Argument: table maxstattable is empty table to represent max stat penalties
--Argument: table eqcheckpenaltytable is empty table to represent check penalty penalties
--Argument: table spellfailuretable is empty table to represent spell failure penalties
--Return: nil, however table arguments are directly updated
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
		sItemType = string.lower(DB.getValue(v, 'type'))
		sItemName = string.lower(DB.getValue(v, 'name'))
		sItemSubtype = string.lower(DB.getValue(v, 'subtype'))

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

	local heavyarmorcount = table.getn(heavyarmortable)
	local medarmorcount = table.getn(medarmortable)
	local ltarmorcount = table.getn(ltarmortable)
	local shieldcount = table.getn(shieldtable)

	if heavyarmorcount ~= 0 and heavyarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 3)
	elseif medarmorcount ~= 0 and medarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 2)
	elseif ltarmorcount ~= 0 and ltarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 1)
	else 
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 0)
	end
	if shieldcount ~= 0 and shieldcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.shieldequipped', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.shieldequipped', 'number', 0)
	end
end

--Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--Argument: number light is medium encumbrance threshold for PC
--Argument: number medium is heavy encumbrance threshold for PC
--Argument: number total is current total encumbrance for PC
--Return: number for max stat penalty based solely on encumbrance (max stat, check penalty, spell failure chance)
--Return: number for check penalty penalty based solely on encumbrance (max stat, check penalty, spell failure chance)
--Return: number for spell failure chance based solely on encumbrance (max stat, check penalty, spell failure chance)
local function encumbrancePenalties(light, medium, total)
	if total > medium then -- heavy load
		return TEGlobals.heavymaxstat, TEGlobals.heavycheckpenalty, nil
	elseif total > light then -- medium load
		return TEGlobals.mediummaxstat, TEGlobals.mediumcheckpenalty, nil
	else -- light load
		return nil, nil, nil
	end
end

--Summary: Appends encumbrance-based penalties to respective penalty tables
--Argument: databasenode nodePC is the PC node
--Argument: table holding nonzero max stat penalties from armor / shields
--Argument: table holding nonzero check penalty penalties from armor / shields
--Argument: table holding nonzero spell failure penalties from armor / shields
--Return: nil, however table arguments are directly updated
local function rawEncumbrancePenalties(nodePC, tMaxStat, tCheckPenalty, tSpellFailure)
	local light = DB.getValue(nodePC, 'encumbrance.lightload')
	local medium = DB.getValue(nodePC, 'encumbrance.mediumload')
	local total = DB.getValue(nodePC, 'encumbrance.total')

	local maxstatbonusfromenc
	local checkpenaltyfromenc
	local spellfailurefromenc

	if light ~= nil then
		maxstatbonusfromenc, checkpenaltyfromenc, spellfailurefromenc = encumbrancePenalties(light, medium, total)
	end

	DB.setValue(nodePC, 'encumbrance.maxstatbonusfromenc', 'number', maxstatbonusfromenc ~= nil and maxstatbonusfromenc or 0)
	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromenc', 'number', checkpenaltyfromenc ~= nil and checkpenaltyfromenc or 0)

	if OptionsManager.isOption('WEIGHT_ENCUMBRANCE', 'on') then -- if weight encumbrance penalties are enabled in options
		if maxstatbonusfromenc ~= nil then
			table.insert(tMaxStat, maxstatbonusfromenc)
		end

		if checkpenaltyfromenc ~= nil then
			table.insert(tCheckPenalty, checkpenaltyfromenc)
		end
		--[[ I think we could support spell failure by encumbrance with this pending using a value of a setting in encumbrancePenalties.
		For now, it can be removed

		if spellfailurefromenc ~= nil then
			table.insert(tSpellFailure, spellfailurefromenc)
		end --]]
	end
end

--Summary: Finds max stat and check penalty based on current enc / armor / shield data
--Argument: databasenode nodePC is the PC node
--Return: number holding armor max stat penalty
--Return: number holding armor check penalty
--Return: number holding armor spell failure penalty
function computePenalties(nodePC)
	local tMaxStat = {}
	local tEqCheckPenalty = {}
	local tCheckPenalty = {}
	local tSpellFailure = {}

	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset

	rawArmorPenalties(nodePC, tMaxStat, tEqCheckPenalty, tSpellFailure)

	if table.getn(tEqCheckPenalty) ~= 0 then
		table.insert(tCheckPenalty, LibTotalEncumbrance.tableSum(tEqCheckPenalty)) -- add equipment total to overall table for comparison with encumbrance
	end

	rawEncumbrancePenalties(nodePC, tMaxStat, tCheckPenalty, tSpellFailure)

	if table.getn(tMaxStat) ~= 0 then
		maxstattoset = math.min(unpack(tMaxStat))
	else
		maxstattoset = -1
	end

	if table.getn(tCheckPenalty) ~= 0 then
		checkpenaltytoset = math.min(unpack(tCheckPenalty)) -- this would sum penalties on multi-equipped shields / armor & encumbrance
	else
		checkpenaltytoset = 0
	end

	if table.getn(tSpellFailure) ~= 0 then
		spellfailuretoset = LibTotalEncumbrance.tableSum(tSpellFailure) -- this would sum penalties on multi-equipped armor
	else
		spellfailuretoset = 0
	end

	return maxstattoset, checkpenaltytoset, spellfailuretoset
end