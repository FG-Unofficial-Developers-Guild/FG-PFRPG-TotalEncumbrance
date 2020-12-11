--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--- Finds nodeChar for each player character in partyinformation and recalculates their carrying capacities.
--	Carrying capacity recalculation is triggered by:
--	reducing stradj by 1 and then returning it back to its original value.
local function onEncOptionChanged()
	if User.isHost() then
		for _,v in pairs(DB.getChildren('partysheet.partyinformation')) do
			local sClass, sRecord = DB.getValue(v, 'link')
			if sClass == 'charsheet' and sRecord then
				local nodeChar = DB.findNode(sRecord)
				if nodeChar then
					local nStrAdj = DB.getValue(nodeChar, 'encumbrance.stradj')
					DB.setValue(nodeChar, 'encumbrance.stradj', 'number', nStrAdj - 1)
					DB.setValue(nodeChar, 'encumbrance.stradj', 'number', nStrAdj)
				end
			end
		end
	end
end

---	Watches for changes at the listed database nodes.
function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath('options.ENCUMBRANCE_UNIT'), 'onUpdate', onEncOptionChanged)
	end
end
