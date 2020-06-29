--
--	Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	Summary: Sums table values
--	Argument: table t to sum values within
--	Return: sum of values in table t
function tableSum(t)
	local nSum = 0

	for _,v in pairs(t) do
		nSum = nSum + v
	end

	return nSum
end