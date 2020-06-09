-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	 local node = getDatabaseNode();
	 DB.addHandler(DB.getPath(node, "*.carried"), "onUpdate", TotalEncumbranceChanged);
end

function onClose()
	 local node = getDatabaseNode();
	 DB.removeHandler(DB.getPath(node, "*.carried"), "onUpdate", TotalEncumbranceChanged);
end

function TotalEncumbranceChanged()
	local nodeWin = window.getDatabaseNode()
    local rActor = ActorManager.getActor("pc", nodeWin )
    local nodePC = DB.findNode(rActor['sCreatureNode'])
	-- Debug.chat('1', nodePC.getParent() )
		nodePC = ( nodePC.getParent() ).getName() == 'inventorylist' and ( nodePC.getParent() ).getParent() or nodePC

    local total = DB.getValue( nodePC.getPath() .. '.encumbrance.total' )
    local medium = DB.getValue( nodePC.getPath() .. '.encumbrance.mediumload' )
    local heavy = DB.getValue( nodePC.getPath() .. '.encumbrance.heavyload' )

    local maxstatfromarmor = DB.getValue( nodePC.getPath() .. '.encumbrance.armormaxstatbonus' )
    local maxstatfromenc
	local maxstattoset
	
	local checkpenalty = DB.getValue( nodePC.getPath() .. '.encumbrance.armorcheckpenalty' )
	local checkpenaltyfromenc
	local checkpenaltytoset
	
	-- Debug.chat('2',nodePC.getPath())
	
	--define penalties
	if total >= heavy then
        maxstatfromenc = 1
        checkpenaltyfromenc = -6
    elseif total >= medium then
        maxstatfromenc = 3
        checkpenaltyfromenc = -3
    else
        maxstatfromenc = 0
		checkpenaltyfromenc = 0
    end
	
	--eliminate potential zero results from max stat
	if (maxstatfromarmor == nil or maxstatfromarmor == 0) and  (maxstatfromenc == nil or maxstatfromenc == 0) then
		maxstattoset = 0
	elseif maxstatfromarmor == nil or maxstatfromarmor == 0 then
		maxstattoset = maxstatfromenc
	elseif maxstatfromenc == nil or maxstatfromenc == 0 then
		maxstattoset = maxstatfromarmor
	else
		maxstattoset = math.min(maxstatfromarmor, maxstatfromenc)
	end
	
	--eliminate potential zero results from check penalty
	if (checkpenalty == nil or checkpenalty == 0) and  (checkpenaltyfromenc == nil or checkpenaltyfromenc == 0) then
		checkpenaltytoset = checkpenaltyfromenc
	elseif checkpenaltyfromenc == nil or checkpenaltyfromenc == 0 then
		checkpenaltytoset = checkpenalty
	else
		checkpenaltytoset = math.min(checkpenalty, checkpenaltyfromenc)
	end

	DB.setValue( nodePC.getPath() .. '.encumbrance.armormaxstatbonusfromenc', 'number', maxstatfromenc )
	DB.setValue( nodePC.getPath() .. '.encumbrance.checkpenaltyfromenc', 'number', checkpenaltyfromenc )
	DB.setValue( nodePC.getPath() .. '.encumbrance.armormaxstatbonus', 'number', maxstattoset )
    DB.setValue( nodePC.getPath() .. '.encumbrance.armorcheckpenalty', 'number', checkpenaltytoset )
	
    DB.setValue( nodePC.getPath() .. '.encumbrance.armormaxstatbonusactive', 'number', 1 )
	-- Debug.chat('checkpenalty',checkpenaltytoset,checkpenalty,checkpenaltyfromenc)
	-- Debug.chat('maxstatfromarmor',maxstattoset,maxstatfromarmor,maxstatfromenc)

end

-- This function queries the total encumbrance
function onValueChanged()

    TotalEncumbranceChanged()
end