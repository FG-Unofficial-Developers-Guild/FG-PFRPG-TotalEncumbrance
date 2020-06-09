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

--Summary: Recomputes penalties and updates max stat and check penalty
--Arguments: nodeField - node of 'carried' when called from handler
function applyPenalties(nodeField)
	local nodePC = handleApplyPenaltiesArgs(nodeField)
	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset
	maxstattoset, checkpenaltytoset, spellfailuretoset = computePenalties(nodePC)

	DB.setValue(nodePC, 'encumbrance.armormaxstatbonus', 'number', maxstattoset)
	DB.setValue(nodePC, 'encumbrance.armorcheckpenalty', 'number', checkpenaltytoset)
	
	--enable armor encumbrance when needed
	if (maxstattoset ~= 0 or checkpenaltytoset ~= 0) or spellfailuretoset ~= 0 then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end
end

--Summary: Handles arguments of applyPenalties()
--Argument: potentially nil nodeField representing carried databasenode on newly carried / equipped / dropped item
--Return: appropriate object databasenode - should represent node of PC
function handleApplyPenaltiesArgs(nodeField)
	local nodePC
	
	if nodeField ~= nil then
		nodePC = nodeField.getChild( '....' )
	else
		local nodeWin = window.getDatabaseNode()
		local rActor = ActorManager.getActor('pc', nodeWin)
		nodePC = DB.findNode(rActor['sCreatureNode'])
	end
	return nodePC
end

--Summary: Finds the max stat and check penalty penalties based on medium and heavy encumbrance thresholds based on current total encumbrance
--Argument: number light is medium encumbrance threshold for PC
--Argument: number light is heavy encumbrance threshold for PC
--Argument: number total is current total encumbrance for PC
--Return: number for max stat penalty based solely on encumbrance (max stat, skill penalty, spell failure chance)
--Return: number for check penalty penalty based solely on encumbrance (max stat, skill penalty, spell failure chance)
--Return: number for spell failure chance based solely on encumbrance (max stat, skill penalty, spell failure chance)
function encumbrancePenalties(light, medium, total)
	if total > medium then -- heavy load
		return 1, -6, nil
	elseif total > light then -- medium load
		return 3, -3, nil
	else -- light load
		return nil, nil, nil
	end
end

--Summary: Finds max stat / check penalty tables with appropriate nonzero values
--Argument: databasenode nodePC is the PC node
--Return: table holding nonzero max stat penalties from armor / shields
--Return: table holding nonzero check penalty penalties from armor / shields
function rawArmorPenalties(nodePC)
	local maxstattable = {}
	local checkpenaltytable	= {}
	local spellfailuretable = {}

	--Populates penalty tables from armor / shields
	local maxstatcount = 1
	local checkpenaltycount = 1
	local spellfailurecount = 1
	for _,v in pairs(DB.getChildren(nodePC, 'inventorylist')) do
		local itemcarried = DB.getValue(v, 'carried', 0)
		local itemmaxstat = DB.getValue(v, 'maxstatbonus', 0)
		local itemcheckpenalty = DB.getValue(v, 'checkpenalty', 0)
		local itemspellfailure = DB.getValue(v, 'spellfailure', 0)

		if itemcarried == 2 then
			if itemmaxstat ~= 0 then
				maxstattable[maxstatcount] = itemmaxstat
				maxstatcount = maxstatcount + 1
			end
			if itemcheckpenalty ~= 0 then
				checkpenaltytable[checkpenaltycount] = itemcheckpenalty
				checkpenaltycount = checkpenaltycount + 1
			end
			if itemspellfailure ~= 0 then
				spellfailuretable[spellfailurecount] = itemspellfailure
				spellfailurecount = spellfailurecount + 1
			end
		end
	end

	return maxstattable, checkpenaltytable, spellfailuretable
end

--Summary: Appends encumbrance-based penalties to respective penalty tables
--Argument: databasenode nodePC is the PC node
--Argument: table holding nonzero max stat penalties from armor / shields
--Argument: table holding nonzero check penalty penalties from armor / shields
function rawEncumbrancePenalties(nodePC, maxstattable, checkpenaltytable, spellfailurefromenc)
	local light = DB.getValue( nodePC, 'encumbrance.lightload')
	local medium = DB.getValue( nodePC, 'encumbrance.mediumload')
	local total = DB.getValue( nodePC, 'encumbrance.total')
	
	local maxstatfromenc
	local checkpenaltyfromenc
	local spellfailurefromenc
	local maxstatfromenc, checkpenaltyfromenc, spellfailuretable = encumbrancePenalties(light, medium, total)
	DB.setValue(nodePC, 'encumbrance.armormaxstatbonusfromenc', 'number', maxstatfromenc)
	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromenc', 'number', checkpenaltyfromenc)
	
	local tblcount = table.getn(maxstattable)
	if maxstatfromenc ~= 0 then
		maxstattable[tblcount + 1] = maxstatfromenc
	end
	
	tblcount = table.getn(checkpenaltytable)
	if checkpenaltyfromenc ~= 0 then
		checkpenaltytable[tblcount + 1] = checkpenaltyfromenc
	end
end

--Summary: Finds max stat and check penalty based on current enc / armor / shield data
--Argument: databasenode nodePC is the PC node
--Return: number holding armor max stat penalty
--Return: number holding armor check penalty
function computePenalties(nodePC)
	local maxstattable = {}
	local checkpenaltytable = {}
	local spellfailuretable = {}
	maxstattable, checkpenaltytable, spellfailuretable = rawArmorPenalties(nodePC)
	rawEncumbrancePenalties(nodePC, maxstattable, checkpenaltytable, spellfailuretable)
	
	local maxstattoset
	local checkpenaltytoset
	local spellfailuretoset

	if table.getn(maxstattable) ~= 0 then
		maxstattoset = math.min(unpack(maxstattable))
	else
		maxstattoset = 0
	end
	
	if table.getn(checkpenaltytable) ~= 0 then
		checkpenaltytoset = math.min(unpack(checkpenaltytable))
	else
		checkpenaltytoset = 0
	end
	
	if table.getn(spellfailuretable) ~= 0 then
		spellfailuretoset = math.max(unpack(spellfailuretable))
	else
		spellfailuretoset = 0
	end
	
	return maxstattoset, checkpenaltytoset, spellfailuretoset
end