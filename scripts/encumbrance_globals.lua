--
--	Please see the license.html file included with this distribution for attribution and copyright information.
--

--	process tClumsyArmorTypes to escape and special characters
function onInit()
	local tSpecialCharacters = {'%(', '%)', '%.', '%+', '%-', '%*', '%?', '%[', '%^', '%$'}

	for i,_ in ipairs(tClumsyArmorTypes) do
		tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], '%%', '%%%%')

		for _,vv in ipairs(tSpecialCharacters) do
			tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], vv, '%' .. vv)
		end
		tClumsyArmorTypes[i] = string.lower(tClumsyArmorTypes[i])
	end
end

--	Change coinsperunit to the number of coins that equals 1 weight
coinsperunit = 50

--	Set which arcane classes face spell failure while wearing different types of armor
arcaneclass_heavyarmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Skald', 'Unchained Summoner'}
arcaneclass_medarmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Unchained Summoner'}
arcaneclass_ltarmor = {'Sorcerer', 'Wizard', 'Witch', 'Arcanist'}
arcaneclass_shield = {'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Unchained Summoner'}

--	Change the encumbrance penalties
heavymaxstat = 1
heavycheckpenalty = -6

mediummaxstat = 3
mediumcheckpenalty = -3

-- Armor that has a max dex of 0 (I promise this was the only way)
tClumsyArmorTypes = {'Fortress plate', 'Half-plate', 'Lamellar (iron)', 'Lamellar (stone coat)', 'Splint mail'}