--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeWin representing effects or PC sheet
--Return: appropriate object databasenodes - nodeEffects and nodePC
local function handleApplyStrengthEffectsArgs(nodeWin)
	local nodeEffects
	local playerid
	local nodePC

	if nodeWin.getName() == 'effects' then
		nodeEffects = nodeWin
		playerid = nodeWin.getParent().getName()
		nodePC = nodeWin.getChild('.....').getChild('charsheet').getChild(playerid)
	elseif nodeWin.getParent().getName() == 'charsheet' then
		nodePC = nodeWin
		playerid = nodeWin.getName()
		nodePC = nodeWin.getChild('..').getChild('combattracker.list').getChild(playerid).getChild('effects')
		Debug.chat(nodePC)
--	elseif nodeWin.getName() == 'encumbrance' then
--		nodePC = nodeWin.getParent()
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
	end

	return nodeEffects, nodePC
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode nodeWin representing effects or label
function applyStrengthEffects(nodeWin)
	local nodeEffects, nodePC = handleApplyStrengthEffectsArgs(nodeWin)
	
	local rActor = ActorManager.getActor('pc', nodeEffects)
	nAbility = ActorManager2.getAbilityEffectsBonus(rActor, 'strength')
	Debug.chat('effects mod',nAbility)

--	DB.setValue(nodeEffects.getParent(), 'encumbrance.stradj_fromeffects') -- Just to write some code without knowing the xml stuff
end

function combineSTRCarryModifiers(nodeWin)
	local nodeEffects, nodePC = handleApplyStrengthEffectsArgs(nodeWin)

	local manualstradj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local strbonusfromeffects = DB.getValue(nodePC, 'encumbrance.strbonusfromeffects')

	Debug.chat('manualstradj,strbonusfromeffects',manualstradj,strbonusfromeffects)

	if totalencstradj ~= nil then
		DB.setValue(nodePC, 'encumbrance.encstradj', totalencstradj)
	end
end