-------------------------------------[AUTHOR: reccur]--------------------------------
local rep = game:GetService("ReplicatedStorage")

local huntersTeam = game.Teams.Hunters
local propsTeam = game.Teams.Props
local lobbyTeam = game.Teams.Lobby

local status = rep.Status

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

local murderMysteryModule = require(game.ReplicatedStorage.MurderMysterySystem)
local decrementLevelModule = require(ServerScriptService.DecrementLevelModule)

local roundEnded = rep.RoundEnded

local clickTauntConnection
local tauntConnection

-- Setup ClickTaunt event handler
local function onClickTaunt(player)
	if not player or not player.Character then return end
	local humRoot = player.Character:FindFirstChild("HumanoidRootPart")
	if humRoot then
		humRoot.TauntSound:Play()
		player.Character.Humanoid.Jump = true
		local coinStatus = player:FindFirstChild("CoinStatus")
		if coinStatus then
			coinStatus.Value = coinStatus.Value + 10
		end

		if player.Team == propsTeam then
			for _, hunter in ipairs(game.Teams.Hunters:GetPlayers()) do
				if hunter then
					local originOfDamage = player.Character.HumanoidRootPart.Position
					rep:WaitForChild("DamageIndicatorReplicatedStorage"):WaitForChild("DamageEvent"):FireClient(hunter, originOfDamage)
					rep:WaitForChild("DisplayRadarEvent"):FireClient(hunter, player)
				end
			end
		end

	end
end

local function onTaunt(player)
	if not player or not player.Character then return end
	local humRoot = player.Character:FindFirstChild("HumanoidRootPart")
	if humRoot and humRoot.TauntSound then
		humRoot.TauntSound:Play()
		player.Character.Humanoid.Jump = true

		if player.Team == propsTeam then
			for _, hunter in ipairs(game.Teams.Hunters:GetPlayers()) do
				if hunter then
					local originOfDamage = player.Character.HumanoidRootPart.Position
					rep:WaitForChild("DamageIndicatorReplicatedStorage"):WaitForChild("DamageEvent"):FireClient(hunter, originOfDamage)

					-- Fix: Now sending the 'prop' (player) to the client
					rep:WaitForChild("DisplayRadarEvent"):FireClient(hunter, player)
				end
			end
		end
	end
end



local function hunterSwap(player, playerHRP, hoveredPlayerHRP)
	if player and player.Team == propsTeam and playerHRP and hoveredPlayerHRP then
		-- Clone VFX and sound objects
		local vfxClone = rep.TeleportVFX:Clone()
		local teleportSoundClone = rep.Teleporter:Clone()
		local chargeSoundClone = rep.charging:Clone()

		-- Ensure player and hovered player HRPs are valid
		playerHRP = player.Character:FindFirstChild("HumanoidRootPart")
		local hoveredPlayer = game.Players:GetPlayerFromCharacter(hoveredPlayerHRP.Parent)
		hoveredPlayerHRP = hoveredPlayer.Character:FindFirstChild("HumanoidRootPart")

		-- Check if both HRPs exist
		if playerHRP and hoveredPlayerHRP then
			-- Parent the VFX and sounds only if they haven't been parented already
			local vfxClone2 = vfxClone:Clone()  -- Create another clone for the second player
			local chargeSoundClone2 = chargeSoundClone:Clone()

			if not playerHRP:FindFirstChild("Teleporter") then
				teleportSoundClone.Parent = playerHRP
			end

			if not playerHRP:FindFirstChild("charging") then
				chargeSoundClone.Parent = playerHRP
			end

			if not hoveredPlayerHRP:FindFirstChild("charging") then
				chargeSoundClone2.Parent = hoveredPlayerHRP
			end

			if not playerHRP:FindFirstChild("Main") then
				vfxClone.Parent = playerHRP
			end

			if not hoveredPlayerHRP:FindFirstChild("Main") then
				vfxClone2.Parent = hoveredPlayerHRP
			end

			-- Function to enable VFX for both players and play sounds
			local function enableVFXplayer()
				-- Enable VFX and play the sound for both players at once
				local playerChargingSound = playerHRP:FindFirstChild("charging")
				local hoveredPlayerChargingSound = hoveredPlayerHRP:FindFirstChild("charging")

				-- Play charging sound for both players if available
				if playerChargingSound then
					playerChargingSound:Play()
				end
				if hoveredPlayerChargingSound then
					hoveredPlayerChargingSound:Play()
				end

				playerHRP:FindFirstChild("TeleportVFX").Enabled = true

				hoveredPlayerHRP:FindFirstChild("TeleportVFX").Enabled = true

				-- Wait for the effects to last
				task.wait(1)

				-- Disable VFX for both players
				playerHRP:FindFirstChild("TeleportVFX").Enabled = false

				hoveredPlayerHRP:FindFirstChild("TeleportVFX").Enabled = false
			end


			-- Perform the position swap
			local playerHRPCframe = playerHRP.CFrame
			local hoveredPlayerHRPCframe = hoveredPlayerHRP.CFrame

			-- Enable VFX, play sounds, and perform the swap after a delay
			enableVFXplayer()
			playerHRP:FindFirstChild("Teleporter"):Play()
			playerHRP.CFrame = hoveredPlayerHRPCframe
			hoveredPlayerHRP.CFrame = playerHRPCframe
		end
	end
