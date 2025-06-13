local Player = game:GetService("Players").LocalPlayer

local Template = script:WaitForChild("Template")
local DescriptionTemplateRobux = script:WaitForChild("DescriptionRobux")
local DescriptionTemplateCashRobux = script:WaitForChild("DescriptionCashRobux")
local UI = script.Parent
local MainFrame = UI:WaitForChild("Frame")
local Button = UI:WaitForChild("Button")
local Toggle = Button:WaitForChild("outline"):WaitForChild("Toggle")
local close = UI.Frame:WaitForChild("Close")

local propsTeam = game.Teams.Props
local huntersTeam = game.Teams.Hunters
local lobbyTeam = game.Teams.Lobby

local rep = game:GetService("ReplicatedStorage")
local status = rep.Status
local MarketplaceService = game:GetService("MarketplaceService")

local UserInputService = game:GetService("UserInputService")

local RunService = game:GetService("RunService")

local updateEvent = rep:WaitForChild("UpdateEvent")
local radarUpdateEvent = rep:WaitForChild("RadarUpdateEvent")
local updateSpeedEvent = rep:WaitForChild("UpdateSpeedEvent")
local updateDamageEvent = rep:WaitForChild("UpdateDamageEvent")
local updateHealthEvent = rep:WaitForChild("UpdateHealthEvent")
local updateFreezePropsEvent = rep:WaitForChild("UpdateFreezePropsEvent")
local updateRadarEvent = rep:WaitForChild("UpdateRadarEvent")
local updateGhostProp = rep:WaitForChild("UpdateGhostProp")
local updateHunterSwapEvent = rep:WaitForChild("UpdateHunterSwapEvent")

local TweenService = game:GetService("TweenService")
local Debounce = false

local healthID = 1076230768
local damageID = 1076482782
local freezePropsID = 1076650574
local radarID = 1076896403
local ghostPropID = 1076824525
local hunterSwapID = 1076212925
local xRayID = 1076336957
local speedID = 1075553716

local GamepassRequests = UI:WaitForChild("Gamepasses")
local function setHunterOutlineVisibility(visible)
	if Player.Team == propsTeam then
		for i, plr in pairs(game.Players:GetPlayers()) do
			while #huntersTeam:GetPlayers() < 1 do
				print("0 players in the hunters team")
				task.wait(1)
			end
			if plr.Team == huntersTeam then
				local character = plr.Character or plr.CharacterAdded:Wait()
				if character then
					local outline = character:FindFirstChild("PlayerOutline")
					if outline then
						outline.Enabled = visible
					end
				end
			end
		end
	end
end

local function updateOutline()

	local Pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("X-Ray Vision") -- Ensure the player's X-Ray Vision pass exists

	if Player.Team == propsTeam then

		if Pass and Pass.Value == true then
			setHunterOutlineVisibility(true) -- Enable hunter outlines
		else
			setHunterOutlineVisibility(false) -- Disable hunter outlines
		end
	end

	Player:GetPropertyChangedSignal("Team"):Connect(function()
		if Player.Team == propsTeam then

			if Pass and Pass.Value == true then
				setHunterOutlineVisibility(true) -- Enable hunter outlines
			else
				setHunterOutlineVisibility(false) -- Disable hunter outlines
			end
		end
	end)

end


local function updatePassGUI(pass, gui)
	local gamepass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(pass)
	
	if gamepass and gamepass.Value == true then
		gui.Visible = true
	else
		gui.Visible = false
	end
end

local health2X = Player.PlayerGui.Health.Health2X
local damage2X = Player.PlayerGui.Health.Damage2X
local speed2X = Player.PlayerGui.Health.Speed2X

updatePassGUI("Health Boost", health2X)
updatePassGUI("Damage Boost", damage2X)
updatePassGUI("Speed Boost", speed2X)
---------------------------------------------------------------------------------------------------------------------------------------------------
local radarButtonConnection
local radarKeyboardConnection

local shockwaveRadius = 118 -- Radius of the shockwave
local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 1, false)
local goal = { Size = Vector3.new(286.661, 143.33, 286.661) } -- Target size of the shockwave

local function updateRadarGUI()
	if Player.Team == huntersTeam then

		local propRadarStatus = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Prop Radar")
		if propRadarStatus then
			local radarGui = Player.PlayerGui:WaitForChild("Radar")
			local noProps = radarGui.NoProps
			local radarAmount = Player:FindFirstChild("RadarAmount")

			-- Function to tween the transparency of the "NoProps" GUI element
			local function tweenRunTransparency(targetTransparency)
				if noProps then
					local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
					local tween = TweenService:Create(noProps, tweenInfo, { ImageTransparency = targetTransparency })
					tween:Play()
				end
			end

			-- Function to show and hide the "NoProps" GUI
			local function showAndHideGUI()
				noProps.Error:Play()
				tweenRunTransparency(0)
				task.wait(3)
				tweenRunTransparency(1)
			end

			-- Function to activate the radar
			local function activateRadar()
				if radarAmount.Value <= 0 then return end -- Exit if no radar charges are left

				radarAmount.Value -= 1
				radarGui.ImageButton.Amount.Text = radarAmount.Value
				if radarAmount.Value == 0 then
					radarGui.Enabled = false
				end

				-- Clone and set up the shockwave
				local shockWaveClone = rep.RadarWave:Clone()
				local hunterRoot = Player.Character:WaitForChild("HumanoidRootPart")
				shockWaveClone.Parent = workspace
				shockWaveClone.CFrame = hunterRoot.CFrame

				-- Tween the shockwave
				local tween = TweenService:Create(shockWaveClone, tweenInfo, goal)
				tween:Play()

				-- Play the shockwave sound
				workspace.RadarSound:Play()

				-- Variable to check if at least one prop is found
				local foundProp = false 

				-- Continuously check for props during the tween
				local startTime = tick()
				local function checkForProps()
					while tick() - startTime < tweenInfo.Time do
						for _, prop in ipairs(game.Teams.Props:GetPlayers()) do
							if prop.Character then
								local propRoot = prop.Character.PrimaryPart or prop.Character:FindFirstChild("HumanoidRootPart")
								if propRoot then
									local distance = (hunterRoot.Position - propRoot.Position).Magnitude
									if distance <= shockwaveRadius then
										if not prop.Character:FindFirstChild("Radar") then
											local radarClone = rep.Radar:Clone()
											radarClone.Parent = prop.Character

											-- Remove after 10 seconds
											task.delay(10, function()
												if radarClone.Parent then
													radarClone:Destroy()
												end
											end)
										end
										foundProp = true
									end
								end
							end
						end
						task.wait(0.1) -- Check every 0.1 seconds
					end
				end

				-- Run the check while tweening
				task.spawn(checkForProps)
				
				tween.Completed:Connect(function()
					if not foundProp then
						showAndHideGUI() -- No props were found, show the "NoProps" UI
					end
					shockWaveClone:Destroy()
				end)
			end

			-- Function to enable or disable the radar GUI and connections
			local function radarGUI()
				if propRadarStatus and propRadarStatus.Value == true and Player.Team == huntersTeam and radarAmount.Value > 0 then
					radarGui.Enabled = true

					-- Connect button click event
					if not radarButtonConnection then
						radarButtonConnection = radarGui.ImageButton.MouseButton1Click:Connect(activateRadar)
					end

					-- Connect keyboard input event
					if not radarKeyboardConnection then
						radarKeyboardConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
							if not gameProcessed and input.KeyCode == Enum.KeyCode.E then
								activateRadar()
							end
						end)
					end
				else
					radarGui.Enabled = false

					-- Disconnect events if they exist
					if radarButtonConnection then
						radarButtonConnection:Disconnect()
						radarButtonConnection = nil
					end

					if radarKeyboardConnection then
						radarKeyboardConnection:Disconnect()
						radarKeyboardConnection = nil
					end
				end
			end

			radarGUI()
		else
			print("prop radar status doesnt exist")
		end
	end
