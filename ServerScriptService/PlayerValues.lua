-- Get the DataStoreService
local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")

game.Players.PlayerAdded:Connect(function(plr)
	-- Create the default values for the player
	local role = Instance.new("StringValue")
	role.Name = "Role"
	role.Value = " "
	role.Parent = plr

	local playingStatus = Instance.new("StringValue")
	playingStatus.Name = "PlayingStatus"
	playingStatus.Value = " "
	playingStatus.Parent = plr

	local tool = Instance.new("StringValue")
	tool.Name = "Tool"
	tool.Value = " "
	tool.Parent = plr

	local coinStatus = Instance.new("NumberValue")
	coinStatus.Name = "CoinStatus"
	coinStatus.Value = 0
	coinStatus.Parent = plr

	local stepCounter = Instance.new("NumberValue")
	stepCounter.Name = "StepCounter"
	stepCounter.Value = 0
	stepCounter.Parent = plr

	local energyDrink = Instance.new("BoolValue")
	energyDrink.Name = "EnergyDrink"
	energyDrink.Value = false
	energyDrink.Parent = plr

	local throwCounter = Instance.new("NumberValue")
	throwCounter.Name = "ThrowCounter"
	throwCounter.Value = 0
	throwCounter.Parent = plr

	local cloneCounter = Instance.new("NumberValue")
	cloneCounter.Name = "CloneCounter"
	cloneCounter.Value = 5
	cloneCounter.Parent = plr


	local levelCounter = Instance.new("NumberValue")
	levelCounter.Name = "Level"
	levelCounter.Value = 1
	levelCounter.Parent = plr

	local rank = Instance.new("StringValue")
	rank.Name = "Rank"
	rank.Value = "BRONZE"
	rank.Parent = plr

	local disableClicking = Instance.new("BoolValue")
	disableClicking.Name = "DisableClicking"
	disableClicking.Value = false
	disableClicking.Parent = plr

	local gamePassesCloned = Instance.new("BoolValue")
	gamePassesCloned.Name = "GamepassesCloned"
	gamePassesCloned.Value = false
	gamePassesCloned.Parent = plr

	local ownedGamepasses = Instance.new("Folder")
	ownedGamepasses.Name = "OwnedGamepasses"
	ownedGamepasses.Parent = plr

	local equips = Instance.new("NumberValue")
	equips.Name = "Equips"
	equips.Value = 3
	equips.Parent = plr

	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = plr
	

	-- Load saved data (Cash, Level, Rank)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(plr.UserId .. "_PlayerData")
	end)

	if success and data then
		cash.Value = data.Cash or 0
		levelCounter.Value = data.Level or 1
		rank.Value = data.Rank or "BRONZE"
	else
		warn("Failed to load saved data for " .. plr.Name)
	end

	-- Auto-save function (called every 2 minutes) to only save Level and Rank
	local function autoSave()
		while plr.Parent do
			local level = plr:FindFirstChild("Level")
			local rank = plr:FindFirstChild("Rank")
			local cash = plr:FindFirstChild("Cash")

			if level and rank then
				local dataToSave = {
					Level = level.Value,
					Rank = rank.Value,
					Cash = cash.Value
				}

				local success, errorMessage = pcall(function()
					playerDataStore:SetAsync(plr.UserId .. "_PlayerData", dataToSave)
				end)

				if not success then
					warn("Failed to auto-save data for " .. plr.Name .. ": " .. errorMessage)
				end
			end

			wait(120)  -- Save every 2 minutes
		end
	end

	-- Start the auto-save loop for the player
	spawn(autoSave)
end)

-- Save data when player leaves (level and rank)
game.Players.PlayerRemoving:Connect(function(plr)
	local level = plr:FindFirstChild("Level")
	local rank = plr:FindFirstChild("Rank")
	local cash = plr:FindFirstChild("Cash")

	if level and rank then
		local dataToSave = {
			Level = level.Value,
			Rank = rank.Value,
			Cash = cash.Value
		}

		local success, errorMessage = pcall(function()
			playerDataStore:SetAsync(plr.UserId .. "_PlayerData", dataToSave)
		end)

		if not success then
			warn("Failed to save data for " .. plr.Name .. ": " .. errorMessage)
		end
	end
end)