end

local shockwaveRadius = 118 -- Radius of the shockwave


local function freezeProps(player)


	if not player or not player.Character then
		print("Player or player character doesn't exist")    
		return
	end

	if player.Team == huntersTeam then
		local freezeAmount = player:FindFirstChild("FreezeAmount")
		if not freezeAmount then
			print("FreezeAmount not found for player:", player.Name)
			return
		end

		local function tweenRunTransparency(targetTransparency, plr)
			local playerGui = plr:FindFirstChild("PlayerGui")
			if playerGui then
				local freezeGui = playerGui:FindFirstChild("Freeze")
				if freezeGui then
					local noProps = freezeGui:FindFirstChild("NoProps")
					if noProps then
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
						local tweenGoal = { ImageTransparency = targetTransparency }
						local tween = TweenService:Create(noProps, tweenInfo, tweenGoal)
						tween:Play()
					end
				end
			end
		end

		-- Show and hide GUI for the player
		local function showAndHideGUI(plr)
			local freezeGui = plr.PlayerGui:FindFirstChild("Freeze")
			local noProps = freezeGui:FindFirstChild("NoProps")
			local errorSound = noProps:FindFirstChild("Error")
			errorSound:Play()
			tweenRunTransparency(0, plr)
			task.wait(3)
			tweenRunTransparency(1, plr)
		end

		if freezeAmount.Value > 0 then
			local oldAmount = freezeAmount.Value

			-- Clone and set up shockwave
			local shockWaveClone = rep.Shockwave:Clone()
			local hunterRoot = player.Character:WaitForChild("HumanoidRootPart")
			shockWaveClone.Parent = game.Workspace
			shockWaveClone.CFrame = hunterRoot.CFrame

			local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local goal = {Size = Vector3.new(286.661, 143.33, 286.661)}
			local tween = TweenService:Create(shockWaveClone, tweenInfo, goal)

			player:WaitForChild("FreezeDebounce").Value = false

			freezeAmount.Value -= 1

			tween:Play()

			-- Play shockwave sound
			game.Workspace.shockSound:Play()

			-- Detect collision with props
			tween.Completed:Connect(function()
				for _, prop in ipairs(game.Teams.Props:GetPlayers()) do
					if prop and prop.Character and prop.Character:FindFirstChild("HumanoidRootPart") then
						local propRoot = prop.Character:WaitForChild("HumanoidRootPart")
						local distance = (hunterRoot.Position - propRoot.Position).Magnitude
						if distance <= shockwaveRadius then
							local frozenClone = rep.Frozen:Clone()
							prop:WaitForChild("DisableClicking").Value = true
							prop.Character:WaitForChild("Humanoid").WalkSpeed = 0
							prop.PlayerGui.Stamina.SprintHandler.Enabled = false
							frozenClone.Parent = prop.Character

							prop.Character:WaitForChild("Humanoid").Died:Connect(function()
								if freezeAmount.Value == oldAmount then
									freezeAmount.Value -= 1
								end
								shockWaveClone:Destroy()
							end)

							-- Wait and then unfreeze
							task.wait(4)
							if prop.Character:FindFirstChild("Frozen") then
								prop.Character.Frozen:Destroy()
							end
							prop:WaitForChild("DisableClicking").Value = false
							prop.Character:WaitForChild("Humanoid").WalkSpeed = 24
							prop.PlayerGui.Stamina.SprintHandler.Enabled = true
						else
							showAndHideGUI(player)
						end
					end
				end
				shockWaveClone:Destroy()
				player:WaitForChild("FreezeDebounce").Value = true
			end)
		end
	end

