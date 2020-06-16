--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('charsheet.*.effects.*.label'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects.*.isactive'), 'onUpdate', applyStrengthEffects)
	DB.addHandler(DB.getPath('charsheet.*.effects'), 'onChildDeleted', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeField representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleApplyStrengthEffectsArgs(nodeField)
	local nodeEffects

	if nodeField.getName() == 'effects' then
		nodeEffects = nodeField
	else
		nodeEffects = nodeField.getChild('...') -- 3 dots or 2 for the onUpdate call on label / isactive?
	end

	return nodeEffects
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode nodeField representing effects or label
function applyStrengthEffects(nodeField)
	local nodeEffects = handleApplyStrengthEffectsArgs(nodeField)
	local strengthBonus = computeStrengthEffects(nodeEffects)

	DB.setValue(nodeEffects.getParent(), 'encumbrance.manualstradj') -- Just to write some code without knowing the xml stuff
	DB.setValue(nodeEffects.getParent(), 'encumbrance.stradj') -- Just to write some code without knowing the xml stuff
end

--Summary: Will populate the table for strength effects (normalized population)
--Argument: databasenode nodeEffects pointing to DB node of effects
--Argument: table strengthEffectsTable will be populated with strength effects
local function gatherStrengthEffects(nodeEffects, strengthEffectsTable)
	local isactive
	local label
	local effecttype
	local effectcontribution

	for _,v in pairs(DB.getChildren(nodeEffects)) do
		isactive = DB.getValue(v, 'isactive', 0)

		if isactive == 1 then
			label = DB.getValue(v, 'label')
		end
	end
end

--Summary: Will compute the total adjustment to strength due to effects
--Return: Strength adjustment due to effects
function computeStrengthEffects(nodeEffects)
	local strengthEffectsTable = {}

	local strengthBonus

	gatherStrengthEffects(nodeEffects, strengthEffectsTable)

	if table.getn(strengthEffectsTable) ~= 0 then
		strengthBonus = TotalEncumbranceLib.tableSum(strengthEffectsTable)
	else
		strengthBonus = 0
	end

	return strengthBonus
end
