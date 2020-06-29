--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.carried'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.weight'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.cost'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.count'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.isidentified'), 'onUpdate', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildDeleted', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildAdded', applyPenalties)
	DB.addHandler(DB.getPath('charsheet.*.hp'), 'onChildUpdate', applyPenalties)
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', applyPenalties)
	DB.addHandler(DB.getPath('combattracker.list'), 'onChildDeleted', applyPenalties)
end

--	Summary: Handles arguments of applyPenalties()
--	Argument: potentially nil node representing carried databasenode on newly carried / equipped / dropped item
--	Return: appropriate object databasenode - should represent node of PC
local function handleApplyPenaltiesArgs(node)
	local nodePC
	local rActor

	if node.getParent().getName() == 'charsheet' then
		nodePC = node
	elseif node.getName() == 'inventorylist' then
		nodePC = node.getParent()
	elseif node.getName() == 'carried' then
		nodePC = node.getChild( '....' )
	elseif node.getParent().getName() == 'inventorylist' then
		nodePC = node.getChild( '...' )
	elseif node.getName() == 'hp' then
		nodePC = node.getParent()
	elseif node.getName() == 'effects' then
		rActor = ActorManager.getActor('ct', node.getParent())
		nodePC = DB.findNode(rActor['sCreatureNode'])
	end

	if not rActor then
		rActor = ActorManager.getActor("pc", nodePC)
	end

	return nodePC, rActor
end

--	Summary: Determine the total bonus to character's speed from effects
--	Argument: rActor containing the PC's charsheet and combattracker nodes
--	Return: total bonus to speed from effects formatted as 'SPEED: n' in the combat tracker
local function getSpeedEffects(nodePC, rActor)
	if not rActor then
		return 0, false
	end

	local bSpeedHalved = false
	local bSpeedZero = false

	if
		EffectManager35E.hasEffectCondition(rActor, "Exhausted")
		or EffectManager35E.hasEffectCondition(rActor, "Entangled")
	then
		bSpeedHalved = true
	end

	if
		EffectManager35E.hasEffectCondition(rActor, "Grappled")
		or EffectManager35E.hasEffectCondition(rActor, "Paralyzed")
		or EffectManager35E.hasEffectCondition(rActor, "Petrified")
		or EffectManager35E.hasEffectCondition(rActor, "Pinned")
	then
		bSpeedZero = true
	end

	--	Check if the character is disabled (at zero remaining hp)
	if DB.getValue(nodePC, "hp.total", 0) == DB.getValue(nodePC, "hp.wounds", 0) then
		bSpeedHalved = true
	end

	local nSpeedAdjFromEffects = EffectManager35E.getEffectsBonus(rActor, 'SPEED', true)

	return nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero
end

--	Summary: converts strings like 300gp to 300 or 30pp to 300.
local function stringToNumber(sItemCost)
	local nDenomination = 0
	if string.match(sItemCost, 'gp') then
		nDenomination = 1
	elseif string.match(sItemCost, 'sp') then
		nDenomination = 2
	elseif string.match(sItemCost, 'cp') then
		nDenomination = 3
	elseif string.match(sItemCost, 'pp') then
		nDenomination = 4
	end

	local sItemCost = sItemCost:gsub('[^0-9.-]', '', x)
	sItemCost = sItemCost:gsub(',', '', x)
	nItemCost = tonumber(sItemCost)

	if nDenomination ~= 0 then
		if nDenomination == 2 then
			nItemCost = nItemCost * .1
		end
		if nDenomination == 3 then
			nItemCost = nItemCost * .01
		end
		if nDenomination == 4 then
			nItemCost = nItemCost * 10
		end
	else
		nItemCost = 0
	end

	return nItemCost
end

---	Returns a string formatted with commas inserted every three digits from the left side of the decimal place
--	@param n The number to be reformatted.
local function formatCurrency(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)',TEGlobals.sDigitDivider):reverse())..right
end

--	Summary: Finds max stat / check penalty tables with appropriate nonzero values
--	Argument: databasenode nodePC is the PC node
--	Argument: table tMaxStat is empty table to represent max stat penalties
--	Argument: table tEqCheckPenalty is empty table to represent check penalty penalties
--	Argument: table tSpellFailure is empty table to represent spell failure penalties
--	Return: nil, however table arguments are directly updated
local function rawArmorPenalties(nodePC, tMaxStat, tEqCheckPenalty, tSpellFailure, tSpeed20, tSpeed30)
	local nItemCarried
	local nItemMaxStat
	local nItemCheckPenalty
	local nItemSpellFailure
	local nItemSpeed20
	local nItemSpeed30
	local nItemIDed
	local nItemCount
	local sItemName
	local sItemType
	local sItemSubtype
	local sItemCost

	local tLtArmor = {}
	local tMedArmor = {}
	local tHeavyArmor = {}
	local tShield = {}

	local nTotalInvVal = 0
