local Player = game:GetService("Players").LocalPlayer
local Template = script:WaitForChild("Template")
local DescriptionTemplate = script:WaitForChild("Description")
local UI = script.Parent
local MainFrame = UI:WaitForChild("Frame")
local Button = UI:WaitForChild("Button")
local Toggle = Button:WaitForChild("outline"):WaitForChild("Toggle")
local close = UI.Frame:WaitForChild("Close")

local rep = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

local GamepassRequests = UI:WaitForChild("Gamepasses")

local propsTeam = game.Teams.Props
local huntersTeam = game.Teams.Hunters

if #GamepassRequests:GetChildren() == 0 and #Player:WaitForChild("OwnedGamepasses"):GetChildren() > 0 then
	MainFrame.backpack.Visible = true
	MainFrame.NoPasses.Visible = true
	MainFrame.NoPasses.Text = "LOADING GAMEPASSES..."
elseif #GamepassRequests:GetChildren() == 0 and #Player:WaitForChild("OwnedGamepasses"):GetChildren() == 0 then
	MainFrame.backpack.Visible = true
	MainFrame.NoPasses.Visible = true
	MainFrame.NoPasses.Text = "PURCHASED GAMEPASSES WILL SHOW UP HERE"
end


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

local shopGui = Player:WaitForChild("PlayerGui"):WaitForChild("GamepassUI", 5)
if not shopGui then
	warn("⚠️ GamepassUI failed to load after 5 seconds.")
	return
end
local shopFrame = shopGui.Frame