end

local freezePropsConnection
local hunterSwapConnection


if rep.InRound.Value == true then
	if not clickTauntConnection then
		clickTauntConnection = rep.ClickTaunt.OnServerEvent:Connect(onClickTaunt)	
	end	

	if not tauntConnection then
		tauntConnection = rep.Taunt.OnServerEvent:Connect(onTaunt)
	end

	if not freezePropsConnection then
		freezePropsConnection = rep.FreezeProps.OnServerEvent:Connect(freezeProps)
	end

	if not hunterSwapConnection then
		hunterSwapConnection = rep.HunterSwap.OnServerEvent:Connect(hunterSwap)
	end
else

	if tauntConnection then
		tauntConnection:Disconnect()
		tauntConnection = nil
	end

	if clickTauntConnection then
		clickTauntConnection:Disconnect()
		clickTauntConnection = nil
	end

	if freezePropsConnection then
		freezePropsConnection:Disconnect()
		freezePropsConnection = nil
	end

	if hunterSwapConnection then
		hunterSwapConnection:Disconnect()
		hunterSwapConnection = nil
	end
end

local function setupProp(plr)
	local character = plr.Character

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local rightFoot = character:WaitForChild("RightFoot")
	local leftFoot = character:WaitForChild("LeftFoot")

	-- Clone and parent only if necessary
	local function cloneIfAbsent(parent, childName, source)
		if not parent:FindFirstChild(childName) then
			local clone = source:Clone()
			clone.Parent = parent
		end
	end

	-- Add assets

	cloneIfAbsent(humanoidRootPart, "TauntSound", rep.TauntSound)
	cloneIfAbsent(humanoidRootPart, "Bubble", rep.Bubble)
	cloneIfAbsent(humanoidRootPart, "Cloud", rep.CloudTool.Handle.Cloud)
	cloneIfAbsent(humanoidRootPart, "Cloud1", rep.CloudTool.Handle.Cloud1)
	cloneIfAbsent(humanoidRootPart, "Attachment", rep.VFX.Attachment)
	cloneIfAbsent(character, "Rotate", game.StarterPlayer.StarterCharacterScripts.Rotate)
	cloneIfAbsent(character, "IsOutside", game.StarterPlayer.StarterCharacterScripts.IsOutside)
	-- Clone and enable Rotate script
	if not plr.Character.Rotate.Enabled then
		plr.Character.Rotate.Enabled = true
	end	

	if plr:WaitForChild("Tool").Value ~= "" then
		local toolNames = string.split(plr.Tool.Value, ",")
		for _, toolName in ipairs(toolNames) do
			local tool = rep:FindFirstChild(toolName)
			if tool then
				local toolClone = plr.Backpack:FindFirstChild(toolName)
				if not toolClone then
					toolClone = tool:Clone()
					toolClone.Parent = plr.Backpack
				end
			end
		end
	end

	if plr:WaitForChild("EnergyDrink").Value == true then
		plr.Character:WaitForChild("Humanoid").WalkSpeed = 37
		plr.PlayerGui.Stamina.SprintHandler.Enabled = false
	else
		plr.Character:WaitForChild("Humanoid").WalkSpeed = 24
		plr.PlayerGui.Stamina.SprintHandler.Enabled = true
	end

	plr:WaitForChild("EnergyDrink"):GetPropertyChangedSignal("Value"):Connect(function()
		if plr:WaitForChild("EnergyDrink").Value == false then
			plr.Character:WaitForChild("Humanoid").WalkSpeed = 24
			plr.PlayerGui.Stamina.SprintHandler.Enabled = true
		end
	end)
