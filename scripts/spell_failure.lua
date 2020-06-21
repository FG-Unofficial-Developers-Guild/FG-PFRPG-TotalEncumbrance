-- 
--	Please see the license.html file included with this distribution for attribution and copyright information.
--

function onInit()
	ActionsManager.registerResultHandler("spellfailure", onRoll)
end

--	Automatically determine if arcane failure chance should be rolled when a spell's cast button is clicked
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')
	local spellfailurechance = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.spellfailure')

	local nodeChar = nodeSpellset.getChild('...')
	local rActor = ActorManager.getActor('pc', nodeChar);

	if spellfailurechance ~= 0 then
		-- if true, rolls failure chance
		local arcanecaster = isArcaneCaster(nodeSpellset)

		-- if true, doesn't roll failure chance
		local notstillspell = isSomaticSpell(nodeSpell)

		-- set up and roll percentile dice for arcane failure
		if arcanecaster == true and notstillspell == false then
			if OptionsManager.isOption('AUTO_SPELL_FAILURE', 'auto') then
				rollDice(nodeChar, rActor, spellfailurechance)
			elseif OptionsManager.isOption('AUTO_SPELL_FAILURE', 'prompt') then
				ChatManager.SystemMessage(spellfailurechance..'% '..'Arcane Spell Failure Chance')
			end
		end
	end
end

--	Determine if the spell is from a spellset that is on the arcane casters list
function isArcaneCaster(nodeSpellset)
	-- this gets the name of the spell class being used to cast the spell that triggers this
	local playerspellset = DB.getValue(nodeSpellset, 'label')

	local armorcategory = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.armorcategory')
	local shieldequipped = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.shieldequipped')

	arcanecaster = false

	if armorcategory == 3 then --if PC has is wearing heavy armor
		for _,v in pairs(TEGlobals.arcaneclass_heavyarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif armorcategory == 2 then --if PC has is wearing medium armor
		for _,v in pairs(TEGlobals.arcaneclass_medarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif armorcategory == 1 then --if PC has is wearing light armor
		for _,v in pairs(TEGlobals.arcaneclass_ltarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	end
	if shieldequipped == 2 then -- if PC has a tower shield equipped
		for _,v in pairs(TEGlobals.arcaneclass_heavyarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif shieldequipped == 1 then -- if PC has a shield equipped
		for _,v in pairs(TEGlobals.arcaneclass_shield) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	end

	return arcanecaster
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
	local components = DB.getValue(nodeSpell,'components')
	local stillspell = true

	if components then
		local componentstable = fromCSV(components)

		for _,v in pairs(componentstable) do
			if v == 'S' or v == ' S' then
				stillspell = false
			end
		end
	end
	
	return stillspell
end

--	Rolls percentile dice
--	sType: unique identifier
--	aDice: 2d10, one tens column and one ones column
--	sDesc: title of roll to be output to chat
--	nTarget: number to roll against (current spellfailurechance)
function rollDice(nodeChar, rActor, spellfailurechance)
	local rRoll = {}
	rRoll.sType = 'spellfailure'
	rRoll.aDice = {'d100','d10'}
	rRoll.sDesc = 'Spell Failure Chance'
	rRoll.nTarget = spellfailurechance -- set DC to currently active spell failure chance

	ActionsManager.roll(nodeChar, rActor, rRoll)
end

--	Determines success/failure and outputs to chat
function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	Comm.deliverChatMessage(rMessage);
end