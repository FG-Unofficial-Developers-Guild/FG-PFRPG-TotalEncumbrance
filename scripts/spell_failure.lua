-- 
--	Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("spellfailure", spellFailureMessage)
end

--	Automatically determine if arcane failure chance should be rolled when a spell's cast button is clicked
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')
	local nSpellFailureChance = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.spellfailure')

	local nodeChar = nodeSpellset.getChild('...')
	local rActor = ActorManager.getActor('pc', nodeChar);

	if nSpellFailureChance ~= 0 then
		-- if true, rolls failure chance
		local bArcaneCaster = isArcaneCaster(nodeSpellset)

		-- if true, doesn't roll failure chance
		local bNotStillSpell = isSomaticSpell(nodeSpell)

		-- set up and roll percentile dice for arcane failure
		if bArcaneCaster == true and bNotStillSpell == false then
			if OptionsManager.isOption('AUTO_SPELL_FAILURE', 'auto') then
				rollDice(nodeChar, rActor, nSpellFailureChance)
			elseif OptionsManager.isOption('AUTO_SPELL_FAILURE', 'prompt') then
				ChatManager.SystemMessage(nSpellFailureChance..'% '..'Arcane Spell Failure Chance')
			end
		end
	end
end

--	Determine if the spell is from a spellset that is on the arcane casters list
function isArcaneCaster(nodeSpellset)
	-- this gets the name of the spell class being used to cast the spell that triggers this
	local sPlayerSpellset = DB.getValue(nodeSpellset, 'label')

	local nArmorCategory = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.armorcategory')
	local nShieldEquipped = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.shieldequipped')

	bArcaneCaster = false

	if nArmorCategory == 3 then --if PC has is wearing heavy armor
		for _,v in pairs(TEGlobals.tArcaneClass_HeavyArmor) do
			if v == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nArmorCategory == 2 then --if PC has is wearing medium armor
		for _,v in pairs(TEGlobals.tArcaneClass_MedArmor) do
			if v == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nArmorCategory == 1 then --if PC has is wearing light armor
		for _,v in pairs(TEGlobals.tArcaneClass_LtArmor) do
			if v == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	end
	if nShieldEquipped == 2 then -- if PC has a tower shield equipped
		for _,v in pairs(TEGlobals.tArcaneClass_HeavyArmor) do
			if v == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	elseif nShieldEquipped == 1 then -- if PC has a shield equipped
		for _,v in pairs(TEGlobals.tArcaneClass_Shield) do
			if v == sPlayerSpellset then
				bArcaneCaster = true
			end
		end
	end

	return bArcaneCaster
end

--	Convert from CSV string to table (converts a single line of a CSV file)
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

--	Determine if the spell requires somatic compenents
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

--	Rolls percentile dice
--	sType: unique identifier
--	aDice: 2d10, one tens column and one ones column
--	sDesc: title of roll to be output to chat
--	nTarget: number to roll against (current nSpellFailureChance)
function rollDice(nodeChar, rActor, nSpellFailureChance)
	local rRoll = {}
	rRoll.sType = 'spellfailure'
	rRoll.aDice = {'d100','d10'}
	rRoll.sDesc = 'Spell Failure Chance'
	rRoll.nTarget = nSpellFailureChance -- set DC to currently active spell failure chance

	ActionsManager.roll(nodeChar, rActor, rRoll)
end

--	Determines success/failure and outputs to chat
function spellFailureMessage(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll)

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll)
		local nTargetDC = tonumber(rRoll.nTarget) or 0
		
		rMessage.text = rMessage.text .. ' (vs. DC ' .. nTargetDC .. ')'
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. ' [SUCCESS]'
		else
			rMessage.text = rMessage.text .. ' [FAILURE]'
		end
	end
	
	Comm.deliverChatMessage(rMessage)
end