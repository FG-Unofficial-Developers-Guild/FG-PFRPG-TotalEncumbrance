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

--- Provide the appropriate weight unit (pounds or kilograms) depending on the GM's choice
--	@return nUnit Desired multipler (to convert pounds to kilograms)
function getEncWeightUnit()
	local nUnit = 0.45359237

	if OptionsManager.isOption('ENCUMBRANCE_UNIT', 'lb') then
		nUnit = 1
	end
	
	return nUnit
end

function isExtraplanarContainer(sItemName, nItemCarried)
	if not sItemName then return nil; end
	local tExtraplanarContainers = {}
	table.insert(tExtraplanarContainers, 'of holding')
	table.insert(tExtraplanarContainers, 'portable hole')
	table.insert(tExtraplanarContainers, 'efficient quiver')
	table.insert(tExtraplanarContainers, 'handy haversack')
	for _,v in pairs(tExtraplanarContainers) do
		if (not nItemCarried or (nItemCarried ~= 2)) and string.find(sItemName, v) then
			return true
		end
	end
end

function isContainer(sItemName, nItemCarried)
	local tContainers = {}
	table.insert(tContainers, 'backpack')
	table.insert(tContainers, 'pouch')
	table.insert(tContainers, 'quiver')
	table.insert(tContainers, 'bag')
	for _,v in pairs(tContainers) do
		if (not nItemCarried or (nItemCarried ~= 2)) and string.find(sItemName, v) then
			return true
		end
	end
end

--	Set multipliers for different currency denominations. nValue = value multiplier. nWeight = per-coin weight (in pounds -- conversion is automatic)
aDenominations =
	{
	-- ['mp'] = {['nValue'] = 500, ['nWeight'] = .3}, -- Asgurgolas (homebrew)
	['pp'] = {['nValue'] = 10, ['nWeight'] = .02},
	['gp'] = {['nValue'] = 1, ['nWeight'] = .02},
	-- ['ep'] = {['nValue'] = .5, ['nWeight'] = .02}, -- electrum pieces (for homebrew)
	['sp'] = {['nValue'] = .1, ['nWeight'] = .02},
	['cp'] = {['nValue'] = .01, ['nWeight'] = .02},
	-- ['op'] = {['nValue'] = 0, ['nWeight'] = .02}, -- Zygmunt Molotch (homebrew)
	-- ['jp'] = {['nValue'] = 0, ['nWeight'] = .02}, -- Zygmunt Molotch (homebrew)
	}

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
