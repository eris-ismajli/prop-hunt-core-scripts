local propsTeam = game.Teams.Props
local CollectionService = game:GetService("CollectionService")
local playerDebounce = {}  -- Holds debounce state per player

-- Listen for changes in the round state
game.ReplicatedStorage.InRound.Changed:Connect(function()
	if game.ReplicatedStorage.InRound.Value == true then
		-- Get the active map
		local map = game.Workspace.Maps:FindFirstChildOfClass("Model")
		if not map then
			warn("No map found!")
			return
		end

		-- For each model tagged "MorphScript", ensure it's within the map
		for _, model in CollectionService:GetTagged("MorphScript") do
			if model:IsDescendantOf(map) then
				local proximity = model:FindFirstChild("Noob") and model.Noob.Mail.Handle:FindFirstChild("ProximityPrompt")
				if proximity then
					proximity.Triggered:Connect(function(player)
						if player.Character:WaitForChild("Humanoid").Health > 5 then
							-- Check debounce for this player
							if not playerDebounce[player] then
								if player.Team == propsTeam and player:WaitForChild("DisableClicking").Value == false then
									local oldCharacter = player.Character
									local morphModel = model:FindFirstChildOfClass("Model")
									if morphModel then
										local newCharacter = morphModel:Clone()
										newCharacter:FindFirstChild("ForceField"):Destroy()
										newCharacter.Name = model.Name
										newCharacter.HumanoidRootPart.Anchored = false
										newCharacter:SetPrimaryPartCFrame(oldCharacter.PrimaryPart.CFrame)

										player.Character = newCharacter
										player.Character.Mail.Handle.ProximityPrompt:Destroy()

										newCharacter.Parent = workspace
										newCharacter.Humanoid.Health = oldCharacter.Humanoid.Health
										if oldCharacter.Humanoid.Health == oldCharacter.Humanoid.MaxHealth then
											newCharacter.Humanoid.Health = newCharacter.Humanoid.MaxHealth
										end

										-- Set player debounce
										playerDebounce[player] = true
										task.delay(1, function()
											playerDebounce[player] = nil
										end)
									else
										warn("No morph model found in:", model.Name)
									end
								end
							end
						end
					end)
				end
			end
		end
	end    
end)
