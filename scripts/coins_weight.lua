--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	This function recomputes the total weight field
function recomputeTotalWeight(nodeWin)
	local rActor = ActorManager.getActor('pc', nodeWin)
	local nodeChar = DB.findNode(rActor['sCreatureNode'])

	local nEqLoad = DB.getValue(nodeChar, 'encumbrance.load') * TEGlobals.getEncWeightUnit()

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'kg-full') then
		nEqLoad = DB.getValue(nodeChar, 'encumbrance.load')
	end

	local nTreasure = DB.getValue(nodeChar, 'encumbrance.treasure')
	local nTotal = nTreasure + nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.total', 'number', nTotalToSet)
end

---	Calculate weight of all coins and total value (in gp).
--	@param nodeChar databasenode of PC within charsheet
local function computeCoins(nodeChar)
	local nTotalCoins = 0
	local nWealth = 0

	for _,coin in pairs(DB.getChildren(nodeChar, 'coins')) do
		nTotalCoins = nTotalCoins + DB.getValue(coin, 'amount', 0)
		
		local sDenomination = string.lower(DB.getValue(coin, 'name', ''))
		local nCoinAmount = DB.getValue(coin, 'amount', 0) + DB.getValue(coin, 'amountA', 0)
		if sDenomination ~= '' then
			for k,v in pairs(TEGlobals.tDenominations) do
				if string.match(sDenomination, k) then
					nWealth = nWealth + (nCoinAmount * v)
				end
			end
		end
	end

	nTotalCoinWeight = (nTotalCoins / TEGlobals.nCoinsPerUnit) * TEGlobals.getEncWeightUnit()
	local nTotalCoinWeightToSet =	nTotalCoinWeight + 0.5 - (nTotalCoinWeight + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.treasure', 'number', nTotalCoinWeightToSet)
	DB.setValue(nodeChar, 'coins.coinstotalval', 'number', nWealth)
	
	recomputeTotalWeight(nodeChar)
end

--	This function is called when a coin field is changed
function onCoinsValueChanged(nodeChar)
	local rActor = ActorManager.getActor('pc', nodeChar)
	local nodeChar = DB.findNode(rActor['sCreatureNode'])
	computeCoins(nodeChar)
end