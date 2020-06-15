-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Automatically determine if arcane failure chance should be rolled when a spell's cast button is clicked
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')
	local spellfailurechance
	spellfailurechance = DB.getValue(nodeSpellset.getChild('...'), 'encumbrance.spellfailure')

	if spellfailurechance ~= 0 then
		-- if true, roll failure chance
		local arcanemagic
		arcanemagic = isArcaneCaster(nodeSpellset)

		-- if true, don't roll failure chance
		local stillspell
		stillspell = isSomaticSpell(nodeSpell)

		if arcanemagic == true and stillspell == false then
			ChatManager.SystemMessage('Arcane Spell Failure: '..spellfailurechance..'%')
		end

		-- roll percentile dice for arcane failure and parse result based on encumbrance.spellfailure
		-- output result to chat
	end
end

--Determine if the spell is from a spellset that is on the arcane casters list
function isArcaneCaster(nodeSpellset)
	-- classes that should roll arcane failure if encumbered by armor/shields
	local arcaneclasses = {'Bard', 'Sorcerer', 'Wizard'}

	local playerspellset = DB.getValue(nodeSpellset, 'label')
	
	arcanemagic = false

	for _,v in pairs(arcaneclasses) do
		if v == playerspellset then
			arcanemagic = true
		end
	end
	
	return arcanemagic
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
	local componentstable = {}
	local components = DB.getValue(nodeSpell,'components')
	componentstable = fromCSV(components)
	
	stillspell = true

	for _,v in pairs(componentstable) do
		if v == 'S' or v == ' S' then
			stillspell = false
		end
	end

	return stillspell
end