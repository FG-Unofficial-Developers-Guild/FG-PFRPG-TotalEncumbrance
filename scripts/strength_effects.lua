--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	DB.addHandler(DB.getPath('charsheet.*.effects.*.label'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects.*.isactive'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects'), 'onChildDeleted', applyStrengthEffects)
end

local function handleApplyStrengthEffectsArgs(nodeField)
	local nodeEffects

	if nodeField.getName() == 'effects' then
		nodeEffects = nodeField
	else
		nodeEffects = nodeField.getChild('...') -- 3 dots or 2 for the onUpdate call on label / isactive?
	end

	return nodeEffects
end

function applyStrengthEffects(nodeField)
	local nodeEffects = handleApplyStrengthEffectsArgs(nodeField)

	local strengtheffectstable = {}

	local isactive
	local label
	local effecttype
	local effectcontribution

	for _,v in pairs(DB.getChildren(nodeEffects)) do
		isactive = DB.getValue(v, 'isactive', 0)

		if isactive == 1 then
			label = DB.getValue(v 'label')
		end
	end

end
