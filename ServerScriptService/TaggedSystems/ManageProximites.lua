local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Notify clients when a round starts or ends
ReplicatedStorage.InRound.Changed:Connect(function()
	local isRoundActive = ReplicatedStorage.InRound.Value
	for _, part in ipairs(CollectionService:GetTagged("ProximityScript")) do
		if isRoundActive then
			-- Connect the team change listener once, outside the part loop
			if isRoundActive then
				CollectionService:AddTag(part, "InRound")
			else
				CollectionService:RemoveTag(part, "InRound")
			end
		end
	end
end)
