--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---  This function posts a message in the chat window if the item cost contains a hyphen or a slash.
local chat_announce_state = 1
local function chat_message_cost_error(node_pc, string_item_name, is_using_lowest_cost)
	if chat_announce_state == 1 and not OptionsManager.isOption('WARN_COST', 'off') then
		local string_pc_name = DB.getValue(node_pc, 'name', Interface.getString("char_name_unknown"))
		if is_using_lowest_cost then
			ChatManager.SystemMessage(string.format(Interface.getString("item_cost_error_range"), string_pc_name, string_item_name))
		else
			ChatManager.SystemMessage(string.format(Interface.getString("item_cost_error_wrong"), string_pc_name, string_item_name))
		end
	end
end

---	Convert to gp, dropping non-numerical characters. ('300gp' -> 300) ('30pp' -> 300) ('3sp' -> .3).
local function convert_denominations(node_pc, string_item_cost, string_item_name)
	if not string.match(string_item_cost, '%d+') then
		return 0
	elseif string.match(string_item_cost, '(%d%s%a+)%/') or string.match(string_item_cost, '(%d%s%a+)%-') then
		chat_message_cost_error(node_pc, string_item_name, true)
		string_item_cost = string.match(string_item_cost, '%d+%s%a+') -- thanks to FeatherRin on FG Forums for the inspiration
	elseif string.match(string_item_cost, '(%d%a+)%/') or string.match(string_item_cost, '(%d%s%a+)%-') then
		chat_message_cost_error(node_pc, string_item_name, true)
		string_item_cost = string.match(string_item_cost, '%d+%a+') -- thanks to FeatherRin on FG Forums for the inspiration
	elseif string.match(string_item_cost, '%-+') then
		chat_message_cost_error(node_pc, string_item_name)
		return 0
	elseif string.match(string_item_cost, '%/+') then
		chat_message_cost_error(node_pc, string_item_name)
		return 0
	end

	local number_item_cost = tonumber(string_item_cost:gsub('[^0-9.-]', '') or '')
	for string_denomination,table_denomination_info in pairs(TEGlobals.aDenominations) do
		if string.match(string_item_cost, string_denomination) then
			return number_item_cost * table_denomination_info['nValue']
		end
	end

	return 0
end

---	This function calculates the total value of every identified item in the player's inventory.
--	It then writes it to the DB for use during net worth calculation.
local function calculateInvCost(node)
	local nodeChar = node.getChild('....')
	if node.getParent().getName() == 'charsheet' then nodeChar = node
	elseif node.getName() == 'inventorylist' then nodeChar = node.getParent() end
	local nTotalInvVal = 0
	for _,v in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		local nItemIDed = DB.getValue(v, 'isidentified', 1)
		local sItemName = DB.getValue(v, 'name', '')
		local sItemCost = DB.getValue(v, 'cost')
		local nItemCount = DB.getValue(v, 'count', 1)

		if sItemCost and nItemIDed ~= 0 then
			local nItemCost = convert_denominations(nodeChar, string.lower(sItemCost), string.lower(sItemName))
			nTotalInvVal = nTotalInvVal + (nItemCount * nItemCost)
		end
	end

	if OptionsManager.isOption('WARN_COST', 'subtle') then nAnnounce = 0 end

	DB.setValue(nodeChar, 'coins.invtotalval', 'number', nTotalInvVal)
end

function onInit()
	if Session.IsHost then
		DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.cost'), 'onUpdate', calculateInvCost)
		DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.count'), 'onUpdate', calculateInvCost)
		DB.addHandler(DB.getPath('charsheet.*.inventorylist.*.isidentified'), 'onUpdate', calculateInvCost)
		DB.addHandler(DB.getPath('charsheet.*.inventorylist'), 'onChildDeleted', calculateInvCost)
	end
end
