--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	This function facilitates imperial/metric options
function recomputeTotalWeight(nodeChar)
	local rActor = ActorManager.getActor('pc', nodeChar)
	local nodeChar = DB.findNode(rActor['sCreatureNode'])

	local nEqLoad = DB.getValue(nodeChar, 'encumbrance.load') * TEGlobals.getEncWeightUnit()

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'kg-full') then
		nEqLoad = DB.getValue(nodeChar, 'encumbrance.load')
	end

	local nTotal = nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.total', 'number', nTotalToSet)
end

---	Calculate weight of all coins and total value (in gp).
--	@param nodeChar databasenode of PC within charsheet
local function computeCoins(nodeChar)
	local nTotalCoins = 0
	local nWealth = 0

	for _,coin in pairs(DB.getChildren(nodeChar, 'coins')) do
		local sDenomination = string.lower(DB.getValue(coin, 'name', ''))
		local nCoinAmount = DB.getValue(coin, 'amount', 0) + DB.getValue(coin, 'amountA', 0)
		if sDenomination ~= '' then
			for k,v in pairs(TEGlobals.tDenominations) do
				if string.match(sDenomination, k) then
					nWealth = nWealth + (nCoinAmount * v)
				end
			end
		end
		nTotalCoins = nTotalCoins + nCoinAmount
	end

	local nTotalCoinWeightToSet = math.floor((nTotalCoins / TEGlobals.nCoinsPerUnit) * TEGlobals.getEncWeightUnit())
	if nTotalCoinWeightToSet then
		local nodeOtherCoins
		for _,nodeItem in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
			local sItemName = string.lower(DB.getValue(nodeItem, 'name', ''))
			if sItemName == 'coins' then
				nodeOtherCoins = nodeItem
			end
		end
		if nTotalCoinWeightToSet > 0 and not nodeOtherCoins then nodeOtherCoins = DB.createChild(nodeChar.getChild('inventorylist')) end
		if nTotalCoinWeightToSet == 0 and nodeOtherCoins then
			nodeOtherCoins.delete()
		elseif nodeOtherCoins then
			DB.setValue(nodeOtherCoins, 'name', 'string', 'Coins')
			DB.setValue(nodeOtherCoins, 'weight', 'number', nTotalCoinWeightToSet)
			DB.setValue(nodeOtherCoins, 'description', 'formattedtext', '<p>The standard coin weighs about a third of an ounce (50 to the pound).</p>')
		end
	end

	DB.setValue(nodeChar, 'coins.coinstotalval', 'number', nWealth)
	
	recomputeTotalWeight(nodeChar)
end

--	This function is called when a coin field is changed
function onCoinsValueChanged(nodeChar)
	local rActor = ActorManager.getActor('pc', nodeChar)
	local nodeChar = DB.findNode(rActor['sCreatureNode'])
	computeCoins(nodeChar)
end