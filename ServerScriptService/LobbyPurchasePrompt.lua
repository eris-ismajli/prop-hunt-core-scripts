local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local debounce = {}
local gamepassInfo = {}

for _, part in pairs(workspace:GetDescendants()) do
	if part:IsA("BasePart") and part:GetAttribute("GamepassId") then
		local gamepassId = part:GetAttribute("GamepassId")
		CollectionService:AddTag(part, "GamepassPrompt")

		local image = part.Parent:WaitForChild("GamepassInfo"):WaitForChild("g"):WaitForChild("ImageLabel")
		local text = image.Parent:WaitForChild("t")

		if not gamepassInfo[gamepassId] then
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
			end)

			if success and info then
				gamepassInfo[gamepassId] = {
					Name = info.Name,
					ImageId = info.IconImageAssetId,
					Id = gamepassId
				}
				image.Image = "rbxassetid://" .. info.IconImageAssetId
				text.Text = info.Name
			end
		end
	end
end

-- Listen for touches on tagged parts
for _, part in pairs(CollectionService:GetTagged("GamepassPrompt")) do
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local gamepassId = part:GetAttribute("GamepassId")
		if not gamepassId then return end

		local key = player.UserId .. "_" .. gamepassId
		if debounce[key] then return end
		debounce[key] = true

		local info = gamepassInfo[gamepassId]
		if info then
			MarketplaceService:PromptGamePassPurchase(player, gamepassId)
		end

		task.delay(2, function()
			debounce[key] = nil
		end)
	end)
end
