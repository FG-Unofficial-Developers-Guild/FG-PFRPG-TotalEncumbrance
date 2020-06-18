--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', combineCarryModifiers)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeField representing effects or label
--Return: appropriate object databasenode - should represent effects
local function handleApplyStrengthEffectsArgs(node)
	local nodeEffects

	Debug.chat(node)

	if node.getChild('...').getName() == 'effects' then
		nodeEffects = node
		Debug.chat(nodeEffects)
	else
		Debug.chat('Node error. Unrecognized Node '..node.getPath())
	end

	return nodeEffects
end

function combineCarryModifiers(node)
	local nodeEffects = handleApplyStrengthEffectsArgs(node)
end