--	local nTotalInvVal = getTotalCoinWealth(nodePC)

	local bClumsyArmor = false

	for _,v in pairs(DB.getChildren(nodePC, 'inventorylist')) do
		nItemCarried = DB.getValue(v, 'carried', 0)
		nItemMaxStat = DB.getValue(v, 'maxstatbonus', 0)
		nItemCheckPenalty = DB.getValue(v, 'checkpenalty', 0)
		nItemSpellFailure = DB.getValue(v, 'spellfailure', 0)
		nItemSpeed20 = DB.getValue(v, 'speed20', 0)
		nItemSpeed30 = DB.getValue(v, 'speed30', 0)
		nItemIDed = DB.getValue(v, 'isidentified', 1)
		nItemCount = DB.getValue(v, 'count', 1)
		sItemName = string.lower(DB.getValue(v, 'name', ''))
		sItemType = string.lower(DB.getValue(v, 'type', ''))
		sItemSubtype = string.lower(DB.getValue(v, 'subtype', ''))
		sItemCost = string.lower(DB.getValue(v, 'cost', ''))

		if nItemIDed ~= 0 then
			nItemCost = stringToNumber(sItemCost)
			nTotalInvVal = nTotalInvVal + (nItemCount * nItemCost)
		end

		if nItemCarried == 2 then
			for _,v in pairs(TEGlobals.tClumsyArmorTypes) do
				if string.find(sItemName, string.lower(v)) then
					bClumsyArmor = true
					break
				end
			end

			if
				nItemMaxStat ~= 0
				or bClumsyArmor
			then
				table.insert(tMaxStat, nItemMaxStat)
			end

			if nItemCheckPenalty ~= 0 then
				table.insert(tEqCheckPenalty, nItemCheckPenalty)
			end

			if nItemSpellFailure ~= 0 then
				table.insert(tSpellFailure, nItemSpellFailure)
			end

			if nItemSpeed20 ~= 0 then
				table.insert(tSpeed20, nItemSpeed20)
			end

			if nItemSpeed30 ~= 0 then
				table.insert(tSpeed30, nItemSpeed30)
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
				elseif
					sItemSubtype == 'shield'
					or sItemSubtype == 'magic shield'
				then
					table.insert(tShield, 'i like turtles')
				end
			end
		end
	end


	local sTotalInvVal = formatCurrency(nTotalInvVal)
	DB.setValue(nodePC, 'coins.inventorytotal', 'string', 'Item Total: '..sTotalInvVal..' gp')
