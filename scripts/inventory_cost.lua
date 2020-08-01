--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-function onInit()
	if User.isHost() then
		DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.cost'), 'onUpdate', calculateInvCost)
		DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.isidentified'), 'onUpdate', calculateInvCost)
		DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildDeleted', calculateInvCost)
	end
end

---  This function posts a message in the chat window if the item cost contains a hyphen or a slash.
local function announceImproperCost(nodeChar, sItemName)
	local nAnnounce = DB.getValue(nodeChar, 'coins.costerrorannouncer', 1)

	if (OptionsManager.isOption('WARN_COST', 'subtle') or OptionsManager.isOption('WARN_COST', 'on')) and nAnnounce == 1 then
		local sHoldingPc = DB.getValue(nodeChar, 'name', 'unknown character')

		ChatManager.SystemMessage(sHoldingPc..': "' .. sItemName .. '" has its cost entered wrong and is being ignored.')
	end
end

---	Convert everything to main currency and drop any non-numerical characters. ('300gp' -> 300) ('30pp' -> 300) ('3sp' -> .3).
local function processItemCost(nodeChar, sItemCost, sItemName)
	if string.match(sItemCost, '%-') or string.match(sItemCost, '%/') then
		announceImproperCost(nodeChar, sItemName)

		return 0
	end

	local sTrimmedItemCost = sItemCost:gsub('[^0-9.-]', '')
	if sTrimmedItemCost then
		nTrimmedItemCost = tonumber(sTrimmedItemCost)
		for k,v in pairs(TEGlobals.tDenominations) do
			if string.match(sItemCost, k) then
				return nTrimmedItemCost * v
			end
		end
	end

	return 0
end

---	This function calculates the total value of every identified item in the player's inventory.
--	It then writes it to the DB for use during net worth calculation.
function calculateInvCost(nodeChar)
	local nTotalInvVal = 0
	for _,v in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local nItemIDed = DB.getValue(v, 'isidentified', 0)
		local sItemName = string.lower(DB.getValue(v, 'name', ''))
		local sItemCost = string.lower(DB.getValue(v, 'cost'))
		local nItemCount = DB.getValue(v, 'count', 1)

		if sItemCost and nItemIDed ~= 0 then
			nItemCost = processItemCost(nodeChar, sItemCost, sItemName)
			nTotalInvVal = nTotalInvVal + (nItemCount * nItemCost)
		end
	end
	
	DB.setValue(nodeChar, 'coins.inventorytotal', 'number', nTotalInvVal)
end