-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Automatically determine if arcane failure chance should be rolled when a spell's cast button is clicked
function arcaneSpellFailure(nodeSpell)
	local nodeSpellset = nodeSpell.getChild('.....')

	-- if true, roll failure chance
	local arcanemagic
	arcanemagic = isArcaneCaster(nodeSpellset)

	-- if true, don't roll failure chance
	local stillspell
	stillspell = isSomaticSpell(nodeSpell)

	if arcanemagic == true and stillspell == false then
		Debug.chat('spell failure!')
	end

	-- roll percentile dice for arcane failure and parse result based on encumbrance.spellfailure
	-- output result to chat
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

--Determine if the spell requires somatic compenents
function isSomaticSpell(nodeSpell)
	local components = DB.getValue(nodeSpell,'components')
	Debug.chat('components',components)

	stillspell = false

	
end