-- I am aware this script absolutely stinks but atleast it does the job
---------------------------------------------------------------------------------

local xrayID = 1076336957
local tauntRadarID = 1076802596
local SpeedBoostID = 1075553716
local damageBoostID = 1076482782
local healthBoostID = 1076230768
local freezePropsID = 1076650574
local propRadarID = 1076896403
local ghostPropID = 1076824525
local hunterSwapID = 1076212925

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")  -- Get the TweenService
local DataStoreService = game:GetService("DataStoreService")
local gamepassesDataStore = DataStoreService:GetDataStore("PlayerGamepasses")

local propsTeam = game.Teams.Props
local huntersTeam = game.Teams.Hunters

-- Store connections in a table to manage them manually
local connectionStore = {}

local function ghostProp(player, character)

	if not player or not character then return end

	local ghostPropPass = player:WaitForChild("OwnedGamepasses"):FindFirstChild("Ghost Prop")
	local ghostAmount = player:FindFirstChild("GhostAmount")
	local debounce = false

	if ghostPropPass and ghostPropPass.Value == true then
		local button = player.PlayerGui.Invisible.ImageButton
		-- Clear previous connection for this button
		if connectionStore[button] then
			connectionStore[button]:Disconnect()
			connectionStore[button] = nil
		end

		if not character:FindFirstChild("InvisiblePoof") then
			local poofSound = ReplicatedStorage.InvisiblePoof:Clone()
			poofSound.Parent = character
		end
		-- Create a new connection
		connectionStore[button] = button.MouseButton1Click:Connect(function()
			if not debounce and player.Team == propsTeam and ghostAmount and ghostAmount.Value > 0 then
				debounce = true

				-- Decrement ghostAmount
				ghostAmount.Value -= 1
				player.PlayerGui.Invisible.ImageButton.Amount.Text = ghostAmount.Value

				player:FindFirstChild("DisableClicking").Value = true

				-- Enable VFX
				character:WaitForChild("HumanoidRootPart").Cloud.Enabled = true
				character:WaitForChild("HumanoidRootPart").Cloud1.Enabled = true
				character:WaitForChild("Mail").Handle.Transparency = 1
				character:WaitForChild("InvisiblePoof"):Play()
				wait(0.3)
				character:WaitForChild("HumanoidRootPart").Cloud.Enabled = false
				character:WaitForChild("HumanoidRootPart").Cloud1.Enabled = false

				-- Enable and tween Energy bar
				player.PlayerGui:WaitForChild("Energy").Enabled = true
				if player.PlayerGui.Energy.Bar.Size ~= UDim2.new(0.221, 0, 0.009, 0) then
					player.PlayerGui.Energy.Bar.Size = UDim2.new(0.221, 0, 0.009, 0)
				end

				local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
				local tween = TweenService:Create(player.PlayerGui.Energy.Bar, tweenInfo, {Size = UDim2.new(0, 0, 0.009, 0)})
				tween:Play()
				tween.Completed:Wait()

				-- Reset Energy bar and character visibility
				player.PlayerGui.Energy.Bar.Size = UDim2.new(0.221, 0, 0.009, 0)
				player.PlayerGui.Energy.Enabled = false
				character:WaitForChild("Mail").Handle.Transparency = 0
				player:FindFirstChild("DisableClicking").Value = false

				debounce = false
			end
		end)
	end
end


local function updateSpeed(player, character)
	local speedBoostStatus = player:WaitForChild("OwnedGamepasses"):FindFirstChild("Speed Boost")

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	repeat
		task.wait()
		print("waiting for pass")
	until speedBoostStatus
	
	
	-- Apply speed boost
	if speedBoostStatus.Value == true then
		humanoid.WalkSpeed = 37
		player.PlayerGui.Stamina.SprintHandler.Enabled = false
		local mobileSprintGUI = player.PlayerGui:FindFirstChild("Sprint")
		if mobileSprintGUI then
			local sprintButton = mobileSprintGUI.MobileSprintGUI.Frame:FindFirstChild("ImageButton")
			if sprintButton and sprintButton.Visible then
				local sprinting = sprintButton:FindFirstChild("Sprinting")
				if sprinting then
					sprinting.Enabled = false
				end
			end
		end
	else
		humanoid.WalkSpeed = 24
		player.PlayerGui.Stamina.SprintHandler.Enabled = true
		local mobileSprintGUI = player.PlayerGui:FindFirstChild("Sprint")
		if mobileSprintGUI then
			local sprintButton = mobileSprintGUI.MobileSprintGUI.Frame:FindFirstChild("ImageButton")
			if sprintButton and sprintButton.Visible then
				local sprinting = sprintButton:FindFirstChild("Sprinting")
				if sprinting then
					sprinting.Enabled = true
				end
			end
		end
	end
