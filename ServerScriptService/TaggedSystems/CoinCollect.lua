local inRound = game.ReplicatedStorage.InRound
local plrs = game:GetService("Players")

local rep = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local propsTeam = game.Teams.Props

rep.InRound.Changed:Connect(function()
	if rep.InRound.Value == true then
		-- Get the current map
		local map = game.Workspace.Maps:FindFirstChildOfClass("Model")
		if not map then
			warn("No map found!")
			return
		end

		-- Iterate through tagged parts and ensure they belong to the map
		for _, part in CollectionService:GetTagged("CollectScript") do
			if part:IsDescendantOf(map) then -- Ensure the part is within the selected map
				local db = true
				part.Touched:Connect(function(hit)
					-- Check if hit.Parent is a valid character
					if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
						local plr = plrs:GetPlayerFromCharacter(hit.Parent)

						-- Check if plr is valid and has a team
						if plr and plr.Team == propsTeam then
							if db then
								db = false

								part.Transparency = 1

								-- Ensure CoinStatus exists
								local coinStatus = plr:FindFirstChild("CoinStatus")
								if coinStatus then
									coinStatus.Value += 5
								end

								-- Play sound if present
								if part:FindFirstChild("Sound") then
									part.Sound:Play()
								end

								-- Reset after a delay
								task.delay(30, function()
									db = true
									part.Transparency = 0
								end)
							end
						end
					end
				end)
			end
		end
	else
		return nil
	end
end)
