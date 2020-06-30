--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

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

function onEncOptionChanged()
	if User.isHost() then
		for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			local sClass, sRecord = DB.getValue(v, 'link')
			if sClass == 'charsheet' and sRecord then
				local nodePC = DB.findNode(sRecord)
				if nodePC then
					RealEncumbrance.applyPenalties(nodePC)
					local update = DB.getValue(nodePC, "encumbrance.stradj")
					DB.setValue(nodePC, "encumbrance.stradj", 'number', -1)
					DB.setValue(nodePC, "encumbrance.stradj", 'number', update)
				end
			end
		end
	end
end

function onCoinWeightOptionChanged()
	if User.isHost() then
		for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			local sClass, sRecord = DB.getValue(v, 'link')
			if sClass == 'charsheet' and sRecord then
				local nodePC = DB.findNode(sRecord)
				if nodePC then
					CoinsWeight.onCoinsValueChanged(nodePC)
				end
			end
		end
	end
end