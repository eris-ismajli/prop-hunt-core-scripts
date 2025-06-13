local Players = game:GetService("Players")

local function createCircleGui(character)
	local humanRoot = character:FindFirstChild("HumanoidRootPart")
	if not humanRoot then
		warn("Torso not found for character:", character.Name)
		return
	end

	-- Check if the BillboardGui already exists
	if humanRoot:FindFirstChild("CircleBillboard") then
		return
	end

	local billboard = game.ReplicatedStorage.CircleRadar:Clone()

	billboard.Parent = humanRoot
	billboard.Adornee = humanRoot

end


-- Function to handle player character addition
local function onCharacterAdded(character)
	task.wait(1) -- Wait for character to fully load
	createCircleGui(character)
end

-- Function to handle player addition
local function onPlayerAdded(player)
	-- Handle existing character or wait for one to load
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect to all current and future players
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
