--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local function onEncumbranceChanged(nodeChar)
	if CharManagerTE then
		CharManagerTE.updateEncumbrance(nodeChar)
		CharManagerTE.calcItemArmorClass(nodeChar)
	end
end

--	This function facilitates imperial/metric options
function recomputeTotalWeight(nodeChar)
	local nEqLoad = DB.getValue(nodeChar, 'encumbrance.load') * TEGlobals.getEncWeightUnit()

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'kg-full') then
		nEqLoad = DB.getValue(nodeChar, 'encumbrance.load')
	end

	local nTotal = nEqLoad
	local nTotalToSet =	nTotal + 0.5 - (nTotal + 0.5) % 1

	DB.setValue(nodeChar, 'encumbrance.total', 'number', nTotalToSet)
	onEncumbranceChanged(nodeChar)
end

---	Calculate weight of all coins and total value (in gp).
--	@param nodeChar databasenode of PC within charsheet
local function computeCoins(nodeChar)
	local nTotalCoins = 0
	local nWealth = 0

	for _,nodeCoinSlot in pairs(DB.getChildren(nodeChar, 'coins')) do
		local sDenomination = string.lower(DB.getValue(nodeCoinSlot, 'name', ''))
		local nCoinAmount = DB.getValue(nodeCoinSlot, 'amount', 0)
		
		-- upgrade method to support removing second coins column
		if DB.getValue(nodeCoinSlot, 'amountA') and DB.getValue(nodeCoinSlot, 'amountA', 0) ~= 0 then
			nCoinAmount = nCoinAmount + DB.getValue(nodeCoinSlot, 'amountA', 0)
			DB.setValue(nodeCoinSlot, 'amount', 'number', nCoinAmount)
			if DB.getValue(nodeCoinSlot, 'amountA') then nodeCoinSlot.getChild('amountA').delete() end
		end
		
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
	computeCoins(nodeChar)
end