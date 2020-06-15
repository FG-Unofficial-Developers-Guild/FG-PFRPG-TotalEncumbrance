-- 
-- Please see the license.html file included with this distribution for attribution and copyright information.
--
function onInit()
	
end

function getRoll()

end

function arcaneSpellFailure(nodeSpellset)

	arcanemagic = isArcaneCaster(nodeSpellset)
end

function isArcaneCaster(nodeSpellset)
	local playerspellset = DB.getValue(nodeSpellset, 'label')

	-- classes that should roll arcane failure if encumbered by armor/shields
	local arcaneclasses = {'Bard', 'Sorcerer', 'Wizard'}

	for _,v in pairs(arcaneclasses) do
		if v == playerspellset then
		-- roll percentile dice for arcane failure and parse result based on encumbrance.spellfailure
		-- output result to chat
		Debug.chat('arcane spellset '..playerspellset..' detected')
		end
	end
end