end



---------------------------------------------------------------------------------------------------------------------------------------------------
local freezeConnection
local buttonConnection
local keyboardButtonConnection

local function updateFreezeGUI()
	local shockwaveGui = Player.PlayerGui:WaitForChild("Freeze")
	local freezeButton = shockwaveGui:WaitForChild("ImageButton")
	local freezePropsPass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Freeze Props")
	if freezePropsPass then
		local freezeAmount = Player:FindFirstChild("FreezeAmount")
		local freezeDebounce = Player:FindFirstChild("FreezeDebounce")

		local function activateFreeze()
			if freezeAmount.Value <= 0 or freezeDebounce.Value == false then return end -- Exit if no charges or debounce is active

			freezeAmount.Value -= 1
			freezeButton.Amount.Text = freezeAmount.Value

			if freezeAmount.Value == 0 then
				shockwaveGui.Enabled = false
			end

			-- Fire the server event to freeze props
			if not freezeConnection then
				freezeConnection = rep:WaitForChild("FreezeProps"):FireServer()
			end
		end

		-- Function to enable or disable the freeze GUI and connections
		local function updateFreeze()
			if freezePropsPass.Value == true and Player.Team == huntersTeam and freezeAmount.Value > 0 then
				shockwaveGui.Enabled = true

				-- Connect button click event if not already connected
				if not buttonConnection then
					buttonConnection = freezeButton.MouseButton1Click:Connect(activateFreeze)
				end

				-- Connect keyboard input event if not already connected
				if not keyboardButtonConnection then
					keyboardButtonConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if not gameProcessed and input.KeyCode == Enum.KeyCode.Q then
							activateFreeze()
						end
					end)
				end
			else
				shockwaveGui.Enabled = false

				-- Disconnect events if they exist
				if buttonConnection then
					buttonConnection:Disconnect()
					buttonConnection = nil
				end

				if keyboardButtonConnection then
					keyboardButtonConnection:Disconnect()
					keyboardButtonConnection = nil
				end
			end
		end

		updateFreeze()
	else
		print("freeze props pass not valid")
	end
end

local function ghostPropGUI()
	local Pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Ghost Prop")

	local invisibleGui = Player:WaitForChild("PlayerGui"):WaitForChild("Invisible")

	if Pass then
		local ghostAmount = Player:WaitForChild("GhostAmount")
		
		if ghostAmount then
			if Pass.Value == true then
				if Player.Team == propsTeam and ghostAmount.Value > 0 then
					invisibleGui.Enabled = true
				else
					invisibleGui.Enabled = false
				end
			else
				invisibleGui.Enabled = false
			end
		end
		invisibleGui.ImageButton.MouseButton1Click:Connect(function()
			if Player.Team == propsTeam and ghostAmount and ghostAmount.Value < 2 then
				invisibleGui.Enabled = false
			end
		end)
		
		Player:GetPropertyChangedSignal("Team"):Connect(function()
			if Player.Team ~= huntersTeam then
				if ghostAmount and ghostAmount.Value < 3 then
					ghostAmount.Value = 3
				end
			else
				invisibleGui.Enabled = false
			end
		end)
	end
end

local swappingDisabled = false -- Persistent cooldown flag
local playerConnections = {} -- Make sure this is declared globally

local function hunterSwap()
	if Player.Team == propsTeam then
		local pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Hunter Swap")
		if swappingDisabled then return end

		local function manageProximity(enable)
			swappingDisabled = not enable

			for _, player in pairs(game.Players:GetPlayers()) do
				if player.Team == huntersTeam and player.Character then
					local humanoidRoot = player.Character:FindFirstChild("HumanoidRootPart")
					local proximity = humanoidRoot and humanoidRoot:FindFirstChild("SwapProximity")
					if proximity then
						if player == Player or Player.Team == huntersTeam then
							proximity.Enabled = false
						else
							proximity.Enabled = enable
						end
					end

					if playerConnections[player] then
						playerConnections[player]:Disconnect()
					end

					playerConnections[player] = player.CharacterAdded:Connect(function(char)
						RunService.RenderStepped:Wait()
						local humanRoot = char:WaitForChild("HumanoidRootPart")
						local newProximity = humanRoot:FindFirstChild("SwapProximity")
						if newProximity then
							if player == Player or Player.Team == huntersTeam then
								newProximity.Enabled = false
							else
								newProximity.Enabled = enable
							end
						end
					end)
				end
			end
		end

		if pass and pass.Value then
			local function createProximity(player)
				if not player or player == Player then return end

				while not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) do
					RunService.RenderStepped:Wait()
				end

				local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
				if not rootPart then return end

				local oldProximity = rootPart:FindFirstChild("SwapProximity")
				if oldProximity then oldProximity:Destroy() end

				local swapProximity = Instance.new("ProximityPrompt")
				swapProximity.Name = "SwapProximity"
				swapProximity.Enabled = not swappingDisabled
				swapProximity.ClickablePrompt = true
				swapProximity.HoldDuration = 0.5
				swapProximity.KeyboardKeyCode = Enum.KeyCode.R
				swapProximity.MaxActivationDistance = 100
				swapProximity.RequiresLineOfSight = false
				swapProximity.ActionText = "Swap with " .. player.Name
				swapProximity.Parent = rootPart

				swapProximity.Triggered:Connect(function()
					if swappingDisabled then return end

					local playerHRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
					local hoveredPlayerHRP = swapProximity.Parent
					if playerHRP and hoveredPlayerHRP then
						rep.HunterSwap:FireServer(playerHRP, hoveredPlayerHRP)
					end

					-- Start cooldown
					swappingDisabled = true
					manageProximity(false)

					-- Show cooldown UI
					local teleportGui = Player.PlayerGui:WaitForChild("TeleportCooldown")
					teleportGui.Enabled = true
					teleportGui.Bar.Size = UDim2.new(0.221, 0, 0.009, 0)

					local tween = TweenService:Create(
						teleportGui.Bar,
						TweenInfo.new(25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
						{Size = UDim2.new(0, 0, 0.009, 0)}
					)
					tween:Play()

					-- Schedule end of cooldown
					task.delay(25, function()
						swappingDisabled = false
						teleportGui.Bar.Size = UDim2.new(0.221, 0, 0.009, 0)
						teleportGui.Enabled = false

						if pass and pass.Value then
							manageProximity(true)
						end
					end)
				end)
			end

			local function setupPlayer(player)
				player:GetPropertyChangedSignal("Team"):Connect(function()
					if player.Team == huntersTeam then
						createProximity(player)
						if pass and pass.Value then
							manageProximity(true)
						end
					end
				end)

				player.CharacterAdded:Connect(function()
					if player.Team == huntersTeam then
						createProximity(player)
						if pass and pass.Value then
							manageProximity(true)
						end
					end
				end)
			end

			for _, player in pairs(game.Players:GetPlayers()) do
				setupPlayer(player)
				if player.Team == huntersTeam then
					createProximity(player)
				end
			end

			game.Players.PlayerAdded:Connect(function(player)
				setupPlayer(player)
			end)

			manageProximity(true)
		else
			manageProximity(false)
		end
	end
end


local function resetAmountGUIs(gamepassName, amountGui, amountText, amountValue)
	local pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(gamepassName)
	local playerAmount = Player:FindFirstChild(amountValue)
	if pass then
		if playerAmount then
			playerAmount.Value = 3
			amountText.Text = playerAmount.Value
			if amountGui and amountGui.Enabled then
				amountGui.Enabled = false
			end
		end
	end
end

local radarGui = Player.PlayerGui:WaitForChild("Radar")
local radarAmountText = radarGui.ImageButton.Amount

local freezeGui = Player.PlayerGui:WaitForChild("Freeze")
local freezeAmountText = freezeGui.ImageButton.Amount

local ghostGui = Player.PlayerGui:WaitForChild("Invisible")
local ghostAmountText = ghostGui.ImageButton.Amount

resetAmountGUIs("Prop Radar", radarGui, radarAmountText, "RadarAmount")
resetAmountGUIs("Freeze Props", freezeGui, freezeAmountText, "FreezeAmount")
resetAmountGUIs("Ghost Prop", ghostGui, ghostAmountText, "GhostAmount")

local function createPulseTween(circle)
	-- TweenInfo: Duration, EasingStyle, EasingDirection, RepeatCount, Reverses, DelayTime
	local tweenInfo = TweenInfo.new(
		0.5,                       -- Tween duration (half a second)
		Enum.EasingStyle.Quad,     -- Smooth easing
		Enum.EasingDirection.Out,  -- Easing direction
		0,                         -- No repeat
		false,                     -- Do not reverse
		0                          -- No delay
	)

	-- Target size for the circle
	local goal = {Size = UDim2.new(1.5, 0, 1.5, 0)}

	-- Create and return the Tween
	return TweenService:Create(circle, tweenInfo, goal)
end

local function taunt(prop) -- prop is now correctly received
	if Player.Team == huntersTeam then
		local tauntRadarPass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Taunt Radar")
		if tauntRadarPass and tauntRadarPass.Value == true then
			if prop and prop.Team == propsTeam and prop.Character then -- Added a check for prop
				local humanoidRootPart = prop.Character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					local billboardGui = humanoidRootPart:FindFirstChild("CircleRadar")
					local circle = billboardGui and billboardGui:FindFirstChild("ImageLabel")

					if billboardGui and circle then
						billboardGui.Enabled = true

						-- Tweening logic
						for i = 1, 10 do 
							circle.Size = UDim2.new(0, 0, 0, 0)
							local pulseTween = createPulseTween(circle)
							pulseTween:Play()
							pulseTween.Completed:Wait()
						end

						-- Disable radar after pulsing
						billboardGui.Enabled = false
					end
				end
			end
		end
	end
end


if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, speedID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Speed Boost") then
	updatePassGUI("Speed Boost", speed2X)
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, healthID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Health Boost") then
	updatePassGUI("Health Boost", health2X)
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, damageID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Damage Boost") then
	updatePassGUI("Damage Boost", damage2X)
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, radarID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Prop Radar") then
	updateRadarGUI()
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, freezePropsID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Freeze Props") then
	updateFreezeGUI()
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, hunterSwapID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("Hunter Swap") then
	hunterSwap()
end

if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, xRayID) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild("X-Ray Vision") then
	updateOutline()
