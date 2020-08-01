--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	Calculate the sums of all values in a table
--	@param t A table containing numbers
--	@return nSum The sum of all values in table t
function tableSum(t)
	local nSum = 0

	for _,v in pairs(t) do
		nSum = nSum + v
	end

	return nSum
end

---	Returns a string formatted with commas inserted every three digits from the left side of the decimal place
--	@param n The number to be reformatted.
function formatCurrency(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')

	return left..(num:reverse():gsub('(%d%d%d)',TEGlobals.sDigitDivider):reverse())..right
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