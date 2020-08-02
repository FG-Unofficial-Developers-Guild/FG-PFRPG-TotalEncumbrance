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

---	This function rounds to the specified number of decimals
function round(number, decimals)
    local power = 10^decimals
    return math.floor(number * power) / power
end