Toggle.Activated:Connect(function()
	if Debounce == true then return end
	Debounce = true
	script["Click"]:Play()
	if MainFrame.Visible == true then
		CloseUI()
		task.wait(0.65)
		Debounce = false
	else
		if shopFrame.Visible then
			shopFrame.Visible = false
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

		-- Variables to store event connections

		-- Function to activate the freeze ability
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


local function CreateTemplate(Info, ID)

	local existingTemplate = MainFrame.List:FindFirstChild(Info["Name"])
	if existingTemplate then
		warn("Template already exists for:", Info["Name"])
		return
	end

	local NewTemplate = Template:Clone() 
	if not NewTemplate then
		warn("Failed to clone template for:", Info["Name"])
		return
	end


	NewTemplate.Name = Info["Name"]
	NewTemplate.TextLabel.Text = Info["Name"]
	NewTemplate.GamePassImage.Image = "rbxassetid://" .. Info["IconImageAssetId"]


	local gamePass = Player.PlayerGui.InventoryUI.Gamepasses:WaitForChild(Info["Name"])
	if not gamePass then
		warn("GamePass object not found for:", Info["Name"])
		return
	end


	close.Activated:Connect(function()
		if Debounce then return end
		Debounce = true
		CloseUI()
		task.wait(0.35)
		Debounce = false
	end)


	local Pass = Player:WaitForChild("OwnedGamepasses"):FindFirstChild(Info["Name"])

	if MainFrame.NoPasses.Visible then
		MainFrame.backpack.Visible = false
		MainFrame.NoPasses.Visible = false
	end

	NewTemplate.TextButton.Activated:Connect(function()

		local existingClone = Player.PlayerGui.DescriptionGUI:FindFirstChild(Info["Name"])
		local newDescriptionTemplate


		if not existingClone then
			newDescriptionTemplate = DescriptionTemplate:Clone()
			newDescriptionTemplate.Name = Info["Name"]
			newDescriptionTemplate:SetAttribute("Type", "inventory")
			local equipStatus = newDescriptionTemplate:WaitForChild("EquipStatus")
			local framePurchase = newDescriptionTemplate:WaitForChild("BackgroundStatus")
			local owned = newDescriptionTemplate:WaitForChild("Owned")


			if Pass then
				if Pass.Value == true then
					equipStatus.Text = "EQUIPPED"
				else
					equipStatus.Text = "UNEQUIPPED"
				end

				if not framePurchase.Visible then
					framePurchase.Visible = true
				end

				if Pass.Value == false then
					equipStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
					framePurchase.UIStroke.Color = equipStatus.TextColor3
				end

				local function toggleGamepass()
					local warningGUI = Player.PlayerGui:WaitForChild("MaxEquips")
					local equips = Player:WaitForChild("Equips")

					-- Check if the player is trying to equip or unequip
					if Pass.Value == false then -- Trying to equip
						if equips.Value > 0 and equips.Value <= 3 then
							Pass.Value = true  -- Equip the pass
						elseif equips.Value == 0 then
							if warningGUI.Enabled == false then
								warningGUI.Enabled = true

								MainFrame.Visible = false

								if newDescriptionTemplate.Visible == true then
									newDescriptionTemplate.Visible = false
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

					NewTemplate.EquipStatus.TextLabel.Text = status
					NewTemplate.EquipStatus.TextLabel.TextColor3 = isEquipped and Color3.fromRGB(170, 255, 0) or Color3.fromRGB(255, 0, 0)

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

				if newDescriptionTemplate:GetAttribute("Type") == "shop" then
					newDescriptionTemplate:WaitForChild("Owned").MouseButton1Click:Connect(function()
						toggleGamepass()
					end)

				elseif newDescriptionTemplate:GetAttribute("Type") == "inventory" then
					newDescriptionTemplate:WaitForChild("Owned").MouseButton1Click:Connect(function()
						toggleGamepass()
					end)
				end

			end

			newDescriptionTemplate.PassName.Text = Info["Name"]
			newDescriptionTemplate.GamePassImage.Image = "rbxassetid://" .. Info["IconImageAssetId"]
			if newDescriptionTemplate.PassName.Text == "X-Ray Vision" then
				newDescriptionTemplate.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO SEE HUNTERS EVERYWHERE. EVEN THROUGH WALLS!"
			elseif newDescriptionTemplate.PassName.Text == "Taunt Radar" then
				newDescriptionTemplate.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DETECT PROPS EFFORTLESSLY WHEN THEY TAUNT"
			elseif newDescriptionTemplate.PassName.Text == "Speed Boost" then
				newDescriptionTemplate.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X SPEED"
			elseif newDescriptionTemplate.PassName.Text == "Damage Boost" then
				newDescriptionTemplate.describe.Text = "WHEN EQUIPPED, THIS ITEM ALLOWS YOU TO DEAL 2X MORE DAMAGE MAKING IT EASIER TO KILL OPPOSING PLAYERS"
			elseif newDescriptionTemplate.PassName.Text == "Health Boost" then
				newDescriptionTemplate.describe.Text = "WHEN EQUIPPED, THIS ITEM GIVES YOU 2X HEALTH"
			elseif newDescriptionTemplate.PassName.Text == "Freeze Props" then
				newDescriptionTemplate.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO FREEZE ANY PROP WITHIN YOUR SHOCKWAVE RADIUS (3 uses per round)"
			elseif newDescriptionTemplate.PassName.Text == "Prop Radar" then
				newDescriptionTemplate.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO EASILY DETECT PROPS WITHIN YOUR RADAR RADIUS (3 uses per round)"
			elseif newDescriptionTemplate.PassName.Text == "Ghost Prop" then
				newDescriptionTemplate.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS YOU TO BECOME INVISIBLE FOR 10 SECONDS (3 uses per round)"
			elseif newDescriptionTemplate.PassName.Text == "Hunter Swap" then
				newDescriptionTemplate.describe.Text = "WHEN ACTIVATED, THIS ITEM ALLOWS PROPS TO SWAP PLACES WITH HUNTERS THEY CLICK ON. 40 SECOND COOLDOWN BETWEEN EACH USE"
			end

			newDescriptionTemplate.Parent = Player.PlayerGui.DescriptionGUI
		else
			if not existingClone.Visible then
				existingClone.Visible = true
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
		TweenService:Create(NewTemplate.TextButton.ImageLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = .8 }):Play()
		TweenService:Create(NewTemplate.background, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 1 }):Play()
	end)
	NewTemplate.TextButton.MouseLeave:Connect(function()
		TweenService:Create(NewTemplate.TextButton, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { Size = UDim2.new(0.95, 0, .95, 0) }):Play()
		TweenService:Create(NewTemplate.TextButton.ImageLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 1 }):Play()
		TweenService:Create(NewTemplate.background, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0), { ImageTransparency = 0 }):Play()
	end)

	NewTemplate.Parent = MainFrame.List
end

Player:WaitForChild("GamepassesCloned"):GetPropertyChangedSignal("Value"):Connect(function()
	if Player:WaitForChild("GamepassesCloned").Value == true then
		for i, v in pairs(GamepassRequests:GetChildren()) do
			if not MainFrame.List:FindFirstChild(v.Name) then
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
		end	
		Player:WaitForChild("GamepassesCloned").Value = false

	end

end)

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

rep.Status:GetPropertyChangedSignal("Value"):Connect(function()
	if rep.Status.Value == "DECLARING MVPS..." then
		resetAmountGUIs("Prop Radar", radarGui, radarAmountText, "RadarAmount")
		resetAmountGUIs("Freeze Props", freezeGui, freezeAmountText, "FreezeAmount")
		resetAmountGUIs("Ghost Prop", ghostGui, ghostAmountText, "GhostAmount")	
	end
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
