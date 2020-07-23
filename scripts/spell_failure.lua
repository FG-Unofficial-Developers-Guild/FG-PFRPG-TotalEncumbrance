-- 
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("spellfailure", spellFailureMessage)
end

---	Determine if arcane failure chance should be rolled
--	This is triggered when a spell's cast button is clicked
--	@see record_spell_entry.xml usePower()
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

---	Determine if spell is arcane
--	Compare spellset with arcane casters list (requires spell class to be only the name of the class)
--	@param nodeSpellset databasenode of the spellset that the cast spell is from
--	@return bArcaneCaster boolean value for whether the spellset used is a match
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

---	Converts from a CSV string to a table
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

---	Determine if the spell cast requires somatic compenents
--	Determine if the spell cast requires somatic compenents
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

---	Roll percentile dice to determine spell failure/success
--	@return nodeChar This is the charsheet databasenode of the player character that is casting the spell
--	@param rActor This is a table containing database paths and identifying data about the player character
--	@param nSpellFailureChance the percentage chance that the spell being cast will fail
function rollDice(nodeChar, rActor, nSpellFailureChance)
	local rRoll = {}
	rRoll.sType = 'spellfailure'
	rRoll.aDice = {'d100','d10'}
	rRoll.sDesc = 'Spell Failure Chance'
	rRoll.nTarget = nSpellFailureChance -- set DC to currently active spell failure chance

	ActionsManager.roll(nodeChar, rActor, rRoll)
end

---	Determine success/failure and output to chat
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