-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--
-- ARMOR MANAGEMENT
--

---	This function checks for special abilities.
local function hasSpecialAbility(nodeChar, sSpecAbil)
	if not sSpecAbil then
		return false
	end

	local sLowerSpecAbil = string.lower(sSpecAbil)
	
	for _,vNode in pairs(DB.getChildren(nodeChar, 'specialabilitylist')) do
		if string.match(StringManager.trim(DB.getValue(vNode, 'name', ''):lower()), sLowerSpecAbil .. ' %d', 1) then
			return true
		end
	end
	
	return false
end

function calcItemArmorClass(nodeChar)
	local nMainArmorTotal = 0
	local nMainShieldTotal = 0
	local nMainMaxStatBonus = 999
	local nMainCheckPenalty = 0
	local nMainSpellFailure = 0
	local nMainSpeed30 = 0
	local nMainSpeed20 = 0

	for _,vNode in pairs(DB.getChildren(nodeChar, 'inventorylist')) do
		if DB.getValue(vNode, 'carried', 0) == 2 then
			local bIsArmor, _, sSubtypeLower = ItemManager2.isArmor(vNode)
			if bIsArmor then
				local bID = LibraryData.getIDState('item', vNode, true)
				
				local bIsShield = (sSubtypeLower == 'shield')
				if bIsShield then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, 'ac', 0)
					end
				else
					if bID then
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0) + DB.getValue(vNode, 'bonus', 0)
					else
						nMainArmorTotal = nMainArmorTotal + DB.getValue(vNode, 'ac', 0)
					end
							
					local nItemSpeed30 = DB.getValue(vNode, 'speed30', 0)
					if (nItemSpeed30 > 0) and (nItemSpeed30 < 30) then
						if nMainSpeed30 > 0 then
							nMainSpeed30 = math.min(nMainSpeed30, nItemSpeed30)
						else
							nMainSpeed30 = nItemSpeed30
						end
					end
					local nItemSpeed20 = DB.getValue(vNode, 'speed20', 0)
					if (nItemSpeed20 > 0) and (nItemSpeed20 < 30) then
						if nMainSpeed20 > 0 then
							nMainSpeed20 = math.min(nMainSpeed20, nItemSpeed20)
						else
							nMainSpeed20 = nItemSpeed20
						end
					end
				end
					
				local nMaxStatBonus = DB.getValue(vNode, 'maxstatbonus', 0)
				if nMaxStatBonus > 0 then
					if not bIsShield and hasSpecialAbility(nodeChar, 'Armor Training') then

						if DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 15 then
							nMaxStatBonus = nMaxStatBonus + 4
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 11 then
							nMaxStatBonus = nMaxStatBonus + 3
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 7 then
							nMaxStatBonus = nMaxStatBonus + 2
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 3 then
							nMaxStatBonus = nMaxStatBonus + 1
						end
					end
					
					if nMainMaxStatBonus > 0 then nMainMaxStatBonus = math.min(nMainMaxStatBonus, nMaxStatBonus)
					else nMainMaxStatBonus = nMaxStatBonus
					end
				else
					for _,v in pairs(TEGlobals.tClumsyArmorTypes) do
						if string.find(string.lower(DB.getValue(vNode, 'name', 0)), string.lower(v)) then
							nMainMaxStatBonus = 0
														
							break
						end
					end
				end
				
				local nCheckPenalty = DB.getValue(vNode, 'checkpenalty', 0)
				if nCheckPenalty < 0 then
					if not bIsShield and CharManager.hasTrait(nodeChar, 'Armor Expert') then
						nCheckPenalty = nCheckPenalty + 1
					end
					if not bIsShield and hasSpecialAbility(nodeChar, 'Armor Training') then
						if DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 15 then
							nCheckPenalty = nCheckPenalty + 4
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 11 then
							nCheckPenalty = nCheckPenalty + 3
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 7 then
							nCheckPenalty = nCheckPenalty + 2
						elseif DB.getValue(CharManager.getClassNode(nodeChar, 'Fighter'), "level") >= 3 then
							nCheckPenalty = nCheckPenalty + 1
						end
					end
					
					if nCheckPenalty < 0 then nMainCheckPenalty = nMainCheckPenalty + nCheckPenalty end
				end
				
				local nSpellFailure = DB.getValue(vNode, 'spellfailure', 0)
				if nSpellFailure > 0 then nMainSpellFailure = nMainSpellFailure + nSpellFailure end
			end
		end
	end
	
	DB.setValue(nodeChar, 'ac.sources.armor', 'number', nMainArmorTotal)
	DB.setValue(nodeChar, 'ac.sources.shield', 'number', nMainShieldTotal)
	if nMainMaxStatBonus < 999 then
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 1)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonus', 'number', nMainMaxStatBonus)
	else
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonusactive', 'number', 0)
		DB.setValue(nodeChar, 'encumbrance.armormaxstatbonus', 'number', 999)
	end
	DB.setValue(nodeChar, 'encumbrance.armorcheckpenalty', 'number', nMainCheckPenalty)
	DB.setValue(nodeChar, 'encumbrance.spellfailure', 'number', nMainSpellFailure)
	
	local bApplySpeedPenalty = true
	if CharManager.hasTrait(nodeChar, 'Slow and Steady') then
		bApplySpeedPenalty = false
	end

	local nSpeedBase = DB.getValue(nodeChar, 'speed.base', 0)
	local nSpeedArmor = 0
	if bApplySpeedPenalty then
		if (nSpeedBase >= 30) and (nMainSpeed30 > 0) then
			nSpeedArmor = nMainSpeed30 - 30
		elseif (nSpeedBase < 30) and (nMainSpeed20 > 0) then
			nSpeedArmor = nMainSpeed20 - 20
		end
	end
	DB.setValue(nodeChar, 'speed.armor', 'number', nSpeedArmor)
	local nSpeedTotal = nSpeedBase + nSpeedArmor + DB.getValue(nodeChar, 'speed.misc', 0) + DB.getValue(nodeChar, 'speed.temporary', 0)
	DB.setValue(nodeChar, 'speed.final', 'number', nSpeedTotal)
end