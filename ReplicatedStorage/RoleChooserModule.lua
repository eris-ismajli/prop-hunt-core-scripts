local mmSystem = {}

function mmSystem.ChooseRoles()
	local players = game:GetService("Players")
	local playersInGame = {}
	local huntersTeam = game.Teams.Hunters
	local propsTeam = game.Teams.Props

	for _, p in ipairs(players:GetPlayers()) do -- Use GetPlayers() instead of GetChildren()
		table.insert(playersInGame, p.Name)
	end

	local playerCount = #playersInGame
	if playerCount < 2 then return "Not Enough Players" end

	local function assignRole(playerName, role, team, equipWeapons)
		local player = players:FindFirstChild(playerName)
		if not player then return end

		player.Team = team
		player:WaitForChild("Role").Value = role
		player:WaitForChild("PlayingStatus").Value = "Playing"

		if not equipWeapons then
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local soundClone = game.ReplicatedStorage.TauntSound:Clone()
				soundClone.Parent = hrp
			end
		end
	end

	local hunters = {}
	local numHunters = playerCount < 4 and 1 or (playerCount < 7 and 2 or 3)

	-- Assign hunters in parallel
	for _ = 1, numHunters do
		local hunter = table.remove(playersInGame, math.random(#playersInGame))
		table.insert(hunters, hunter)
		task.spawn(assignRole, hunter, "HUNTER", huntersTeam, true) -- Assign hunters asynchronously
	end

	-- Assign props in parallel
	for _, plrName in ipairs(playersInGame) do
		task.spawn(assignRole, plrName, "PROP", propsTeam, false) -- Assign props asynchronously
	end

	-- Wait for all roles to be assigned before firing DisplayRole
	task.wait(1)

	for _, player in ipairs(players:GetPlayers()) do
		if player:FindFirstChild("PlayingStatus") and player.PlayingStatus.Value == "Playing" then
			game.ReplicatedStorage.DisplayRole:FireClient(player)
		end
	end

	return "Success"
end

return mmSystem