end

-- Fix: Accepts prop as argument now
rep:WaitForChild("DisplayRadarEvent").OnClientEvent:Connect(function(prop)
	taunt(prop)
end)


local cashPrices = {
	["Freeze Props"] = 27000,
	["Ghost Prop"] = 27800,
	["Hunter Swap"] = 27000,
	["Prop Radar"] = 27800,
	["Taunt Radar"] = 32000,
	["X-Ray Vision"] = 24000
}

local inventoryUI = Player.PlayerGui:WaitForChild("InventoryUI")
local inventoryFrame = inventoryUI:WaitForChild("Frame")
local inventoryList = inventoryFrame:WaitForChild("List")

local function CloseUI()
	local Tween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0), { Size = UDim2.new(0, 0, 0, 0) })
	Tween.Completed:Connect(function()
		MainFrame.Visible = false
		game.Lighting.Blur.Enabled = false
		for i, descriptionFrame in pairs(Player.PlayerGui.DescriptionGUI:GetChildren()) do
			descriptionFrame.Visible = false
		end
	end)
	Tween:Play()
end

Toggle.Activated:Connect(function()
	if Debounce == true then return end
	Debounce = true
	script["Click"]:Play()
	if MainFrame.Visible == true then
		CloseUI()
		task.wait(0.65)
		Debounce = false
	else
		if inventoryFrame.Visible then
			inventoryFrame.Visible = false
		end
		MainFrame.Position = UDim2.new(0.47, 0, 0.425, 0)
		MainFrame.Size = UDim2.new(0.516, 0, 0.581, 0)
		TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { Position = UDim2.new(0.47, 0, 0.51, 0) }):Play()
		MainFrame.Visible = true
		game.Lighting.Blur.Enabled = true
		task.wait(0.35)
		Debounce = false
	end
end)

close.Activated:Connect(function()
	if Debounce then return end
	Debounce = true
	CloseUI()
	task.wait(0.35)
	Debounce = false
end)

