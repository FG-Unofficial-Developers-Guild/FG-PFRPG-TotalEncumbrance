--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	Watches for changes at the listed database nodes.
function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath('options.WEIGHT_ENCUMBRANCE'), 'onUpdate', onEncOptionChanged)
		DB.addHandler(DB.getPath('options.ENCUMBRANCE_UNIT'), 'onUpdate', onEncOptionChanged)
		DB.addHandler(DB.getPath('options.ENCUMBRANCE_COLORS'), 'onUpdate', onEncOptionChanged)
		DB.addHandler(DB.getPath('options.COIN_WEIGHT'), 'onUpdate', onCoinWeightOptionChanged)
		DB.addHandler(DB.getPath('options.SPEED_INCREMENT'), 'onUpdate', onEncOptionChanged)
		DB.addHandler(DB.getPath('options.CALCULATE_INVENTORY_VALUE'), 'onUpdate', onEncOptionChanged)
	end
end

--- Finds nodePC for each player character in partyinformation and recalculates their encumbrance penalties and carrying capacities.
--	Encumbrance is recalculated by calling applyPenalties from real_encumbrance.
--	Carrying capacity recalculation is triggered by setting stradj to -1 and then back to its original value.
function onEncOptionChanged()
	if User.isHost() then
		for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			local sClass, sRecord = DB.getValue(v, 'link')
			if sClass == 'charsheet' and sRecord then
				local nodePC = DB.findNode(sRecord)
				if nodePC then
					RealEncumbrance.applyPenalties(nodePC)
					local update = DB.getValue(nodePC, 'encumbrance.stradj')
					DB.setValue(nodePC, 'encumbrance.stradj', 'number', -1)
					DB.setValue(nodePC, 'encumbrance.stradj', 'number', update)
				end
			end
		end
	end
end

--- Finds nodePC for each player character in partyinformation and recalculates the weight of their coins.
--	Coin weight is recalculated by calling onCoinsValueChanged from coins_weight.
function onCoinWeightOptionChanged()
	if User.isHost() then
		for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			local sClass, sRecord = DB.getValue(v, 'link')
			if sClass == 'charsheet' and sRecord then
				local nodePC = DB.findNode(sRecord)
				if nodePC then
					CoinsWeight.onCoinsValueChanged(nodePC)
					CoinsWeight.recomputeTotalWeight(nodePC)
				end
			end
		end
	end
end