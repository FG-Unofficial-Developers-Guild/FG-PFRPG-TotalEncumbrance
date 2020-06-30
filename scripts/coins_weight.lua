--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	Initialization
-- function onInit()
	-- if User.isHost() then
		-- Comm.registerSlashHandler('ccweight', computeCoinsWeight)
	-- end
-- end

--	This function recomputes the total weight field
function recomputeTotalWeight(nodeWin)
	local rActor = ActorManager.getActor('pc', nodeWin)
	local nodePC = DB.findNode(rActor['sCreatureNode'])

	local nUnit = LibTotalEncumbrance.getEncWeightUnit()
	local nEqLoad = DB.getValue(nodePC, 'encumbrance.load') * nUnit
	local nTreasure = DB.getValue(nodePC, 'encumbrance.treasure')
	local nTotal = nTreasure + nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodePC, 'encumbrance.total', 'number', nTotalToSet)
end

--	This function is manualy called with the command /ccweight (DM only)
-- function computeCoinsWeight(command, parameters)
	-- if User.isHost() then
		-- for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			-- local sClass, sRecord = DB.getValue(v, 'link')
			-- Debug.chat( sRecord );
			-- if sClass == 'charsheet' and sRecord then
				-- local nodePC = DB.findNode(sRecord)
				-- if nodePC then
					-- computePCCoinsWeigh(nodePC)
				-- end
			-- end
		-- end
	-- end
-- end

--	This function is called when a coin field is called
function onCoinsValueChanged(nodeWin)
	local rActor = ActorManager.getActor('pc', nodeWin )
	local nodePC = DB.findNode(rActor['sCreatureNode'])
	computePCCoinsWeigh(nodePC)
end

---	Computes the weight of all coins in 'carried' fields.
function computePCCoinsWeigh(nodePC)
	local nTotalCoins = 0
	for _,coin in pairs(DB.getChildren(nodePC, 'coins')) do
		nTotalCoins = nTotalCoins + DB.getValue(coin, 'amount', 0)
	end

	if OptionsManager.isOption('COIN_WEIGHT', 'on') then -- if coin weight calculation is enabled
		local nUnit = LibTotalEncumbrance.getEncWeightUnit()
		nTotalCoinWeight = math.floor(nTotalCoins / (TEGlobals.nCoinsPerUnit * nUnit))
	else
		nTotalCoinWeight = 0
	end

	DB.setValue(nodePC, 'encumbrance.treasure', 'number', nTotalCoinWeight)
end