--	DB.setValue(nodePC, 'coins.wealthtotal', 'string', 'Wealth Total: '..nWealthVal..' gp')

	local nMaxStatFromArmor
	local nCheckPenaltyFromArmor
	local nSpeed20FromArmor
	local nSpeed30FromArmor

	if table.getn(tMaxStat) ~= 0 then
		nMaxStatFromArmor = math.min(unpack(tMaxStat)) -- this would pick the lowest max dex if there is multi-equipped armor
	else
		nMaxStatFromArmor = -1
	end

	DB.setValue(nodePC, 'encumbrance.maxstatbonusfromarmor', 'number', nMaxStatFromArmor ~= nil and nMaxStatFromArmor or -1)

	if table.getn(tEqCheckPenalty) ~= 0 then
		nCheckPenaltyFromArmor = LibTotalEncumbrance.tableSum(tEqCheckPenalty) -- this would sum penalties on multi-equipped armor
	else
		nCheckPenaltyFromArmor = 0
	end

	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromarmor', 'number', nCheckPenaltyFromArmor ~= nil and nCheckPenaltyFromArmor or 0)

	if table.getn(tSpeed20) ~= 0 then
		nSpeed20FromArmor = math.min(unpack(tSpeed20)) -- this gets min speed from multi-equipped armor
	else
		nSpeed20FromArmor = 0
	end

	if table.getn(tSpeed30) ~= 0 then
		nSpeed30FromArmor = math.min(unpack(tSpeed30)) -- this gets min speed from multi-equipped armor
	else
		nSpeed30FromArmor = 0
	end

	DB.setValue(nodePC, 'encumbrance.speed20fromarmor', 'number', nSpeed20FromArmor ~= nil and nSpeed20FromArmor or 0)
	DB.setValue(nodePC, 'encumbrance.speed30fromarmor', 'number', nSpeed30FromArmor ~= nil and nSpeed30FromArmor or 0)

	local nHeavyArmorCount = table.getn(tHeavyArmor)
	local nMedArmorCount = table.getn(tMedArmor)
	local nLtArmorCount = table.getn(tLtArmor)
	local nShieldCount = table.getn(tShield)

	if
		nHeavyArmorCount ~= 0
		and nHeavyArmorCount ~= nil
	then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 3)
	elseif
			nMedArmorCount ~= 0
			and nMedArmorCount ~= nil
	then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 2)
	elseif
		nLtArmorCount ~= 0
		and nLtArmorCount ~= nil
	then
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.armorcategory', 'number', 0)
	end

	if
		nShieldCount ~= 0
		and nShieldCount ~= nil
	then
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
local function encumbrancePenalties(nodePC, light, medium, total)
	if total > medium then -- heavy load
		DB.setValue(nodePC, 'encumbrance.encumbrancelevel', 'number', 3)
		return TEGlobals.nHeavyMaxStat, TEGlobals.nHeavyCheckPenalty, nil
	elseif total > light then -- medium load
		DB.setValue(nodePC, 'encumbrance.encumbrancelevel', 'number', 2)
		return TEGlobals.nMediumMaxStat, TEGlobals.nMediumCheckPenalty, nil
	else -- light load
		DB.setValue(nodePC, 'encumbrance.encumbrancelevel', 'number', 1)
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
	local light = DB.getValue(nodePC, 'encumbrance.lightload', 0)
	local medium = DB.getValue(nodePC, 'encumbrance.mediumload', 0)
	local total = DB.getValue(nodePC, 'encumbrance.total', 0)

	local nMaxStatFromEnc, nCheckPenaltyFromEnc, nSpellFailureFromEnc = encumbrancePenalties(nodePC, light, medium, total)

	DB.setValue(nodePC, 'encumbrance.maxstatbonusfromenc', 'number', nMaxStatFromEnc ~= nil and nMaxStatFromEnc or -1)
	DB.setValue(nodePC, 'encumbrance.checkpenaltyfromenc', 'number', nCheckPenaltyFromEnc ~= nil and nCheckPenaltyFromEnc or 0)

	if OptionsManager.isOption('WEIGHT_ENCUMBRANCE', 'on') then -- if weight encumbrance penalties are enabled in options
		if nMaxStatFromEnc ~= nil then
			table.insert(tMaxStat, nMaxStatFromEnc)
		end

		if nCheckPenaltyFromEnc ~= nil then
			table.insert(tCheckPenalty, nCheckPenaltyFromEnc)
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
local function computePenalties(nodePC)
	local tMaxStat = {}
	local tEqCheckPenalty = {}
	local tCheckPenalty = {}
	local tSpellFailure = {}
	local tSpeed20 = {}
	local tSpeed30 = {}

	rawArmorPenalties(nodePC, tMaxStat, tEqCheckPenalty, tSpellFailure, tSpeed20, tSpeed30)

	if table.getn(tEqCheckPenalty) ~= 0 then
		table.insert(tCheckPenalty, LibTotalEncumbrance.tableSum(tEqCheckPenalty)) -- add equipment total to overall table for comparison with encumbrance
	end

	rawEncumbrancePenalties(nodePC, tMaxStat, tCheckPenalty, tSpellFailure)

	local nMaxStatToSet
	local nCheckPenaltyToSet
	local nSpellFailureToSet
	local nSpeedPenalty20
	local nSpeedPenalty30

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

	if table.getn(tSpeed20) ~= 0 then
		 nSpeedPenalty20 = math.min(unpack(tSpeed20))
	else
		 nSpeedPenalty20 = 0
	end

	if table.getn(tSpeed30) ~= 0 then
		 nSpeedPenalty30 = math.min(unpack(tSpeed30))
	else
		 nSpeedPenalty30 = 0
	end

	--compute speed including total encumberance speed penalty
	local tEncumbranceSpeed = TEGlobals.tEncumbranceSpeed
	local nSpeedBase = DB.getValue(nodePC, "speed.base", 0)
	local nSpeedTableIndex = nSpeedBase / 5

	nSpeedTableIndex = nSpeedTableIndex + 0.5 - (nSpeedTableIndex + 0.5) % 1

	local nSpeedPenaltyFromEnc = 0

	if tEncumbranceSpeed[nSpeedTableIndex] ~= nil then
		nSpeedPenaltyFromEnc = tEncumbranceSpeed[nSpeedTableIndex] - nSpeedBase
	end

	DB.setValue(nodePC, 'encumbrance.speedfromenc', 'number', nSpeedPenaltyFromEnc ~= nil and nSpeedPenaltyFromEnc or 0)

	local bApplySpeedPenalty = true

	if CharManager.hasTrait(nodePC, "Slow and Steady") then
		bApplySpeedPenalty = false
	end

	local nSpeedPenalty = 0

	if bApplySpeedPenalty then
		if
			nSpeedBase >= 30
			and nSpeedPenalty30 > 0
		then
			nSpeedPenalty = nSpeedPenalty30 - 30
		elseif
			nSpeedBase < 30
			and nSpeedPenalty20 > 0
		then
			nSpeedPenalty = nSpeedPenalty20 - 20
		end
	end

	local nEncumbranceLevel = DB.getValue(nodePC, 'encumbrance.encumbrancelevel', 0)

	if -- if weight encumbrance penalties are enabled in options and player is encumbered
		OptionsManager.isOption('WEIGHT_ENCUMBRANCE', 'on')
		and nEncumbranceLevel > 1
	then
		if
			nSpeedPenalty ~= 0
			and nSpeedPenaltyFromEnc ~= 0
		then
			nSpeedPenalty = math.min(nSpeedPenaltyFromEnc, nSpeedPenalty)
		elseif nSpeedPenaltyFromEnc then
			nSpeedPenalty = nSpeedPenaltyFromEnc
		end
	end

	return nMaxStatToSet, nCheckPenaltyToSet, nSpellFailureToSet, nSpeedPenalty, nSpeedBase