end

local function updateHealth(plr, humanoid)
	if not humanoid or not plr:FindFirstChild("OriginalMaxHealth") then
		return -- Exit early if conditions aren't met
	end

	local healthBoostStatus = plr:WaitForChild("OwnedGamepasses"):WaitForChild("Health Boost")
	local originalMaxHealth = plr.OriginalMaxHealth.Value
	humanoid.MaxHealth = originalMaxHealth
	-- Set MaxHealth based on Health Boost status
	if healthBoostStatus.Value then
		humanoid.MaxHealth = originalMaxHealth * 2
	else
		humanoid.MaxHealth = originalMaxHealth
	end
	humanoid.Health = humanoid.MaxHealth -- Ensure health is consistent
end

local function setupCharacter(plr, char)
	if char:GetAttribute("SetupComplete") then return end
	char:SetAttribute("SetupComplete", true)

	local healthConnection

	local humanoid = char:WaitForChild("Humanoid")
	local healthBoostStatus = plr:WaitForChild("OwnedGamepasses"):FindFirstChild("Health Boost")

	-- Ensure `OriginalMaxHealth` is set once and not overwritten
	if not plr:FindFirstChild("OriginalMaxHealth") then
		local originalMaxHealthValue = Instance.new("NumberValue")
		originalMaxHealthValue.Name = "OriginalMaxHealth"
		originalMaxHealthValue.Value = humanoid.MaxHealth -- Store true base health
		originalMaxHealthValue.Parent = plr
	end

	updateHealth(plr, humanoid) -- Apply health boost if active

	if healthConnection then
		healthConnection:Disconnect()
	end

	if not healthConnection then
		healthConnection = healthBoostStatus.Changed:Connect(function()
			updateHealth(plr, humanoid)
		end)
	end
end

local function ownCheck(plr, gamepassName)
	local ownedGamepasses = plr:WaitForChild("OwnedGamepasses")
	local pass = ownedGamepasses:FindFirstChild(gamepassName)
	local equips = plr:WaitForChild("Equips")
	
	if not pass then
		pass = Instance.new("BoolValue")
		pass.Name = gamepassName
		pass.Parent = plr:WaitForChild("OwnedGamepasses")
	end

	if equips.Value > 0 then
		pass.Value = true
		equips.Value -= 1
	else
		pass.Value = false
	end


	if gamepassName == "Speed Boost" then

		-- Apply speed to current character if exists
		if plr.Character then
			updateSpeed(plr, plr.Character)
		end

		plr.CharacterAdded:Connect(function(character)
			task.defer(function()
				updateSpeed(plr, character)
			end)
		end)

	elseif gamepassName == "Health Boost" then
		if not plr:FindFirstChild("OriginalMaxHealth") then
			local originalMaxHealthValue = Instance.new("NumberValue")
			originalMaxHealthValue.Name = "OriginalMaxHealth"
			originalMaxHealthValue.Value = plr.Character:WaitForChild("Humanoid").MaxHealth
			originalMaxHealthValue.Parent = plr
		end

		if plr.Character then
			setupCharacter(plr, plr.Character)
		end

		-- Connect CharacterAdded to setupCharacter
		plr.CharacterAdded:Connect(function(char)
			if pass.Value == true then
				-- Store originalMaxHealth in the player object to persist across respawns
				local originalMaxHealth = plr:WaitForChild("OriginalMaxHealth")
				if originalMaxHealth then
					local hum = char:WaitForChild("Humanoid")
					originalMaxHealth.Value = hum.MaxHealth
					setupCharacter(plr, char)
					originalMaxHealth.Value = originalMaxHealth.Value
				end
			else
				local originalMaxHealth = plr:WaitForChild("OriginalMaxHealth")
				if originalMaxHealth then
					local hum = char:WaitForChild("Humanoid")
					originalMaxHealth.Value = hum.MaxHealth
					setupCharacter(plr, char)
				end
			end
		end)
	elseif gamepassName == "Freeze Props" then
		local freezeAmount = plr:FindFirstChild("FreezeAmount")
		if not freezeAmount then
			freezeAmount = Instance.new("NumberValue")
			freezeAmount.Name = "FreezeAmount"
			freezeAmount.Value = 3
			freezeAmount.Parent = plr
		end

		local freezeDebounce = plr:FindFirstChild("FreezeDebounce")
		if not freezeDebounce then
			freezeDebounce = Instance.new("BoolValue")
			freezeDebounce.Name = "FreezeDebounce"
			freezeDebounce.Value = true
			freezeDebounce.Parent = plr
		end
	elseif gamepassName == "Prop Radar" then
		local radarAmount = plr:FindFirstChild("RadarAmount")
		if not radarAmount then
			radarAmount = Instance.new("NumberValue")
			radarAmount.Name = "RadarAmount"
			radarAmount.Value = 3
			radarAmount.Parent = plr
		end
	elseif gamepassName == "Ghost Prop" then
		local ghostAmount = plr:FindFirstChild("GhostAmount")
		if not ghostAmount then
			ghostAmount = Instance.new("NumberValue")
			ghostAmount.Name = "GhostAmount"
			ghostAmount.Value = 3
			ghostAmount.Parent = plr
		end

		if plr.Character then
			ghostProp(plr, plr.Character)
		end

		plr.CharacterAdded:Connect(function(newCharacter)
			ghostProp(plr, newCharacter)
		end)
	end
