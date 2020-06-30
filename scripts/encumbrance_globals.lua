--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	process tClumsyArmorTypes to escape and special characters
function onInit()
	local tSpecialCharacters = {'%(', '%)', '%.', '%+', '%-', '%*', '%?', '%[', '%^', '%$'}

	for i,_ in ipairs(tClumsyArmorTypes) do
		tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], '%%', '%%%%')

		for _,vv in ipairs(tSpecialCharacters) do
			tClumsyArmorTypes[i] = string.gsub(tClumsyArmorTypes[i], vv, '%' .. vv)
		end
	end
end

--	Change coinsperunit to the number of coins that equals 1 weight
nCoinsPerUnit = 50

--	Set multipliers for different currency denominations
tDenominations = {['pp'] = 10, ['gp'] = 1, ['ep'] = 0.5, ['sp'] = 0.1, ['cp'] = 0.01}

--	Set which arcane classes face spell failure while wearing different types of armor
tArcaneClass_HeavyArmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Skald', 'Unchained Summoner'}
tArcaneClass_MedArmor = {'Bard', 'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Unchained Summoner'}
tArcaneClass_LtArmor = {'Sorcerer', 'Wizard', 'Witch', 'Arcanist'}
tArcaneClass_Shield = {'Sorcerer', 'Wizard', 'Magus', 'Summoner', 'Witch', 'Arcanist', 'Bloodrager', 'Unchained Summoner'}

--	Change the encumbrance penalties
nHeavyMaxStat = 1
nHeavyCheckPenalty = -6

nMediumMaxStat = 3
nMediumCheckPenalty = -3

--	Encumbered Speed Equivalents to Base Speeds from 5-120
tEncumbranceSpeed = {'5','10','10','15','20','20','25','30','30','35','40','40','45','50','50','55','60','60','65','70','70','75','80','80'}

--	Armor that has a max dex of 0 (I promise this was the only way)
tClumsyArmorTypes = {'Fortress plate', 'Half-plate', 'Lamellar (iron)', 'Lamellar (stone coat)', 'Splint mail'}

--	Seperator for decimal places
sDigitDivider = '%1,'
