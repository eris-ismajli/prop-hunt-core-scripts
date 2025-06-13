-- Listen for the button click in the player's GUI to clone the character
local propsTeam = game.Teams.Props

local debounce = true

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Assuming there is a button in the player's GUI named "CloneButton"
		local cloneButton = player.PlayerGui:WaitForChild("RotateGui").Decoy

		-- When the player clicks the button
		cloneButton.MouseButton1Click:Connect(function()
			if debounce == true then
				if player:WaitForChild("CloneCounter").Value > 0 then
					if player.Team == propsTeam then
						-- Clone the player's current character and set its position
						local oldCharacter = player.Character
						local clonedCharacter = oldCharacter:Clone()
						clonedCharacter.Name = "Decoy"
						clonedCharacter.HumanoidRootPart.Anchored = false
						clonedCharacter:SetPrimaryPartCFrame(oldCharacter.PrimaryPart.CFrame)
						
						for i, highlight in pairs(clonedCharacter:GetChildren()) do
							if highlight:IsA("Highlight") then
								highlight:Destroy()
							end
						end

						-- Parent the cloned character to the workspace
						clonedCharacter.Parent = workspace.Decoys
						player:WaitForChild("CloneCounter").Value -= 1

						debounce = false
						task.wait(1)
						debounce = true
					end
				end
			end
		end)
	end)
end)
