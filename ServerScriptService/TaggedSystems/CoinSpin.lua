local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Notify clients when a round starts or ends
ReplicatedStorage.InRound.Changed:Connect(function()
	local isRoundActive = ReplicatedStorage.InRound.Value
	for _, part in ipairs(CollectionService:GetTagged("SpinScript")) do
		if part:IsA("BasePart") then
			-- Add or remove "ActiveRound" tag based on round state
			if isRoundActive then
				CollectionService:AddTag(part, "ActiveRound")
			else
				CollectionService:RemoveTag(part, "ActiveRound")
			end
		end
	end
end)
