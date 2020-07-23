-- 
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("spellfailure", spellFailureMessage)
end

---	This function determines if arcane failure chance should be rolled.
--	It is triggered when a spell's cast button is clicked.
--	Other functions are called to determine whether a roll should be performed.
--	@see isArcaneCaster()
--	@see bStillSpell()
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')
	local nSpellFailureChance = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.spellfailure')

	local nodeChar = nodeSpellset.getChild('...')
	local rActor = ActorManager.getActor('pc', nodeChar)

	if nSpellFailureChance ~= 0 then
		-- if true, rolls failure chance
		local bArcaneCaster = isArcaneCaster(nodeSpellset)

		-- if bStillSpell is flase, roll spell failure chance
		local bStillSpell = isSomaticSpell(nodeSpell)

		-- set up and roll percentile dice for arcane failure
		if bArcaneCaster == true and bStillSpell == false then
			if OptionsManager.isOption('AUTO_SPELL_FAILURE', 'auto') then
				rollDice(nodeChar, rActor, nSpellFailureChance)
			elseif OptionsManager.isOption('AUTO_SPELL_FAILURE', 'prompt') then
				ChatManager.SystemMessage('Roll for ' .. nSpellFailureChance .. '% ' .. 'Arcane Spell Failure Chance')
			end
		end
	end
end

---	This function compares the spellset name to one of the tables of arcane caster classes in TEGlobals
--	Some classes are able to ignore arcane failure chance in certain armor categories,.
--	To accomodate this, the function gets the current armor type as calculated by RealEncumbrance.
--	This armor type is used to select which table of classes to be checked for spell failure applicability.
--	@param nodeSpellset databasenode of the spellset that the cast spell is from
--	@return bArcaneCaster boolean value for whether the spellset used is a match for any in the table
function isArcaneCaster(nodeSpellset)
	local sPlayerSpellset = string.lower(DB.getValue(nodeSpellset, 'label'))

	local nArmorCategory = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.armorcategory')
	local nShieldEquipped = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.shieldequipped')

	bArcaneCaster = false

	if nArmorCategory == 3 then -- if PC is wearing heavy armor
		for _,v in pairs(TEGlobals.tArcaneClass_HeavyArmor) do
			if string.lower(v) == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nArmorCategory == 2 then -- if PC is wearing medium armor
		for _,v in pairs(TEGlobals.tArcaneClass_MedArmor) do
			if string.lower(v) == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nArmorCategory == 1 then -- if PC is wearing light armor
		for _,v in pairs(TEGlobals.tArcaneClass_LtArmor) do
			if string.lower(v) == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	end
	if nShieldEquipped == 2 then -- if PC has a tower shield equipped, same as heavy armor
		for _,v in pairs(TEGlobals.tArcaneClass_HeavyArmor) do
			if string.lower(v) == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nShieldEquipped == 1 then -- if PC has a shield equipped
		for _,v in pairs(TEGlobals.tArcaneClass_Shield) do
			if string.lower(v) == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	end

	return bArcaneCaster
end

---	This function converts CSVs from a string to a table of values
--	@param s input, a string of CSVs
--	@return t output, an indexed table of values
function fromCSV(s)
	s = s .. ','        -- ending comma
	local t = {}        -- table to collect fields
	local fieldstart = 1
	repeat
		local nexti = string.find(s, ',', fieldstart)
		table.insert(t, string.sub(s, fieldstart, nexti-1))
		fieldstart = nexti + 1
	until fieldstart > string.len(s)

	return t
end

---	This function determines if the spell cast requires somatic compenents.
--	To do this, it gets the value of the components string and passes it to the fromCSV function.
--	The resulting table is then checked for an S character.
--	@see fromCSV
--	@param nodeSpell database node of the spell being cast
--	@return bStillSpell boolean value, true if spell has no somatic compenents
function isSomaticSpell(nodeSpell)
	local sComponents = DB.getValue(nodeSpell,'components')
	local bStillSpell = true

	if sComponents then
		local tComponents = fromCSV(sComponents)

		for _,v in pairs(tComponents) do
			if v == 'S' or v == ' S' then
				bStillSpell = false
			end
		end
	end
	
	return bStillSpell
end

---	This function rolls typed percentile dice identified as a spell failure roll including the failure threshold.
--	@param nodeChar This is the charsheet databasenode of the player character that is casting the spell
--	@param rActor This is a table containing database paths and identifying data about the player character
--	@param nSpellFailureChance The numerical chance that the spell being cast will fail
function rollDice(nodeChar, rActor, nSpellFailureChance)
	local rRoll = {}
	rRoll.sType = 'spellfailure'
	rRoll.aDice = {'d100','d10'}
	rRoll.sDesc = 'Spell Failure Chance'
	rRoll.nTarget = nSpellFailureChance -- set DC to currently active spell failure chance

	ActionsManager.roll(nodeChar, rActor, rRoll)
end

---	This function determines whether the spell failure roll was a success or failure.
--	This is triggered when a roll of sType 'spellfailure' is performed.
--	After checking for success/failure, it outputs the result to chat.
--	@param rSource the character casting the spell
--	@param rRoll a table of details/parameters about the roll being performed
function spellFailureMessage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll)

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll)
		local nTargetDC = tonumber(rRoll.nTarget) or 0
		
		rMessage.text = rMessage.text .. ' (failure under ' .. nTargetDC .. '%)'
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. ' [SUCCESS]'
		else
			rMessage.text = rMessage.text .. ' [FAILURE]'
		end
	end
	
	Comm.deliverChatMessage(rMessage)
end