end

game.Players.PlayerAdded:Connect(function(player)
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("Humanoid") -- Ensures it's fully loaded

	local shopUI = player.PlayerGui:WaitForChild("GamepassUI")
	local gamepasses = shopUI.Gamepasses	

	local playerUserId = "Player_" .. player.UserId

	-- Load saved data from DataStore
	local success, err = pcall(function()
		local savedGamepasses = gamepassesDataStore:GetAsync(playerUserId)
		if savedGamepasses then
			for gamepassName, isOwned in pairs(savedGamepasses) do
				local gamepassID = gamepasses:FindFirstChild(gamepassName)
				if gamepassID and gamepassID:IsA("StringValue") then
					local ownsPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassID.Value)
					if not ownsPass then
						if not player:WaitForChild("OwnedGamepasses"):FindFirstChild(gamepassName) then
							local gamepassValue = Instance.new("BoolValue")
							gamepassValue.Name = gamepassName
							gamepassValue.Parent = player:WaitForChild("OwnedGamepasses")
							if gamepassName == "Freeze Props" then
								local freezeAmount = player:FindFirstChild("FreezeAmount")
								if not freezeAmount then
									freezeAmount = Instance.new("NumberValue")
									freezeAmount.Name = "FreezeAmount"
									freezeAmount.Value = 3
									freezeAmount.Parent = player
								end

								local freezeDebounce = player:FindFirstChild("FreezeDebounce")
								if not freezeDebounce then
									freezeDebounce = Instance.new("BoolValue")
									freezeDebounce.Name = "FreezeDebounce"
									freezeDebounce.Value = true
									freezeDebounce.Parent = player
								end
							elseif gamepassName == "Ghost Prop" then
								local ghostAmount = player:FindFirstChild("GhostAmount")
								if not ghostAmount then
									ghostAmount = Instance.new("NumberValue")
									ghostAmount.Name = "GhostAmount"
									ghostAmount.Value = 3
									ghostAmount.Parent = player
								end
							end	

						end
					end
				end
			end
		end
	end)

	if not success then
		warn("Failed to load player data: " .. err)
	else
		print("success")
	end


	local gamepasses = {
		[xrayID] = "X-Ray Vision",
		[tauntRadarID] = "Taunt Radar",
		[damageBoostID] = "Damage Boost",
		[SpeedBoostID] = "Speed Boost",
		[healthBoostID] = "Health Boost",
		[freezePropsID] = "Freeze Props",
		[propRadarID] = "Prop Radar",
		[ghostPropID] = "Ghost Prop",
		[hunterSwapID] = "Hunter Swap"
	}

	for id, name in pairs(gamepasses) do
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, id) or player:WaitForChild("OwnedGamepasses"):FindFirstChild(name) then
			ownCheck(player, name)
		end
	end

	--========================================================================================================================	
	local cashPrices = {
		["Freeze Props"] = 27000,
		["Ghost Prop"] = 27800,
		["Hunter Swap"] = 25100,
		["Prop Radar"] = 27800,
		["Taunt Radar"] = 36000,
		["X-Ray Vision"] = 26000
	}

	local cashPurchaseGui = player.PlayerGui:WaitForChild("CashPurchase")
	local frame = cashPurchaseGui:FindFirstChildOfClass("Frame")
	local purchaseButton = frame.Purchase

	local debounce = {} -- Table to track active function calls

	-- Ensure the event is only connected once
	if not script:GetAttribute("Connected") then
		script:SetAttribute("Connected", true)

		ReplicatedStorage.ClickedPurchase.OnServerEvent:Connect(function(Player, name)

			-- Debounce check
			if debounce[Player] then
				print("Debounce active for", Player.Name)
				return
			end
			debounce[Player] = true

			-- Use pcall to handle errors and ensure debounce is reset
			local success, err = pcall(function()
				-- Get player data
				local cash = Player:WaitForChild("Cash")
				local equips = Player:WaitForChild("Equips")
				local ownedGamepasses = Player:WaitForChild("OwnedGamepasses")

				-- Check if the item exists in cashPrices
				if not cashPrices[name] then
					warn("Item not found in cashPrices:", name)
					return
				end

				-- Check if the player has enough cash
				local cashNeeded = cashPrices[name]
				if cash.Value < cashNeeded then
					ReplicatedStorage.Fail:FireClient(Player)
					return
				end

				-- Handle gamepass status
				local gamepassStatus = ownedGamepasses:FindFirstChild(name)
				if not gamepassStatus then
					gamepassStatus = Instance.new("BoolValue")
					gamepassStatus.Name = name
					gamepassStatus.Parent = ownedGamepasses
				end

				-- Reduce equips and set gamepass status
				if equips.Value > 0 then
					gamepassStatus.Value = true
					equips.Value -= 1
				else
					gamepassStatus.Value = false
				end

				-- Deduct cash
				cash.Value -= cashNeeded
				ReplicatedStorage.Success:FireClient(Player)

				-- Handle special gamepasses
				if name == "Freeze Props" then
					local freezeAmount = Player:FindFirstChild("FreezeAmount") or Instance.new("NumberValue", Player)
					freezeAmount.Name = "FreezeAmount"
					freezeAmount.Value = 3

					local freezeDebounce = Player:FindFirstChild("FreezeDebounce") or Instance.new("BoolValue", Player)
					freezeDebounce.Name = "FreezeDebounce"
					freezeDebounce.Value = true
				elseif name == "Prop Radar" then
					local radarAmount = Player:FindFirstChild("RadarAmount") or Instance.new("NumberValue", Player)
					radarAmount.Name = "RadarAmount"
					radarAmount.Value = 3
				elseif name == "Ghost Prop" then
					local ghostAmount = Player:FindFirstChild("GhostAmount") or Instance.new("NumberValue", Player)
					ghostAmount.Name = "GhostAmount"
					ghostAmount.Value = 3

					local ghostPropConnection

					if ghostPropConnection then
						ghostPropConnection:Disconnect()
					end
					ghostPropConnection = Player.CharacterAdded:Connect(function(character)
						ghostProp(Player, character)
					end)

					if Player.Character then
						ghostProp(Player, Player.Character)
					end
				end

				-- Save player's gamepasses
				local gamepassesToSave = {}
				for _, gamepass in ipairs(ownedGamepasses:GetChildren()) do
					if gamepass:IsA("BoolValue") then
						gamepassesToSave[gamepass.Name] = gamepass.Value
					end
				end

				local saveSuccess, saveErr = pcall(function()
					gamepassesDataStore:SetAsync(Player.UserId, gamepassesToSave)
				end)

				if not saveSuccess then
					warn("Failed to save player data:", saveErr)
				else
					print("Successfully saved gamepass data for", Player.Name)
				end
			end)

			-- Handle errors and reset debounce
			if not success then
				warn("Error in ClickedPurchase event for", Player.Name, ":", err)
			end

			-- Add a small delay before resetting debounce to prevent rapid firing
			task.delay(0.1, function()
				debounce[Player] = nil
				print("Debounce reset for", Player.Name)
			end)
		end)
	end
