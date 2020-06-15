--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
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
local function rawArmorPenalties(nodePC, maxstattable, eqcheckpenaltytable, spellfailuretable)
	local itemcarried
	local itemmaxstat
	local itemcheckpenalty
	local itemspellfailure
	
	local ltarmortable = {}
	local medarmortable = {}
	local heavyarmortable = {}

	for _,v in pairs(DB.getChildren(nodePC, 'inventorylist')) do
		itemcarried = DB.getValue(v, 'carried', 0)
		itemmaxstat = DB.getValue(v, 'maxstatbonus')
		itemcheckpenalty = DB.getValue(v, 'checkpenalty')
		itemspellfailure = DB.getValue(v, 'spellfailure')
		itemtype = DB.getValue(v, 'type')
		itemsubtype = DB.getValue(v, 'subtype')

		if itemcarried == 2 then
			if itemmaxstat ~= nil and itemmaxstat ~= 0 then
				table.insert(maxstattable, itemmaxstat)
			end
			if itemcheckpenalty ~= nil and itemcheckpenalty ~= 0 then
				table.insert(eqcheckpenaltytable, itemcheckpenalty)
			end
			if itemspellfailure ~= nil and itemspellfailure ~= 0 then
				table.insert(spellfailuretable, itemspellfailure)
			end
			if itemtype == 'Armor' then
				if itemsubtype == 'Light' or itemsubtype == 'light' then
				table.insert(ltarmortable, '1')
				elseif itemsubtype == 'Medium' or itemsubtype == 'medium' then
				table.insert(medarmortable, '2')
				elseif itemsubtype == 'Heavy' or itemsubtype == 'heavy' then
				table.insert(heavyarmortable, '3')
				end
			end
		end
	end

	local heavyarmorcount
	local medarmorcount
	local ltarmorcount

	heavyarmorcount = table.getn(heavyarmortable)
	medarmorcount = table.getn(medarmortable)
	ltarmorcount = table.getn(ltarmortable)

	if heavyarmorcount ~= 0 and heavyarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 3)
	elseif medarmorcount ~= 0 and medarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 2)
	elseif ltarmorcount ~= 0 and ltarmorcount ~= nil then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 1)
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
		return 1, -6, nil
	elseif total > light then -- medium load
		return 3, -3, nil
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
local function rawEncumbrancePenalties(nodePC, maxstattable, checkpenaltytable, spellfailuretable)
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
			table.insert(maxstattable, maxstatbonusfromenc)
		end
		
		if checkpenaltyfromenc ~= nil then
			table.insert(checkpenaltytable, checkpenaltyfromenc)
		end
		--[[ I think we could support spell failure by encumbrance with this pending using a value of a setting in encumbrancePenalties.
		For now, it can be removed

		if spellfailurefromenc ~= nil then
			table.insert(spellfailuretable, spellfailurefromenc)
		end --]]
	end
end

--Summary: Sums table values
--Argument: table t to sum values within
--Return: sum of values in table t
local function tableSum(t)
	local sum = 0

	for _,v in pairs(t) do
		sum = sum + v
	end

	return sum
end

--Summary: Finds max stat and check penalty based on current enc / armor / shield data
--Argument: databasenode nodePC is the PC node
--Return: number holding armor max stat penalty
--Return: number holding armor check penalty
--Return: number holding armor spell failure penalty
function computePenalties(nodePC)
	local maxstattable = {}
	local eqcheckpenaltytable	= {}
	local checkpenaltytable = {}
	local spellfailuretable = {}
	
	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset

	rawArmorPenalties(nodePC, maxstattable, eqcheckpenaltytable, spellfailuretable)

	if table.getn(eqcheckpenaltytable) ~= 0 then
		table.insert(checkpenaltytable, tableSum(eqcheckpenaltytable)) -- add equipment total to overall table for comparison with encumbrance
	end

	rawEncumbrancePenalties(nodePC, maxstattable, checkpenaltytable, spellfailuretable)

	if table.getn(maxstattable) ~= 0 then
		maxstattoset = math.min(unpack(maxstattable))
	else
		maxstattoset = 0
	end

	if table.getn(checkpenaltytable) ~= 0 then
		checkpenaltytoset = math.min(unpack(checkpenaltytable)) -- this would sum penalties on multi-equipped shields / armor & encumbrance
	else
		checkpenaltytoset = 0
	end

	if table.getn(spellfailuretable) ~= 0 then
		spellfailuretoset = tableSum(spellfailuretable) -- this would sum penalties on multi-equipped armor
	else
		spellfailuretoset = 0
	end

	return maxstattoset, checkpenaltytoset, spellfailuretoset
end