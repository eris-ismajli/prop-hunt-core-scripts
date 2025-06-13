local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local propsTeam = game.Teams.Props
-- Track parts to animate
local animatedParts = {}

-- Function to start animating a part
local function startAnimating(part)
	if animatedParts[part] then return end -- Prevent duplicate animations

	animatedParts[part] = true
	
	if player.Team == propsTeam then
		part.Enabled = true
		local char = player.Character or player.CharacterAdded:Wait()
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			part.Enabled = false
		end)
	else
		part.Enabled = false
	end
	
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if player.Team == propsTeam then
			part.Enabled = true
			local char = player.Character or player.CharacterAdded:Wait()
			local hum = char:WaitForChild("Humanoid")
			hum.Died:Connect(function()
				part.Enabled = false
			end)
		else
			part.Enabled = false
		end
	end)
end

-- Function to stop animating a part
local function stopAnimating(part)
	animatedParts[part] = nil
end

-- Listen for parts being tagged or untagged
CollectionService:GetInstanceAddedSignal("InRound"):Connect(startAnimating)
CollectionService:GetInstanceRemovedSignal("InRound"):Connect(stopAnimating)

-- Initialize existing tagged parts
for _, part in ipairs(CollectionService:GetTagged("InRound")) do
	startAnimating(part)
end
