local decrementLevel = {}

local ranks = {
	{name = "BRONZE", levelToAdvance = 3},
	{name = "SILVER", levelToAdvance = 4},
	{name = "GOLD", levelToAdvance = 4},
	{name = "PLATINUM", levelToAdvance = 5},
	{name = "DIAMOND", levelToAdvance = 5},
	{name = "MASTER", levelToAdvance = 6},
	{name = "GRANDMASTER", levelToAdvance = 6},
	{name = "LEGEND", levelToAdvance = 7},
	{name = "PHANTOM", levelToAdvance = 8},
	{name = "APEX HUNTER", levelToAdvance = math.huge}
}

function decrementLevel.FireDecrementLevel(plr)
	local level = plr:WaitForChild("Level")
	local rank = plr:WaitForChild("Rank")

	if rank.Value == "BRONZE" then return end

	if level.Value > 1 then
		level.Value -= 1
		return "decremented"
	else
		local currentRankIndex
		for i, rankInfo in ipairs(ranks) do
			if rank.Value == rankInfo.name then
				currentRankIndex = i
				break
			end
		end

		if currentRankIndex and currentRankIndex > 1 then
			local previousRank = ranks[currentRankIndex - 1]
			rank.Value = previousRank.name
			level.Value = previousRank.levelToAdvance - 1
			return "downgraded"
		else
			level.Value = 1
			return "at_min"
		end
	end
end

return decrementLevel