local function CreateTemplate(Info, ID)
	local NewTemplate = Template:Clone() 
	NewTemplate.Name = Info["Name"]
	NewTemplate.TextLabel.Text = Info["Name"]
	NewTemplate.GamePassImage.Image = "rbxassetid://" .. Info["IconImageAssetId"]
	local priceBarCash = NewTemplate.Prices.PriceBarCash
	local imageCash = priceBarCash.ImageLabel
	local textCash = priceBarCash.TextLabel

	if NewTemplate.Name == "Speed Boost" or NewTemplate.Name == "Health Boost" or NewTemplate.Name == "Damage Boost" then
		imageCash.ImageTransparency = 1
		textCash.TextTransparency = 1
	else
		imageCash.ImageTransparency = 0
		textCash.TextTransparency = 0
	end

	local gamePass = Player.PlayerGui.GamepassUI.Gamepasses:WaitForChild(Info["Name"])
	if not gamePass then
		warn("Gamepass ID not found!")
		return
	end

	local ownedGamepass = Player:WaitForChild("OwnedGamepasses"):GetChildren()
	local ownsPass = MarketplaceService:UserOwnsGamePassAsync(Player.UserId, gamePass.Value) or Player:WaitForChild("OwnedGamepasses"):FindFirstChild(Info["Name"])

	if #ownedGamepass > 0 then
		if ownsPass then
			gamePass:Clone().Parent = Player.PlayerGui.InventoryUI.Gamepasses
			local clonedGamepass = Player.PlayerGui.InventoryUI.Gamepasses:GetChildren()

			if #clonedGamepass == #ownedGamepass then
				Player:WaitForChild("GamepassesCloned").Value = true
			end
		end
	end

	if not ownsPass then
		NewTemplate.Prices.PriceBar.TextLabel.Text = Info["PriceInRobux"]
		if textCash.TextTransparency == 0 then
			textCash.Text = cashPrices[Info["Name"]]
		end
	else
		for i, inventoryTemplate in pairs(inventoryList:GetChildren()) do
			if inventoryTemplate:IsA("Frame") then
				local templateStatus = inventoryTemplate.EquipStatus.TextLabel
				local playerGamepass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(inventoryTemplate.Name)

				if playerGamepass then
					if playerGamepass.Value == true then
						templateStatus.Text = "EQUIPPED"
						templateStatus.TextColor3 = Color3.fromRGB(170, 255, 0)
					else
						templateStatus.Text = "UNEQUIPPED"
						templateStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
					end
				else
					return
				end

			end
		end

		if NewTemplate.Prices then
			NewTemplate.Prices:Destroy()
		end
		if NewTemplate.Owned then
			NewTemplate.Owned.Visible = true
			NewTemplate.Owned.TextLabel.Name = Info["Name"]
		end
	end

	NewTemplate.TextButton.Activated:Connect(function()
		
		if NewTemplate.Name == "Speed Boost" or NewTemplate.Name == "Health Boost" or NewTemplate.Name == "Damage Boost" then
			local existingClone = Player.PlayerGui.DescriptionGUI:FindFirstChild(Info["Name"])
			local newDescriptionTemplateRobux

			local equips = Player:WaitForChild("Equips")

			if not existingClone then
				newDescriptionTemplateRobux = DescriptionTemplateRobux:Clone()
				newDescriptionTemplateRobux.Name = Info["Name"]
				newDescriptionTemplateRobux:SetAttribute("Type", "shop")
				local equipStatus = newDescriptionTemplateRobux:WaitForChild("EquipStatus")
				local framePurchase = newDescriptionTemplateRobux:WaitForChild("BackgroundStatus")
				local purchase = newDescriptionTemplateRobux:WaitForChild("Purchase")
				local owned = newDescriptionTemplateRobux:WaitForChild("Owned")

				local inventoryTemplate
				local templateStatus

				MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassID, purchaseSuccess)
					if purchaseSuccess == true and ID == gamePassID then

						local Pass = player:WaitForChild("OwnedGamepasses"):WaitForChild(Info["Name"])
						local warning = player.PlayerGui:WaitForChild("MaxEquips")

						local equipsAfterPurchase = player:WaitForChild("Equips")

						if not player.PlayerGui.InventoryUI.Gamepasses:FindFirstChild(Info["Name"]) then
							gamePass:Clone().Parent = player.PlayerGui.InventoryUI.Gamepasses
							player:WaitForChild("GamepassesCloned").Value = true
						end

						if newDescriptionTemplateRobux:FindFirstChild("PriceBar") then
							newDescriptionTemplateRobux:FindFirstChild("PriceBar"):Destroy()
						end

						if purchase then
							purchase:Destroy()
						end

						if owned then
							owned.Visible = true
						end

						if NewTemplate:WaitForChild("Prices") then
							NewTemplate.Prices:Destroy()
						end
						if NewTemplate:WaitForChild("Owned") then
							NewTemplate.Owned.Visible = true
							NewTemplate.Owned.TextLabel.Name = Info["Name"]
						end

						equipStatus.Visible = true
						purchase.Visible = false

						inventoryTemplate = inventoryList:WaitForChild(Info["Name"])

						if inventoryTemplate then
							templateStatus = inventoryTemplate.EquipStatus.TextLabel

							if Pass.Value == true then
								equipStatus.Text = "EQUIPPED"
								templateStatus.Text = "EQUIPPED"
							else
								equipStatus.Text = "UNEQUIPPED"
								templateStatus.Text = "UNEQUIPPED"
							end

							if Pass.Value == false then
								equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
								framePurchase.UIStroke.Color = equipStatus.TextColor3
								templateStatus.TextColor3 = equipStatus.TextColor3
							end

						else
							print("inventory template not found or smth")
						end

						local function toggleGamepass()

							if Pass.Value == false then -- Trying to equip
								if equipsAfterPurchase.Value > 0 and equipsAfterPurchase.Value <= 3 then
									Pass.Value = true  -- Equip the pass
								elseif equipsAfterPurchase.Value == 0 then
									if warning.Enabled == false then
										warning.Enabled = true

										MainFrame.Visible = false
										if inventoryFrame.Visible then
											inventoryFrame.Visible = false
											inventoryFrame:SetAttribute("Visible", false)
										end
										if newDescriptionTemplateRobux.Visible == true then
											newDescriptionTemplateRobux.Visible = false
										end
									end
									return nil
								end
							else -- Unequipping
								Pass.Value = false
							end

							-- Reflect current equip status
							local isEquipped = Pass.Value
							local status = isEquipped and "EQUIPPED" or "UNEQUIPPED"

							equipStatus.Text = status
							equipStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
							framePurchase.UIStroke.Color = equipStatus.TextColor3 -- Match background to text color

							if inventoryTemplate then
								local templateStatus = inventoryTemplate.EquipStatus.TextLabel
								templateStatus.Text = status
								templateStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
							end


							if Pass.Name == "X-Ray Vision" then
								updateEvent:FireServer(Pass.Value)
								updateOutline()
							elseif Pass.Name == "Taunt Radar" then
								radarUpdateEvent:FireServer(Pass.Value)
							elseif Pass.Name == "Speed Boost" then
								updateSpeedEvent:FireServer(Pass.Value)
								updatePassGUI("Speed Boost", speed2X)
							elseif Pass.Name == "Damage Boost" then
								updateDamageEvent:FireServer(Pass.Value)
								updatePassGUI("Damage Boost", damage2X)
							elseif Pass.Name == "Health Boost" then
								updateHealthEvent:FireServer(Pass.Value)
								updatePassGUI("Health Boost", health2X)
							elseif Pass.Name == "Freeze Props" then
								updateFreezePropsEvent:FireServer(Pass.Value)
								updateFreezeGUI()
							elseif Pass.Name == "Prop Radar" then
								updateRadarEvent:FireServer(Pass.Value)
								updateRadarGUI()
							elseif Pass.Name == "Ghost Prop" then
								updateGhostProp:FireServer(Pass.Value)
								ghostPropGUI()
							elseif Pass.Name == "Hunter Swap" then
								updateHunterSwapEvent:FireServer(Pass.Value)
								hunterSwap()

							end

						end
						
						if newDescriptionTemplateRobux:GetAttribute("Type") == "shop" then
							newDescriptionTemplateRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
								toggleGamepass()
							end)
							
						elseif newDescriptionTemplateRobux:GetAttribute("Type") == "inventory" then
							newDescriptionTemplateRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
								toggleGamepass()
							end)
						end

						if Pass.Name == "X-Ray Vision" then		
							updateOutline()
						elseif Pass.Name == "Health Boost" then
							updatePassGUI("Health Boost", health2X)
						elseif Pass.Name == "Damage Boost" then
							updatePassGUI("Damage Boost", damage2X)
						elseif Pass.Name == "Freeze Props" then
							updateFreezeGUI()
						elseif Pass.Name == "Prop Radar" then
							updateRadarGUI()
						elseif Pass.Name == "Ghost Prop" then
							ghostPropGUI()
						elseif Pass.Name == "Hunter Swap" then
							hunterSwap()
						elseif Pass.Name == "Speed Boost" then
							updatePassGUI("Speed Boost", speed2X)
						end
					end
				end)

				local warningGUI = Player.PlayerGui:WaitForChild("MaxEquips")

				local Pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(Info["Name"])

				if not Pass then
					newDescriptionTemplateRobux.PriceBar.TextLabel.Text = Info["PriceInRobux"]
				else

					if newDescriptionTemplateRobux:FindFirstChild("PriceBar") then
						newDescriptionTemplateRobux:FindFirstChild("PriceBar"):Destroy()
					end

					equipStatus.Visible = true
					purchase.Visible = false
					owned.Visible = true

					if not framePurchase.Visible then
						framePurchase.Visible = true
					end

					inventoryTemplate = inventoryList:FindFirstChild(Info["Name"])

					if inventoryTemplate then
						templateStatus = inventoryTemplate.EquipStatus.TextLabel

						if Pass.Value == true then
							equipStatus.Text = "EQUIPPED"
							templateStatus.Text = "EQUIPPED"

						else
							equipStatus.Text = "UNEQUIPPED"
							templateStatus.Text = "UNEQUIPPED"

						end

						if Pass.Value == false then
							equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
							framePurchase.UIStroke.Color = equipStatus.TextColor3
							templateStatus.TextColor3 = equipStatus.TextColor3
						end
					end

					local function toggleGamepass()

						if Pass.Value == false then -- Trying to equip
							if equips.Value > 0 and equips.Value <= 3 then
								Pass.Value = true  -- Equip the pass
							elseif equips.Value == 0 then
								if warningGUI.Enabled == false then
									warningGUI.Enabled = true

									MainFrame.Visible = false
									if inventoryFrame.Visible then
										inventoryFrame.Visible = false
										inventoryFrame:SetAttribute("Visible", false)
									end
									if newDescriptionTemplateRobux.Visible == true then
										newDescriptionTemplateRobux.Visible = false
									end
								end
								return nil
							end
						else -- Unequipping
							Pass.Value = false
						end

						-- Reflect current equip status
						local isEquipped = Pass.Value
						local status = isEquipped and "EQUIPPED" or "UNEQUIPPED"

						equipStatus.Text = status
						equipStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						framePurchase.UIStroke.Color = equipStatus.TextColor3 -- Match background color to text color

						if inventoryTemplate then
							local templateStatus = inventoryTemplate.EquipStatus.TextLabel
							templateStatus.Text = status
							templateStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						end

						if Pass.Name == "X-Ray Vision" then
							updateEvent:FireServer(Pass.Value)
							updateOutline()
						elseif Pass.Name == "Taunt Radar" then
							radarUpdateEvent:FireServer(Pass.Value)
						elseif Pass.Name == "Speed Boost" then
							updateSpeedEvent:FireServer(Pass.Value)
							updatePassGUI("Speed Boost", speed2X)
						elseif Pass.Name == "Damage Boost" then
							updateDamageEvent:FireServer(Pass.Value)
							updatePassGUI("Damabe Boost", damage2X)
						elseif Pass.Name == "Health Boost" then
							updateHealthEvent:FireServer(Pass.Value)
							updatePassGUI("Health Boost", health2X)
						elseif Pass.Name == "Freeze Props" then
							updateFreezePropsEvent:FireServer(Pass.Value)
							updateFreezeGUI()
						elseif Pass.Name == "Prop Radar" then
							updateRadarEvent:FireServer(Pass.Value)
							updateRadarGUI()
						elseif Pass.Name == "Ghost Prop" then
							updateGhostProp:FireServer(Pass.Value)
							ghostPropGUI()
						elseif Pass.Name == "Hunter Swap" then
							updateHunterSwapEvent:FireServer(Pass.Value)
							hunterSwap()
						end
					end
					if newDescriptionTemplateRobux:GetAttribute("Type") == "shop" then
						newDescriptionTemplateRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)

					elseif newDescriptionTemplateRobux:GetAttribute("Type") == "inventory" then
						newDescriptionTemplateRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)
					end
				end

				newDescriptionTemplateRobux.PassName.Text = Info["Name"]
				newDescriptionTemplateRobux.GamePassImage.Image = "rbxassetid://" .. Info["IconImageAssetId"]
				if newDescriptionTemplateRobux.PassName.Text == "X-Ray Vision" then
					newDescriptionTemplateRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO SEE HUNTERS EVERYWHERE. EVEN THROUGH WALLS!"
				elseif newDescriptionTemplateRobux.PassName.Text == "Taunt Radar" then
					newDescriptionTemplateRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DETECT PROPS EFFORTLESSLY WHEN THEY TAUNT"
				elseif newDescriptionTemplateRobux.PassName.Text == "Speed Boost" then
					newDescriptionTemplateRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X SPEED"
				elseif newDescriptionTemplateRobux.PassName.Text == "Damage Boost" then
					newDescriptionTemplateRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DEAL 2X MORE DAMAGE MAKING IT EASIER TO KILL OPPOSING PLAYERS"
				elseif newDescriptionTemplateRobux.PassName.Text == "Health Boost" then
					newDescriptionTemplateRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X HEALTH"
				elseif newDescriptionTemplateRobux.PassName.Text == "Freeze Props" then
					newDescriptionTemplateRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO FREEZE ANY PROP WITHIN YOUR SHOCKWAVE RADIUS (3 uses per round)"
				elseif newDescriptionTemplateRobux.PassName.Text == "Prop Radar" then
					newDescriptionTemplateRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO EASILY DETECT PROPS WITHIN YOUR RADAR RADIUS (3 uses per round)"
				elseif newDescriptionTemplateRobux.PassName.Text == "Ghost Prop" then
					newDescriptionTemplateRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO BECOME INVISIBLE FOR 10 SECONDS (3 uses per round)"
				elseif newDescriptionTemplateRobux.PassName.Text == "Hunter Swap" then
					newDescriptionTemplateRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS PROPS TO SWAP PLACES WITH HUNTERS THEY CLICK ON. 40 SECOND COOLDOWN BETWEEN EACH USE"
				end

				purchase.Activated:Connect(function()
					if Debounce == true then return end
					Debounce = true
					script["Bell"]:Play()
					MarketplaceService:PromptGamePassPurchase(Player, ID)
					CloseUI()
					task.wait(0.65)
					Debounce = false
				end)

				newDescriptionTemplateRobux.Parent = Player.PlayerGui.DescriptionGUI
			else
				if not existingClone.Visible then
					existingClone.Visible = true
				end
			end
		else
			local existingClone = Player.PlayerGui.DescriptionGUI:FindFirstChild(Info["Name"])
			local newDescriptionTemplateCashRobux

			local equips = Player:WaitForChild("Equips")	
			local cash = Player:WaitForChild("Cash")

			local cashPurchaseGui = Player.PlayerGui.CashPurchase

			if not existingClone then
				newDescriptionTemplateCashRobux = DescriptionTemplateCashRobux:Clone()
				newDescriptionTemplateCashRobux.Name = Info["Name"]
				newDescriptionTemplateCashRobux:SetAttribute("Type", "shop")
				local equipStatus = newDescriptionTemplateCashRobux:WaitForChild("EquipStatus")
				local framePurchase = newDescriptionTemplateCashRobux:WaitForChild("BackgroundStatus")
				local purchase = newDescriptionTemplateCashRobux:WaitForChild("PurchaseCash")
				local purchaseRobux = newDescriptionTemplateCashRobux:WaitForChild("Purchase")
				local owned = newDescriptionTemplateCashRobux:WaitForChild("Owned")
				local priceBarCashDescription = newDescriptionTemplateCashRobux:WaitForChild("PriceBarCash")
				local priceBar = newDescriptionTemplateCashRobux:WaitForChild("PriceBar")

				local robuxBackground = newDescriptionTemplateCashRobux:WaitForChild("FramePurchase")
				local cashBackground = newDescriptionTemplateCashRobux:WaitForChild("FramePurchaseCash")

				local frame = cashPurchaseGui:FindFirstChildOfClass("Frame")

				local dialog = frame.Dialog

				local priceBarCashPurchasing = frame.PriceBarCash.TextLabel

				local purchaseSuccessGui = Player:WaitForChild("PlayerGui"):WaitForChild("PurchaseSuccess")
				local successText = purchaseSuccessGui.Frame.Dialog
				local statusTitle = purchaseSuccessGui.Frame.TextLabel

				local inventoryTemplate
				local templateStatus

				rep.Fail.OnClientEvent:Connect(function()
					purchaseSuccessGui.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					purchaseSuccessGui.Enabled = true
					successText.Text = "Not enough cash to purchase this item."
					statusTitle.Text = "PURCHASE FAILED"
				end)


				local eventConnected = false  -- This will ensure the event is only connected once

				rep.Success.OnClientEvent:Connect(function()
					if eventConnected then return end  -- If the event is already connected, exit the function
					eventConnected = true  -- Mark the event as connected

					purchaseSuccessGui.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					purchaseSuccessGui.Enabled = true
					successText.Text = "You successfully purchased " .. Info["Name"] .. "!"
					statusTitle.Text = "PURCHASE SUCCESS!"

					local Pass = Player:WaitForChild("OwnedGamepasses"):WaitForChild(Info["Name"])
					print(Pass)
					local warning = Player.PlayerGui:WaitForChild("MaxEquips")                

					if not Player.PlayerGui.InventoryUI.Gamepasses:FindFirstChild(Info["Name"]) then
						gamePass:Clone().Parent = Player.PlayerGui.InventoryUI.Gamepasses
						Player:WaitForChild("GamepassesCloned").Value = true
					end

					local elementsToDestroy = {priceBar, purchase, purchaseRobux, priceBarCash, priceBarCashDescription, cashBackground, robuxBackground}

					for _, element in ipairs(elementsToDestroy) do
						if element then
							element:Destroy()
						end
					end

					if owned then
						owned.Visible = true
					end

					if not framePurchase.Visible then
						framePurchase.Visible = true
					end

					if NewTemplate:WaitForChild("Prices") then
						NewTemplate.Prices:Destroy()
					end
					if NewTemplate:WaitForChild("Owned") then
						NewTemplate.Owned.Visible = true
						NewTemplate.Owned.TextLabel.Name = Info["Name"]
					end

					equipStatus.Visible = true
					purchase.Visible = false

					inventoryTemplate = inventoryList:WaitForChild(Info["Name"])

					if inventoryTemplate then
						templateStatus = inventoryTemplate.EquipStatus.TextLabel

						if Pass.Value == true then
							equipStatus.Text = "EQUIPPED"
							templateStatus.Text = "EQUIPPED"
						else
							equipStatus.Text = "UNEQUIPPED"
							templateStatus.Text = "UNEQUIPPED"
						end

						if Pass.Value == false then
							equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
							framePurchase.UIStroke.Color = equipStatus.TextColor3
							templateStatus.TextColor3 = equipStatus.TextColor3
						end

					else
						print("inventory template not found or smth")
					end

					local function toggleGamepass()
						if Pass.Value == false then -- Trying to equip
							if equips.Value > 0 and equips.Value <= 3 then
								Pass.Value = true  -- Equip the pass
							elseif equips.Value == 0 then
								if warning.Enabled == false then
									warning.Enabled = true

									MainFrame.Visible = false
									if inventoryFrame.Visible then
										inventoryFrame.Visible = false
										inventoryFrame:SetAttribute("Visible", false)
									end

									if newDescriptionTemplateCashRobux.Visible == true then
										newDescriptionTemplateCashRobux.Visible = false
									end
								end
								return nil
							end
						else -- Unequipping
							Pass.Value = false
						end

						-- Reflect current equip status
						local isEquipped = Pass.Value
						local status = isEquipped and "EQUIPPED" or "UNEQUIPPED"

						equipStatus.Text = status
						equipStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						framePurchase.UIStroke.Color = equipStatus.TextColor3 -- Match background to text color

						if inventoryTemplate then
							local templateStatus = inventoryTemplate.EquipStatus.TextLabel
							templateStatus.Text = status
							templateStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						end

						if Pass.Name == "X-Ray Vision" then
							updateEvent:FireServer(Pass.Value)
							updateOutline()
						elseif Pass.Name == "Taunt Radar" then
							radarUpdateEvent:FireServer(Pass.Value)
						elseif Pass.Name == "Speed Boost" then
							updateSpeedEvent:FireServer(Pass.Value)
							updatePassGUI("Speed Boost", speed2X)
						elseif Pass.Name == "Damage Boost" then
							updateDamageEvent:FireServer(Pass.Value)
							updatePassGUI("Damage Boost", damage2X)
						elseif Pass.Name == "Health Boost" then
							updateHealthEvent:FireServer(Pass.Value)
							updatePassGUI("Health Boost", health2X)
						elseif Pass.Name == "Freeze Props" then
							updateFreezePropsEvent:FireServer(Pass.Value)
							updateFreezeGUI()
						elseif Pass.Name == "Prop Radar" then
							updateRadarEvent:FireServer(Pass.Value)
							updateRadarGUI()
						elseif Pass.Name == "Ghost Prop" then
							updateGhostProp:FireServer(Pass.Value)
							ghostPropGUI()
						elseif Pass.Name == "Hunter Swap" then
							updateHunterSwapEvent:FireServer(Pass.Value)
							hunterSwap()
						end
					end

					if newDescriptionTemplateCashRobux:GetAttribute("Type") == "shop" then
						newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)

					elseif newDescriptionTemplateCashRobux:GetAttribute("Type") == "inventory" then
						newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)
					end

					if Pass.Name == "X-Ray Vision" then
						updateOutline()
					elseif Pass.Name == "Health Boost" then
						updatePassGUI("Health Boost", health2X)
					elseif Pass.Name == "Damage Boost" then
						updatePassGUI("Damage Boost", damage2X)
					elseif Pass.Name == "Freeze Props" then
						updateFreezeGUI()
						print("freeze props")
					elseif Pass.Name == "Prop Radar" then
						updateRadarGUI()
					elseif Pass.Name == "Ghost Prop" then
						ghostPropGUI()
					elseif Pass.Name == "Hunter Swap" then
						hunterSwap()
					elseif Pass.Name == "Speed Boost" then
						updatePassGUI("Speed Boost", speed2X)
					end
				end)


				MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassID, purchaseSuccess)
					if purchaseSuccess == true and ID == gamePassID then

						local Pass = player:WaitForChild("OwnedGamepasses"):WaitForChild(Info["Name"])
						local warning = player.PlayerGui:WaitForChild("MaxEquips")

						local equipsAfterPurchase = player:WaitForChild("Equips")

						if not player.PlayerGui.InventoryUI.Gamepasses:FindFirstChild(Info["Name"]) then
							gamePass:Clone().Parent = player.PlayerGui.InventoryUI.Gamepasses
							player:WaitForChild("GamepassesCloned").Value = true
						end


						local elementsToDestroy = {priceBar, priceBarCashDescription, cashBackground, robuxBackground, purchase, purchaseRobux}

						for _, element in ipairs(elementsToDestroy) do
							if element then
								element:Destroy()
							end
						end

						if owned and not owned.Visible then
							owned.Visible = true
						end

						if framePurchase and not framePurchase.Visible then
							framePurchase.Visible = true
						end


						if NewTemplate:WaitForChild("Prices") then
							NewTemplate.Prices:Destroy()
						end
						if NewTemplate:WaitForChild("Owned") then
							NewTemplate.Owned.Visible = true
							NewTemplate.Owned.TextLabel.Name = Info["Name"]
						end

						equipStatus.Visible = true
						purchase.Visible = false

						inventoryTemplate = inventoryList:WaitForChild(Info["Name"])

						if inventoryTemplate then
							templateStatus = inventoryTemplate.EquipStatus.TextLabel

							if Pass.Value == true then
								equipStatus.Text = "EQUIPPED"
								templateStatus.Text = "EQUIPPED"
							else
								equipStatus.Text = "UNEQUIPPED"
								templateStatus.Text = "UNEQUIPPED"
							end

							if Pass.Value == false then
								equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
								framePurchase.UIStroke.Color = equipStatus.TextColor3
								templateStatus.TextColor3 = equipStatus.TextColor3
							end

						else
							print("inventory template not found or smth")
						end


						local function toggleGamepass()

							if Pass.Value == false then -- Trying to equip
								if equipsAfterPurchase.Value > 0 and equipsAfterPurchase.Value <= 3 then
									Pass.Value = true  -- Equip the pass
								elseif equipsAfterPurchase.Value == 0 then
									if warning.Enabled == false then
										warning.Enabled = true

										MainFrame.Visible = false
										if inventoryFrame.Visible then
											inventoryFrame.Visible = false
											inventoryFrame:SetAttribute("Visible", false)
										end

										if newDescriptionTemplateCashRobux.Visible == true then
											newDescriptionTemplateCashRobux.Visible = false
										end
									end
									return nil
								end
							else -- Unequipping
								Pass.Value = false
							end

							-- Reflect current equip status
							local isEquipped = Pass.Value
							local status = isEquipped and "EQUIPPED" or "UNEQUIPPED"

							equipStatus.Text = status
							equipStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
							framePurchase.UIStroke.Color = equipStatus.TextColor3 -- Match background to text color

							if inventoryTemplate then
								local templateStatus = inventoryTemplate.EquipStatus.TextLabel
								templateStatus.Text = status
								templateStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
							end


							if Pass.Name == "X-Ray Vision" then
								updateEvent:FireServer(Pass.Value)
								updateOutline()

							elseif Pass.Name == "Taunt Radar" then
								radarUpdateEvent:FireServer(Pass.Value)

							elseif Pass.Name == "Speed Boost" then
								updateSpeedEvent:FireServer(Pass.Value)
								updatePassGUI("Speed Boost", speed2X)
							elseif Pass.Name == "Damage Boost" then
								updateDamageEvent:FireServer(Pass.Value)
								updatePassGUI("Damage Boost", damage2X)

							elseif Pass.Name == "Health Boost" then
								updateHealthEvent:FireServer(Pass.Value)
								updatePassGUI("Health Boost", health2X)

							elseif Pass.Name == "Freeze Props" then
								updateFreezePropsEvent:FireServer(Pass.Value)
								updateFreezeGUI()
							elseif Pass.Name == "Prop Radar" then
								updateRadarEvent:FireServer(Pass.Value)
								updateRadarGUI()
							elseif Pass.Name == "Ghost Prop" then
								updateGhostProp:FireServer(Pass.Value)
								ghostPropGUI()
							elseif Pass.Name == "Hunter Swap" then
								updateHunterSwapEvent:FireServer(Pass.Value)
								hunterSwap()

							end

						end

						if newDescriptionTemplateCashRobux:GetAttribute("Type") == "shop" then
							newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
								
								toggleGamepass()
							end)

						elseif newDescriptionTemplateCashRobux:GetAttribute("Type") == "inventory" then
							newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
								
								toggleGamepass()
							end)
						end


						if Pass.Name == "X-Ray Vision" then
							updateOutline()
						elseif Pass.Name == "Health Boost" then
							updatePassGUI("Health Boost", health2X)
						elseif Pass.Name == "Damage Boost" then
							updatePassGUI("Damage Boost", damage2X)
						elseif Pass.Name == "Freeze Props" then
							updateFreezeGUI()
						elseif Pass.Name == "Prop Radar" then
							updateRadarGUI()
						elseif Pass.Name == "Ghost Prop" then
							ghostPropGUI()
						elseif Pass.Name == "Hunter Swap" then
							hunterSwap()
						elseif Pass.Name == "Speed Boost" then
							updatePassGUI("Speed Boost", speed2X)
						end
					end
				end)

				local warningGUI = Player.PlayerGui:WaitForChild("MaxEquips")

				local Pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(Info["Name"])

				if not Pass then
					newDescriptionTemplateCashRobux.PriceBar.TextLabel.Text = Info["PriceInRobux"]
					newDescriptionTemplateCashRobux.PriceBarCash.TextLabel.Text = cashPrices[Info["Name"]]
				else
					local elementsToDestroy = {priceBarCash, priceBarCashDescription, priceBar, robuxBackground, cashBackground, purchase, purchaseRobux}

					for _, element in ipairs(elementsToDestroy) do
						if element then
							element:Destroy()
						end
					end

					framePurchase.Visible = true
					equipStatus.Visible = true
					purchase.Visible = false
					owned.Visible = true

					inventoryTemplate = inventoryList:FindFirstChild(Info["Name"])

					if inventoryTemplate then
						templateStatus = inventoryTemplate.EquipStatus.TextLabel

						if Pass.Value == true then
							equipStatus.Text = "EQUIPPED"
							templateStatus.Text = "EQUIPPED"

						else
							equipStatus.Text = "UNEQUIPPED"
							templateStatus.Text = "UNEQUIPPED"

						end

						if Pass.Value == false then
							equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
							framePurchase.UIStroke.Color = equipStatus.TextColor3
							templateStatus.TextColor3 = equipStatus.TextColor3
						end
					end

					local function toggleGamepass()
						if Pass.Value == false then -- Trying to equip
							if equips.Value > 0 and equips.Value <= 3 then
								Pass.Value = true  -- Equip the pass
							elseif equips.Value == 0 then
								if warningGUI.Enabled == false then
									warningGUI.Enabled = true
									MainFrame.Visible = false
									if inventoryFrame.Visible then
										inventoryFrame.Visible = false
										inventoryFrame:SetAttribute("Visible", false)
									end
									if newDescriptionTemplateCashRobux.Visible == true then
										newDescriptionTemplateCashRobux.Visible = false
									end
								end
								return nil
							end
						else -- Unequipping
							Pass.Value = false
						end

						-- Reflect current equip status
						local isEquipped = Pass.Value
						local status = isEquipped and "EQUIPPED" or "UNEQUIPPED"

						equipStatus.Text = status
						equipStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						framePurchase.UIStroke.Color = equipStatus.TextColor3 -- Match background color to text color

						if inventoryTemplate then
							local templateStatus = inventoryTemplate.EquipStatus.TextLabel
							templateStatus.Text = status
							templateStatus.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)
						end

						if Pass.Name == "X-Ray Vision" then
							updateEvent:FireServer(Pass.Value)
							updateOutline()
						elseif Pass.Name == "Taunt Radar" then
							radarUpdateEvent:FireServer(Pass.Value)
						elseif Pass.Name == "Speed Boost" then
							updateSpeedEvent:FireServer(Pass.Value)
							updatePassGUI("Speed Boost", speed2X)
						elseif Pass.Name == "Damage Boost" then
							updateDamageEvent:FireServer(Pass.Value)
							updatePassGUI("Damage Boost", damage2X)
						elseif Pass.Name == "Health Boost" then
							updateHealthEvent:FireServer(Pass.Value)
							updatePassGUI("Health Boost", health2X)
						elseif Pass.Name == "Freeze Props" then
							updateFreezePropsEvent:FireServer(Pass.Value)
							updateFreezeGUI()
						elseif Pass.Name == "Prop Radar" then
							updateRadarEvent:FireServer(Pass.Value)
							updateRadarGUI()
						elseif Pass.Name == "Ghost Prop" then
							updateGhostProp:FireServer(Pass.Value)
							ghostPropGUI()
						elseif Pass.Name == "Hunter Swap" then
							updateHunterSwapEvent:FireServer(Pass.Value)
							hunterSwap()
						end
					end
					if newDescriptionTemplateCashRobux:GetAttribute("Type") == "shop" then
						newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)

					elseif newDescriptionTemplateCashRobux:GetAttribute("Type") == "inventory" then
						newDescriptionTemplateCashRobux:WaitForChild("Owned").MouseButton1Click:Connect(function()
							
							toggleGamepass()
						end)
					end
				end

				newDescriptionTemplateCashRobux.PassName.Text = Info["Name"]
				newDescriptionTemplateCashRobux.GamePassImage.Image = "rbxassetid://" .. Info["IconImageAssetId"]
				if newDescriptionTemplateCashRobux.PassName.Text == "X-Ray Vision" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO SEE HUNTERS EVERYWHERE. EVEN THROUGH WALLS!"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Taunt Radar" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DETECT PROPS EFFORTLESSLY WHEN THEY TAUNT"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Speed Boost" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X SPEED"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Damage Boost" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DEAL 2X MORE DAMAGE MAKING IT EASIER TO KILL OPPOSING PLAYERS"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Health Boost" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X HEALTH"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Freeze Props" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO FREEZE ANY PROP WITHIN YOUR SHOCKWAVE RADIUS (3 uses per round)"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Prop Radar" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO EASILY DETECT PROPS WITHIN YOUR RADAR RADIUS (3 uses per round)"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Ghost Prop" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO BECOME INVISIBLE FOR 10 SECONDS (3 uses per round)"
				elseif newDescriptionTemplateCashRobux.PassName.Text == "Hunter Swap" then
					newDescriptionTemplateCashRobux.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS PROPS TO SWAP PLACES WITH HUNTERS THEY CLICK ON. 40 SECOND COOLDOWN BETWEEN EACH USE"
				end

				local function tweenCashPurchase()
					if frame then
						-- Set starting position (optional)
						frame.Position = UDim2.new(0.5, 0, -1, 0) 

						-- Create and play tween
						local Tween = TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0.3), { Position = UDim2.new(0.5, 0, 0.5, 0) })
						Tween:Play()
					else
						warn("Frame not found!")
					end
				end


				purchase.Activated:Connect(function()
					if Debounce == true then return end
					Debounce = true
					cashPurchaseGui.Enabled = true
					script["Bell"]:Play()
					frame.Name = Info["Name"]
					dialog.Text = "<font color='#ffffff'> Would you like to purchase </font>" .. Info["Name"] .. "<font color='#ffffff'> ? </font>"
					priceBarCashPurchasing.Text = cashPrices[Info["Name"]]
					tweenCashPurchase()
					rep.ChangeName:FireServer(Info["Name"])
					CloseUI()
					task.wait(0.65)
					Debounce = false
				end)

				local purchaseConnection

				if not purchaseConnection then
					purchaseConnection = frame.Purchase.Activated:Connect(function()
						rep.ClickedPurchase:FireServer(Info["Name"])
						purchaseConnection:Disconnect()
						purchaseConnection = nil
					end)
				end

				purchaseRobux.Activated:Connect(function()
					if Debounce == true then return end
					Debounce = true
					script["Bell"]:Play()
					MarketplaceService:PromptGamePassPurchase(Player, ID)
					CloseUI()
					task.wait(0.65)
					Debounce = false
				end)

				newDescriptionTemplateCashRobux.Parent = Player.PlayerGui.DescriptionGUI
			else
				if not existingClone.Visible then
					existingClone.Visible = true
				end
			end
		end

		-- Iterate through all children of DescriptionGUI
		for _, child in ipairs(Player.PlayerGui.DescriptionGUI:GetChildren()) do
			-- Check if the child is a Frame or has a Visible property
			if child:IsA("Frame") then
				-- Turn invisible if the name does not match the new clone's name
				if child.Name ~= Info["Name"] then
					child.Visible = false
				end
			end
		end

	end)

	NewTemplate.TextButton.MouseEnter:Connect(function()
		TweenService:Create(NewTemplate.TextButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { Size = UDim2.new(0.9, 0, .9, 0) }):Play()
		TweenService:Create(NewTemplate.TextButton.ImageLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = .6 }):Play()
		TweenService:Create(NewTemplate.background, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 1 }):Play()
	end)
	NewTemplate.TextButton.MouseLeave:Connect(function()
		TweenService:Create(NewTemplate.TextButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { Size = UDim2.new(0.95, 0, .95, 0) }):Play()
		TweenService:Create(NewTemplate.TextButton.ImageLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 1 }):Play()
		TweenService:Create(NewTemplate.background, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 0 }):Play()
	end)
	if NewTemplate.Name == "X-Ray Vision" or NewTemplate.Name == "Ghost Prop" or NewTemplate.Name == "Hunter Swap" then
		NewTemplate.Parent = MainFrame.List.Props.List
	elseif NewTemplate.Name == "Taunt Radar" or NewTemplate.Name == "Freeze Props" or NewTemplate.Name == "Prop Radar" then
		NewTemplate.Parent = MainFrame.List.Hunters.List
	elseif NewTemplate.Name == "Speed Boost" or NewTemplate.Name == "Damage Boost" or NewTemplate.Name == "Health Boost" then
		NewTemplate.Parent = MainFrame.List.Boosts.List
	end