end

local function setupHunter(plr, RedSpawns)
	if plr.Character then
		if plr.Team == huntersTeam then

			plr.PlayerGui.Taunt.Enabled = false
			plr.PlayerGui.Taunt.Frame.Timer.TimerScript.Enabled = false
			plr.PlayerGui.RotateGui.Enabled = false
			plr.PlayerGui.Coin.Enabled = false

			plr.Character.Rotate.Enabled = false

			plr.PlayerGui.StepCounter.steps.Visible = false


			local character = plr.Character or plr.CharacterAdded:Wait()

			local rootPart = character:WaitForChild("HumanoidRootPart")

			character:SetPrimaryPartCFrame(RedSpawns[math.random(1, #RedSpawns)].CFrame)

			if roundEnded.Value == false then
				local hum = character:FindFirstChildOfClass("Humanoid")
				if not plr.Backpack:FindFirstChild("SMG") then
					local gunClone = rep.SMG:Clone()
					gunClone.Parent = plr.Backpack
					hum:EquipTool(gunClone)
				end

				if not plr.Backpack:FindFirstChild("EnergyDrink") then
					local sodaClone = rep.EnergyDrink:Clone()
					sodaClone.Parent = plr.Backpack
				end
				plr.PlayerGui.PlayerCounter.Enabled = true	
			end

		end
	end
end

local function enableAttachments(plr)
	if plr.Team ~= lobbyTeam then

		local attachments = plr.Character:WaitForChild("HumanoidRootPart").Attachment

		for _, attachment in pairs(attachments:GetChildren()) do
			attachment.Enabled = true
		end
		task.wait(3)
		for _, attachment in pairs(attachments:GetChildren()) do
			attachment.Enabled = false
		end
	end
end

local function changeTeamHunter(plr)
	if rep.InRound.Value == true then
		if plr.Team == huntersTeam then
			task.wait(2)
			plr.Team = huntersTeam
			plr:WaitForChild("Role").Value = "HUNTER"
		end
	end
end

local function changeTeamProp(plr)
	if plr.Team == propsTeam then
		local propsPlayers = propsTeam:GetPlayers()
		if #propsPlayers == 1 then
			task.wait(2)
			plr.Team = huntersTeam
			plr:WaitForChild("Role").Value = "PROP"
		else
			task.wait(2)
			plr.Team = huntersTeam
			plr:WaitForChild("Role").Value = "HUNTER"
		end
	end	
end
--teleport
rep.InRound.Changed:Connect(function()

	if rep.InRound.Value == true then

		if not clickTauntConnection then
			clickTauntConnection = rep.ClickTaunt.OnServerEvent:Connect(onClickTaunt)	
		end	

		if not tauntConnection then
			tauntConnection = rep.Taunt.OnServerEvent:Connect(onTaunt)
		end

		if not freezePropsConnection then
			freezePropsConnection = rep.FreezeProps.OnServerEvent:Connect(freezeProps)
		end

		if not hunterSwapConnection then
			hunterSwapConnection = rep.HunterSwap.OnServerEvent:Connect(hunterSwap)
		end

		local mapClone = game.Workspace.Maps:FindFirstChildOfClass("Model")

		if game.ReplicatedStorage.Modes["Blue Zone"].Value == true then
			game.Workspace.forcefield.Transparency = 0

		elseif game.ReplicatedStorage.Modes.Classic.Value == true then
			game.Workspace.forcefield.Transparency = 1
		end
		--- getting the map from the replicated storgae to the workspace


		if mapClone then
			local mapName = mapClone.Name
			local map = game.Workspace.Maps[mapName]

			local models = map["Morphs" .. mapName].random:GetChildren()
			local model = models[math.random(1, #models)]

			if mapName == "Cubana" then
				game.Workspace.forcefield.Position = Vector3.new(-170.547, 98.893, -518.31)
			elseif mapName == "Favela" then
				game.Workspace.forcefield.Position = Vector3.new(-699.785, 98.893, -620.31)
			else
				game.Workspace.forcefield.Position = Vector3.new(-312.785, 98.893, -993.31)
			end

			local msg = murderMysteryModule.ChooseRoles()
			task.wait(1)

			for _, plr in pairs(game.Players:GetChildren()) do
				task.spawn(function() -- Run in parallel

					local char = plr.Character or plr.CharacterAdded:Wait()
					local humanRoot = char:WaitForChild("HumanoidRootPart", 3) -- Wait max 3 seconds for it to load

					if not humanRoot then
						warn("Failed to get HumanoidRootPart for " .. plr.Name)
						return
					end

					local RedSpawns = mapClone.RedSpawns:GetChildren()
					local BlueSpawns = mapClone.BlueSpawns:GetChildren()

					local function morphProp()
						local oldCharacter = plr.Character
						local morphModel = model:FindFirstChildOfClass("Model")
						local newCharacter = morphModel:Clone()

						newCharacter.Name = model.Name
						newCharacter.HumanoidRootPart.Anchored = false
						newCharacter:SetPrimaryPartCFrame(oldCharacter.PrimaryPart.CFrame)

						plr.Character = newCharacter
						plr.Character.ForceField:Destroy()
						plr.Character.Mail.Handle.ProximityPrompt:Destroy()

						plr.PlayerGui.PlayerCounter.Enabled = true
						setupProp(plr)
						newCharacter.Parent = workspace
					end

					-- Handle Blue Zone Mode
					local function updateBlueZone()
						local inBlueZone = game.ReplicatedStorage.Modes["Blue Zone"].Value
						local outsideStorm = plr:WaitForChild("PlayerGui"):WaitForChild("OutsideStorm", 5)
						if not outsideStorm then
							warn("⚠️ outsideStorm failed to load after 5 seconds.")
							return
						end
						outsideStorm.Enabled = inBlueZone
					end

					updateBlueZone()
					game.ReplicatedStorage.Modes["Blue Zone"].Changed:Connect(updateBlueZone)

					-- **HUNTER PROCESSING**
					if plr.Team == huntersTeam then

						if #RedSpawns == 0 then
							warn("No RedSpawns found!")
							return
						end

						local chosenSpawn = RedSpawns[math.random(1, #RedSpawns)]
						if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
							plr.Character:SetPrimaryPartCFrame(chosenSpawn.CFrame)
						else
							warn(plr.Name .. " failed teleport: No HumanoidRootPart!")
							return
						end

						-- Equip weapons
						for _, tool in ipairs({"SMG", "EnergyDrink"}) do
							local clone = game.ReplicatedStorage[tool]:Clone()
							clone.Parent = plr.Backpack
						end

						-- Auto-equip SMG
						local hum = plr.Character:FindFirstChild("Humanoid")
						if hum then
							hum:EquipTool(plr.Backpack:FindFirstChild("SMG"))
						end

						-- Handle respawn events
						local function onCharacterAdded(character)
							RunService.Stepped:Wait()
							local humanoid = character:WaitForChild("Humanoid")
							setupHunter(plr, RedSpawns)

							humanoid.Died:Connect(function()
								task.spawn(function() enableAttachments(plr) end)
								task.spawn(function() changeTeamHunter(plr) end)
							end)
						end

						plr.CharacterAdded:Connect(onCharacterAdded)
						if plr.Character then
							onCharacterAdded(plr.Character)
						end

						-- **PROP PROCESSING**
					elseif plr.Team == propsTeam then

						if #BlueSpawns == 0 then
							warn("No BlueSpawns found!")
							return
						end

						local chosenSpawn = BlueSpawns[math.random(1, #BlueSpawns)]
						if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
							plr.Character:SetPrimaryPartCFrame(chosenSpawn.CFrame)
						else
							warn(plr.Name .. " failed teleport: No HumanoidRootPart!")
							return
						end

						plr.PlayerGui.Taunt.Enabled = true
						plr.PlayerGui.Taunt.Frame.Timer.TimerScript.Enabled = true
						plr.PlayerGui.RotateGui.Enabled = true
						plr.PlayerGui.Coin.Enabled = true
						plr.Character.Rotate.Enabled = true
						plr.PlayerGui.StepCounter.steps.Visible = true

						plr:WaitForChild("CoinStatus").Value = 0

						local function onCharacterAdded(character)
							task.spawn(function()
								RunService.Stepped:Wait() -- Avoids blocking execution
								if plr.Team == huntersTeam then
									setupHunter(plr, RedSpawns)
								elseif plr.Team == propsTeam then
									setupProp(plr)

									local humanoid = character:FindFirstChild("Humanoid")
									local rootPart = character:FindFirstChild("HumanoidRootPart")

									if humanoid and rootPart then
										rootPart.Bubble:Play()
										rootPart.Cloud.Enabled = true
										rootPart.Cloud1.Enabled = true
										task.wait(0.3)
										rootPart.Cloud.Enabled = false
										rootPart.Cloud1.Enabled = false

										humanoid.Died:Connect(function()
											task.spawn(enableAttachments, plr)
											task.spawn(changeTeamProp, plr)
										end)
									end
								end
							end)
						end

						plr.CharacterAdded:Connect(onCharacterAdded)

						if plr.Character then
							onCharacterAdded(plr.Character)
						end


						plr.CharacterAdded:Connect(onCharacterAdded)
						if plr.Character then
							onCharacterAdded(plr.Character)
						end

						task.wait()

						morphProp()
					end
				end)
			end

		end

	else

		local decoys = game.Workspace.Decoys

		if #decoys:GetChildren() > 0 then
			for i, decoy in pairs(decoys:GetChildren()) do
				decoy:Destroy()
				task.wait(1)
			end
		end


		if tauntConnection then
			tauntConnection:Disconnect()
			tauntConnection = nil
		end

		if clickTauntConnection then
			clickTauntConnection:Disconnect()
			clickTauntConnection = nil
		end

		if freezePropsConnection then
			freezePropsConnection:Disconnect()
			freezePropsConnection = nil
		end

		if hunterSwapConnection then
			hunterSwapConnection:Disconnect()
			hunterSwapConnection = nil
		end


	end

end)

local connectedPlayers = {}

local function onPlayerAdded(player)
	if connectedPlayers[player] then return end
	connectedPlayers[player] = true

	local mapClone = game.Workspace.Maps:FindFirstChildOfClass("Model")
	if not mapClone then return end

	local RedSpawns = mapClone.RedSpawns:GetChildren()

	player.CharacterAdded:Connect(function()
		RunService.Stepped:Wait()
		local humanoid = player.Character:WaitForChild("Humanoid")

		setupHunter(player, RedSpawns)

		humanoid.Died:Connect(function()
			task.spawn(enableAttachments, player)
			task.spawn(changeTeamHunter, player)
		end)
	end)

	if player.Character then
		local humanoid = player.Character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.spawn(enableAttachments, player)
			task.spawn(changeTeamHunter, player)
		end)
	end

	local teleportConnection
	if not teleportConnection then
		teleportConnection = rep.TeleportToRound.OnServerEvent:Connect(function(plr)
			if plr == player then
				if not plr.Character then return end

				local mapClone = game.Workspace.Maps:FindFirstChildOfClass("Model")
				if not mapClone then return end

				local RedSpawns = mapClone.RedSpawns:GetChildren()
				local hum = plr.Character:FindFirstChild("Humanoid")

				local gunClone = game.ReplicatedStorage.SMG:Clone()
				local sodaClone = game.ReplicatedStorage.EnergyDrink:Clone()

				plr.Team = huntersTeam
				plr:WaitForChild("Role").Value = "HUNTER"
				plr.Character:SetPrimaryPartCFrame(RedSpawns[math.random(1, #RedSpawns)].CFrame)


				local inBlueZone = game.ReplicatedStorage.Modes["Blue Zone"].Value
				plr.PlayerGui.OutsideStorm.Enabled = inBlueZone

				plr.PlayerGui.PlayerCounter.Enabled = true

				gunClone.Parent = plr.Backpack
				sodaClone.Parent = plr.Backpack

				if hum then hum:EquipTool(gunClone) end

				if teleportConnection then
					teleportConnection:Disconnect()
					teleportConnection = nil
				end
			end
		end)
	end
end

game.Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")

		hum.Died:Connect(function()
			decrementLevelModule.FireDecrementLevel(plr)
		end)
	end)
	onPlayerAdded(plr)
end)