end)

-- Set up game pass ownership check
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, gamePassID, purchaseSuccess)
	if purchaseSuccess and gamePassID == damageBoostID then
		ownCheck(plr, "Damage Boost")
	elseif purchaseSuccess and gamePassID == xrayID then
		ownCheck(plr, "X-Ray Vision")
	elseif purchaseSuccess and gamePassID == tauntRadarID then
		ownCheck(plr, "Taunt Radar")
	elseif purchaseSuccess and gamePassID == healthBoostID then
		ownCheck(plr, "Health Boost")
	elseif purchaseSuccess and gamePassID == SpeedBoostID then
		ownCheck(plr, "Speed Boost")
	elseif purchaseSuccess and gamePassID == freezePropsID then
		ownCheck(plr, "Freeze Props")
	elseif purchaseSuccess and gamePassID == propRadarID then
		ownCheck(plr, "Prop Radar")
	elseif purchaseSuccess and gamePassID == ghostPropID then
		ownCheck(plr, "Ghost Prop")
	elseif purchaseSuccess and gamePassID == hunterSwapID then
		ownCheck(plr, "Hunter Swap")
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	local playerUserId = "Player_" .. player.UserId
	local ownedGamepasses = player:FindFirstChild("OwnedGamepasses")

	if ownedGamepasses then
		local success, err = pcall(function()
			local gamepassesToSave = {}
			for _, gamepass in pairs(ownedGamepasses:GetChildren()) do
				if gamepass:IsA("BoolValue") then
					gamepassesToSave[gamepass.Name] = gamepass.Value
				end
			end

			gamepassesDataStore:SetAsync(playerUserId, gamepassesToSave)
		end)

		if not success then
			warn("Failed to save player data: " .. err)
		else
			print("success")
		end
	end
