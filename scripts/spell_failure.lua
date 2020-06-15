-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Automatically determine if arcane failure chance should be rolled when a spell's cast button is clicked
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')
	local spellfailurechance = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.spellfailure')

	if spellfailurechance ~= 0 then
		-- if true, roll failure chance
		local arcanecaster = isArcaneCaster(nodeSpellset)

		-- if true, don't roll failure chance
		local stillspell = isSomaticSpell(nodeSpell)

		if arcanecaster == true and stillspell == false then
			ChatManager.SystemMessage('Arcane Spell Failure: '..spellfailurechance..'%')
		end

		-- roll percentile dice for arcane failure and parse result based on encumbrance.spellfailure
		-- output result to chat
	end
end

--Determine if the spell is from a spellset that is on the arcane casters list
function isArcaneCaster(nodeSpellset)
	-- classes that should roll arcane failure if encumbered by armor/shields
	local arcaneclass_heavyarmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Skald', 'Unchained Summoner'}
	local arcaneclass_medarmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Unchained Summoner'}
	local arcaneclass_ltarmor = {'Sorcerer', 'Wizard', 'Witch', 'Arcanist'}
	local arcaneclass_shield = {'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Unchained Summoner'}
	local playerspellset = DB.getValue(nodeSpellset, 'label')

	local armorcategory = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.armorcategory')
	local shieldequipped = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.shieldequipped')

	arcanecaster = false

	if armorcategory == 3 then --if PC has is wearing heavy armor
		for _,v in pairs(arcaneclass_heavyarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif armorcategory == 2 then --if PC has is wearing medium armor
		for _,v in pairs(arcaneclass_medarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif armorcategory == 1 then --if PC has is wearing light armor
		for _,v in pairs(arcaneclass_ltarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	end
	if shieldequipped == 2 then -- if PC has a tower shield equipped
		for _,v in pairs(arcaneclass_heavyarmor) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	elseif shieldequipped == 1 then -- if PC has a shield equipped
		for _,v in pairs(arcaneclass_shield) do
			if v == playerspellset then
				arcanecaster = true
			end
		end
	end

	return arcanecaster
end

-- Convert from CSV string to table (converts a single line of a CSV file)
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

--Determine if the spell requires somatic compenents
function isSomaticSpell(nodeSpell)
	local components = DB.getValue(nodeSpell,'components')
	local componentstable = fromCSV(components)
	
	stillspell = true

	for _,v in pairs(componentstable) do
		if v == 'S' or v == ' S' then
			stillspell = false
		end
	end

	return stillspell
end