end

for i, v in pairs(GamepassRequests:GetChildren()) do
	if v:IsA("StringValue") then
		if not tonumber(v.Value) then
			warn("Gamepass Shop: " .. v.Name .. " has an Invalid ID")
		else
			local ID = tonumber(v.Value)
			local Info = MarketplaceService:GetProductInfo(v.Value, Enum.InfoType.GamePass) or nil
			if not Info then
				warn("Gamepass Shop: " .. v.Name .. " failed to get Info.")
			else
				CreateTemplate(Info, ID)
			end
		end
	else
		warn("Gamepass Shop: " .. v.Name .. " is not a StringValue.")
	end
end


Player:GetPropertyChangedSignal("Team"):Connect(function()
	hunterSwap()
	updateRadarGUI()
	updateFreezeGUI()
end)

-- React to round state changes
rep.InRound.Changed:Connect(function()
	if rep.InRound.Value == true then
		updateOutline()
		updateFreezeGUI()
		updateRadarGUI()
		ghostPropGUI()
		hunterSwap()
		Player.CharacterAdded:Connect(function()
			updateRadarGUI()
			updateFreezeGUI()
		end)
		Player.Character:WaitForChild("Humanoid").Died:Connect(function()
			for i, plr in pairs(game.Players:GetChildren()) do
				if plr.Team == huntersTeam then
					local char = plr.Character or plr.CharacterAdded:Wait()
					local outline = char:FindFirstChild("PlayerOutline")
					if outline then
						outline.Enabled = false
					end
				end
			end
		end)
		status:GetPropertyChangedSignal("Value"):Connect(function()
			if status.Value == "DECLARING MVPS..." then
				resetAmountGUIs("Prop Radar", radarGui, radarAmountText, "RadarAmount")
				resetAmountGUIs("Freeze Props", freezeGui, freezeAmountText, "FreezeAmount")
				resetAmountGUIs("Ghost Prop", ghostGui, ghostAmountText, "GhostAmount")	
			end
		end)
	else
		resetAmountGUIs("Prop Radar", radarGui, radarAmountText, "RadarAmount")
		resetAmountGUIs("Freeze Props", freezeGui, freezeAmountText, "FreezeAmount")
		resetAmountGUIs("Ghost Prop", ghostGui, ghostAmountText, "GhostAmount")
	end
end)