end)

--=================================================================================================================

local function togglePass(player, gamepass, status)
	local ownedGamepasses = player:WaitForChild("OwnedGamepasses")
	local pass = ownedGamepasses:FindFirstChild(gamepass)
	local equips = player:WaitForChild("Equips")

	if status == true then
		if equips.Value > 0 then
			pass.Value = status
			equips.Value -= 1
			if gamepass == "Ghost Prop" then
				if player.Character then
					ghostProp(player, player.Character)
				end
			elseif gamepass == "Speed Boost" then
				if player.Character then
					updateSpeed(player, player.Character)
				end
			elseif gamepass == "Health Boost" then
				if player.Character then
					setupCharacter(player, player.Character)
				end
			end
		end
	else
		if equips.Value < 3 then
			pass.Value = status
			equips.Value += 1

			if gamepass == "Ghost Prop" then
				if player.Character then
					ghostProp(player, player.Character)
				end
			elseif gamepass == "Speed Boost" then
				if player.Character then
					updateSpeed(player, player.Character)
				end
			elseif gamepass == "Health Boost" then
				if player.Character then
					setupCharacter(player, player.Character)
				end
			end
		end
	end
end

ReplicatedStorage.UpdateHunterSwapEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Hunter Swap", newStatus)
end)


ReplicatedStorage.UpdateGhostProp.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Ghost Prop", newStatus)
end)

ReplicatedStorage.UpdateRadarEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Prop Radar", newStatus)
end)

ReplicatedStorage.UpdateFreezePropsEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Freeze Props", newStatus)
end)

-- Handle server event for Speed Boost status change
ReplicatedStorage.UpdateSpeedEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Speed Boost", newStatus)
end)

ReplicatedStorage.UpdateHealthEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Health Boost", newStatus)	
end)


ReplicatedStorage.RadarUpdateEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Taunt Radar", newStatus)
end)


ReplicatedStorage.UpdateEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "X-Ray Vision", newStatus)
end)


ReplicatedStorage.UpdateDamageEvent.OnServerEvent:Connect(function(client, newStatus)
	togglePass(client, "Damage Boost", newStatus)
end)

ReplicatedStorage.ChangeName.OnServerEvent:Connect(function(player, newName)
	-- Find the relevant object on the server and update its name
	local purchase = player.PlayerGui:WaitForChild("CashPurchase"):FindFirstChildOfClass("Frame")
	if purchase then
		purchase.Name = newName
	end
end)
