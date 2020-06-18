--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: you know
function onInit()
	DB.addHandler(DB.getPath('combattracker.list.*.effects'), 'onChildUpdate', applyStrengthEffects)
end

--Summary: Handles arguments of applyStrengthEffects()
--Argument: databasenode nodeWin representing effects or PC sheet
--Return: nodeEffects and nodePC databasenodes if provided with either. If input is neither, return what it sees.
local function nodeConcierge(nodeWin)
	local nodeEffects
	local nodePC
	local playerid

	if nodeWin.getName() == 'effects' then
		nodeEffects = nodeWin
		playerid = nodeWin.getParent().getName()
		nodePC = nodeWin.getChild('.....').getChild('charsheet').getChild(playerid)
	elseif nodeWin.getParent().getName() == 'charsheet' then
		nodePC = nodeWin
		playerid = nodeWin.getName()
		nodeEffects = nodeWin.getChild('...').getChild('combattracker').getChild('list').getChild(playerid).getChild('effects')
	else
		Debug.chat('Node error. Unrecognized Node '..nodeWin.getPath())
	end

	return nodeEffects, nodePC
end

--Summary: Recomputes bonuses from effects and writes them to stradj
--Argument: databasenode nodeWin representing effects or label
function applyStrengthEffects(nodeWin)
	local nodeEffects, nodePC = nodeConcierge(nodeWin)
	
	local rActor = ActorManager.getActor('pc', nodeEffects)
	nAbility = ActorManager2.getAbilityEffectsBonus(rActor, 'strength')
	Debug.chat('effects mod',nAbility)

--	DB.setValue(nodeEffects.getParent(), 'encumbrance.stradj_fromeffects') -- Just to write some code without knowing the xml stuff
end

function combineSTRCarryModifiers(nodeWin)
	local nodeEffects, nodePC = nodeConcierge(nodeWin)

	local manualstradj = DB.getValue(nodePC, 'encumbrance.manualstradj')
	local strbonusfromeffects = DB.getValue(nodePC, 'encumbrance.strbonusfromeffects')
	local stradjtable = {}
	
	if manualstradj ~= nil and manualstradj ~= 0 then
		table.insert(stradjtable, manualstradj)
	end
	if strbonusfromeffects ~= nil and strbonusfromeffects ~= 0 then
		table.insert(stradjtable, strbonusfromeffects)
	end
	
	local totalencstradj = TotalEncumbranceLib.tableSum(stradjtable)
	
	Debug.chat(totalencstradj)

	if totalencstradj == nil then
		DB.setValue(nodePC, 'encumbrance.stradj', 'number', 0)
	end
	if totalencstradj ~= nil then
		DB.setValue(nodePC, 'encumbrance.stradj', 'number', totalencstradj)
	end
end