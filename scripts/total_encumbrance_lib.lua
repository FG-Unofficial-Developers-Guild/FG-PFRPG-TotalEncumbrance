--
-- Please see the license.html file included with this distribution for attribution and copyright information.
--

--Summary: Sums table values
--Argument: table t to sum values within
--Return: sum of values in table t
function tableSum(t)
	local sum = 0

	for _,v in pairs(t) do
		sum = sum + v
	end

	return sum
end