end

--	Summary: Recomputes penalties and updates max stat and check penalty
--	Arguments: node - node of 'carried' when called from handler
function applyPenalties(node)
	local nodePC, rActor = handleApplyPenaltiesArgs(node)

	local nMaxStatToSet, nCheckPenaltyToSet, nSpellFailureToSet, nSpeedPenalty, nSpeedBase = computePenalties(nodePC)

	--	enable armor encumbrance when needed
	if
		nMaxStatToSet ~= -1
		or nCheckPenaltyToSet ~= 0
		or nSpellFailureToSet ~= 0
	then
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
	else
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 1)
		DB.setValue(nodePC, 'encumbrance.armormaxstatbonusactive', 'number', 0)
	end

	DB.setValue(nodePC, 'encumbrance.armormaxstatbonus', 'number', nMaxStatToSet)
	DB.setValue(nodePC, 'encumbrance.armorcheckpenalty', 'number', nCheckPenaltyToSet)
	DB.setValue(nodePC, 'encumbrance.armorspellfailure', 'number', nSpellFailureToSet)

	DB.setValue(nodePC, "speed.armor", "number", nSpeedPenalty)

	local nSpeedAdjFromEffects, bSpeedHalved, bSpeedZero = getSpeedEffects(nodePC, rActor)

	--	recalculate total speed from all inputs
	local nSpeedToSet = nSpeedBase + nSpeedPenalty + nSpeedAdjFromEffects + DB.getValue(nodePC, "speed.misc", 0) + DB.getValue(nodePC, "speed.temporary", 0)

	--	round to nearest 5 (or 1 as specified in options list - SPEED_INCREMENT)
--	if OptionsManager.isOption('SPEED_INCREMENT', '5') then
		nSpeedToSet = ((nSpeedToSet / 5) + 0.5 - ((nSpeedToSet / 5) + 0.5) % 1) * 5
--	else
--		nSpeedToSet = nSpeedToSet + 0.5 - (nSpeedToSet + 0.5) % 1
--	end

	if bSpeedZero then
		nSpeedToSet = 0
	elseif bSpeedHalved then
		nSpeedToSet = nSpeedToSet / 2
	end

	DB.setValue(nodePC, "speed.final", "number", nSpeedToSet)
	DB.setValue(nodePC, "speed.total", "number", nSpeedToSet)
end
