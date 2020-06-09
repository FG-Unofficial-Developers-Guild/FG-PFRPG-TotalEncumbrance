-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath(getDatabaseNode(), 'inventorylist.*.carried'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath(getDatabaseNode(), 'coins.*.amount'), 'onUpdate', applyPenalties)
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'inventorylist.*.carried'), 'onUpdate', applyPenalties)
	DB.removeHandler(DB.getPath(getDatabaseNode(), 'coins.*.amount'), 'onUpdate', applyPenalties)
end

local function notEmpty(s)
	return s ~= nil
end

local function isEmpty(s)
	return s == nil
end

--Summary: Handles arguments of applyPenalties()
--Argument: potentially nil nodeField representing carried databasenode on newly carried / equipped / dropped item
--Return: appropriate object databasenode - should represent node of PC
local function handleApplyPenaltiesArgs(nodeField)
	local nodePC
	
	if nodeField == '*.coins.*.amount' then
		nodePC = nodeField.getChild( '...' )
	elseif notEmpty(nodeField) then
		nodePC = nodeField.getChild( '....' )
	else
		local nodeWin = window.getDatabaseNode()
		local rActor = ActorManager.getActor('pc', nodeWin)
		nodePC = DB.findNode(rActor['sCreatureNode'])
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

	Debug.chat('applyPenalties', maxstattoset, checkpenaltytoset, spellfailuretoset)

	DB.setValue(nodePC, 'encumbrance.armormaxstatbonus', 'number', maxstattoset)
	DB.setValue(nodePC, 'encumbrance.armorcheckpenalty', 'number', checkpenaltytoset)
	DB.setValue(nodePC, 'encumbrance.armorspellfailure', 'number', spellfailuretoset)

	--enable armor encumbrance when needed
	if isEmpty(maxstattoset) and isEmpty(checkpenaltytoset) and isEmpty(spellfailuretoset) then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	else
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	end
end

local function addtoTable(t,i)
	if isEmpty(t) then
		local t = {}
	end
	if notEmpty(i) then
		table.insert(t, i)
	end
	
	return t
end

--Summary: Finds max stat / check penalty tables with appropriate nonzero values
--Argument: databasenode nodePC is the PC node
--Return: table holding nonzero max stat penalties from armor / shields
--Return: table holding nonzero check penalty penalties from armor / shields
local function rawArmorPenalties(nodePC)
	local shieldmaxstattable = {}
	local shieldcheckpenaltytable	= {}
	local shieldspellfailuretable = {}
	local maxstattable = {}
	local checkpenaltytable	= {}
	local spellfailuretable = {}

	--Populates penalty tables from armor / shields
	local shieldmaxstatcount = 1
	local shieldcheckpenaltycount = 1
	local spellfailurecount = 1
	local maxstatcount = 1
	local checkpenaltycount = 1
	for _,v in pairs(DB.getChildren(nodePC, 'inventorylist')) do
		local itemcarried = DB.getValue(v, 'carried', 0)
		local subtype = DB.getValue(v, 'subtype')
		local slot = DB.getValue(v, 'slot')
		local itemmaxstat = DB.getValue(v, 'maxstatbonus')
		local itemcheckpenalty = DB.getValue(v, 'checkpenalty')
		local itemspellfailure = DB.getValue(v, 'spellfailure')

		if itemcarried == 2 and (subtype == 'Shield' and (slot == 'Armor' or slot == 'shield')) then
			addtoTable(shieldmaxstattable,itemmaxstat)
			addtoTable(shieldcheckpenaltytable,itemcheckpenalty)
			addtoTable(shieldspellfailuretable,itemspellfailure)
		elseif itemcarried == 2 and (subtype ~= 'Shield' and slot == 'Armor') then
			addtoTable(maxstattable,itemmaxstat)
			addtoTable(checkpenaltytable,itemcheckpenalty)
			addtoTable(spellfailuretable,itemspellfailure)
		end
	end

	return shieldmaxstattable, shieldcheckpenaltytable, shieldspellfailuretable, maxstattable, checkpenaltytable, spellfailuretable
end

--Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--Argument: number light is medium encumbrance threshold for PC
--Argument: number light is heavy encumbrance threshold for PC
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
local function rawEncumbrancePenalties(nodePC, equipmentmaxstat, equipmentcheckpenalty, equipmentspellfailure)
	local light = DB.getValue(nodePC, 'encumbrance.lightload')
	local medium = DB.getValue(nodePC, 'encumbrance.mediumload')
	local total = DB.getValue(nodePC, 'encumbrance.total')

	local maxstatfromenc
	local checkpenaltyfromenc
	local spellfailurefromenc

	maxstatfromenc, checkpenaltyfromenc, spellfailurefromenc = encumbrancePenalties(light, medium, total)

	if notEmpty(maxstatfromenc) then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusfromenc', 'number', maxstatfromenc)
	end
	if notEmpty(checkpenaltyfromenc) then
		DB.setValue(nodePC, 'encumbrance.checkpenaltyfromenc', 'number', checkpenaltyfromenc)
	end
	if notEmpty(spellfailurefromenc) then
		DB.setValue(nodePC, 'encumbrance.spellfailurefromenc', 'number', spellfailurefromenc)
	end

	if notEmpty(maxstatfromenc) then
		maxstattoset = equipmentmaxstat + maxstatfromenc
	end
	if notEmpty(checkpenaltyfromenc) then
		checkpenaltytoset = equipmentcheckpenalty + checkpenaltyfromenc
	end
	if notEmpty(spellfailurefromenc) then
		spellfailuretoset = equipmentspellfailure + spellfailurefromenc
	end

	Debug.chat('full total',maxstattoset, checkpenaltytoset, spellfailuretoset)

	return maxstattoset, checkpenaltytoset, spellfailuretoset
end

local function minofTable(t,o)
	if table.getn(t) ~= 1 then
		o = math.min(unpack(t))
	else
		o = nil
	end

	return o
end

local function maxofTable(t,o)
	if table.getn(t) ~= 1 then
		o = math.max(unpack(t))
	else
		o = nil
	end

	return o
end

--Summary: Finds max stat and check penalty based on current enc / armor / shield data
--Argument: databasenode nodePC is the PC node
--Return: number holding armor max stat penalty
--Return: number holding armor check penalty
function computePenalties(nodePC)
	shieldmaxstattable, shieldcheckpenaltytable, shieldspellfailuretable, maxstattable, checkpenaltytable, spellfailuretable = rawArmorPenalties(nodePC)

	local shieldmaxstat
	local shieldcheckpenalty
	local shieldspellfailure

	local maxstat
	local checkpenalty
	local spellfailure

	local equipmentmaxstat
	local equipmentcheckpenalty
	local equipmentspellfailure

--	minofTable(shieldmaxstattable, shieldmaxstat)
--	minofTable(shieldcheckpenaltytable, shieldcheckpenalty)
--	maxofTable(shieldspellfailuretable, shieldspellfailure)

--	minofTable(maxstattable, maxstat)
--	minofTable(checkpenaltytable, checkpenalty)
--	maxofTable(spellfailuretable, spellfailure)

	if table.getn(shieldmaxstattable) ~= 0 then
		shieldmaxstat = math.min(unpack(shieldmaxstattable))
	else
		shieldmaxstat = 0
	end

	if table.getn(shieldcheckpenaltytable) ~= 0 then
		shieldcheckpenalty = math.min(unpack(shieldcheckpenaltytable))
	else
		shieldcheckpenalty = 0
	end

	if table.getn(shieldspellfailuretable) ~= 0 then
		shieldspellfailure = math.max(unpack(shieldspellfailuretable))
	else
		shieldspellfailure = 0
	end

	if table.getn(maxstattable) ~= 0 then
		maxstat = math.min(unpack(maxstattable))
	else
		maxstat = 0
	end

	if table.getn(checkpenaltytable) ~= 0 then
		checkpenalty = math.min(unpack(checkpenaltytable))
	else
		checkpenalty = 0
	end

	if table.getn(spellfailuretable) ~= 0 then
		spellfailure = math.max(unpack(spellfailuretable))
	else
		spellfailure = 0
	end

	equipmentmaxstat = shieldmaxstat + maxstat

	equipmentcheckpenalty = shieldcheckpenalty + checkpenalty

	equipmentspellfailure = shieldspellfailure + spellfailure

	Debug.chat('equipment totals',equipmentmaxstat, equipmentcheckpenalty, equipmentspellfailure)

	--add encumberance penalties to the mix
	rawEncumbrancePenalties(nodePC, equipmentmaxstat, equipmentcheckpenalty, equipmentspellfailure)

	Debug.chat('full total',maxstattoset, checkpenaltytoset, spellfailuretoset)

	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset

--	minofTable(maxstattable, maxstattoset)
--	minofTable(checkpenaltytable, checkpenaltytoset)
--	maxofTable(spellfailuretable, spellfailuretoset)
	
	return maxstattoset, checkpenaltytoset, spellfailuretoset
end