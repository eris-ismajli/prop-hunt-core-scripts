local intermission = 18
local modeVoting = 20
local huntersWillRelease = 30
local roundLength = 240

local rep = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local inRound = rep.InRound

local lobbyTeam = game.Teams.Lobby
local propsTeam = game.Teams.Props
local huntersTeam = game.Teams.Hunters

local decrementLevelModule = require(ServerScriptService.DecrementLevelModule)

local TweenService = game:GetService("TweenService")

local roundEnded = rep.RoundEnded

local winners = rep.Winners

local RunService = game:GetService("RunService")

local votingStatus = rep.VotingStatus

local function resetPassAmount(plr)
	local passAmounts = {"FreezeAmount", "RadarAmount", "GhostAmount"}

	for _, passAmount in ipairs(passAmounts) do
		local amount = plr:FindFirstChild(passAmount)

		local textAmount = plr.PlayerGui:FindFirstChild("Freeze").ImageButton.Amount

		if amount and amount.Value < 3 then
			amount.Value = 3
		end	
		if textAmount then
			if textAmount.Text ~= "3" then
				textAmount.Text = 3
			end
		end
	end

end

local function respawnPlayer()
	for i, plr in pairs(game.Players:GetChildren()) do	
		if plr.Character then
			plr:WaitForChild("Tool").Value = " "
			plr:WaitForChild("Role").Value = "Neutral"
			plr:WaitForChild("CoinStatus").Value = 0
			plr:WaitForChild("StepCounter").Value = 0
			plr:WaitForChild("CloneCounter").Value = 5


			resetPassAmount(plr)

			plr.leaderstats.Kills.Value = 0
			plr.PlayerGui.PutInStarterGui.Enabled = true


			if plr.Team ~= lobbyTeam then
				plr.Team = lobbyTeam
				plr:LoadCharacter()
			end

		end
	end
end

local function destroyTools()
	for _, plr in pairs(game.Players:GetChildren()) do
		if plr.Character and plr.Team ~= lobbyTeam then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:UnequipTools()
			end

			for _, tool in pairs(plr.Backpack:GetChildren()) do
				if tool:IsA("Tool") then
					tool:Destroy()
				end
			end

		end

	end

	local remainingPlayers = game.Players:GetPlayers()
	if #remainingPlayers == 1 then
		-- Respawn the remaining player back to the lobby
		local playerToRespawn = remainingPlayers[1]
		if playerToRespawn.Character and playerToRespawn.Team ~= lobbyTeam then
			respawnPlayer()
		end
	end

end


inRound.Changed:Connect(function()
	if inRound.Value == false then
		local map = game.Workspace.Maps:FindFirstChildOfClass("Model")
		respawnPlayer()
		game.Workspace.Sea.CanCollide = false
		if map then
			map:Destroy()
		end
		rep.MapDestroyed.Value = false
	end
end)

local staus = rep.Status
local requiredPlayers = 2

local voteRemote = rep:WaitForChild("Vote")
local votes = {}

local voteConnection

local function GetVotedTally()
	local voteCount = {}
	local winningScore = 0
	local winningVote = nil

	for choice, data in pairs(votes) do
		voteCount[choice] = 0

		for _, _ in pairs(data) do
			voteCount[choice] += 1
		end

		if voteCount[choice] > winningScore then
			winningScore = voteCount[choice]
			winningVote = choice
		end
	end

	voteRemote:FireAllClients(voteCount)

	return winningVote
end
-- Process a player's vote
local function ProcessVote(player, choice)

	-- Clear previous votes for this player
	for _, data in pairs(votes) do
		data[player.UserId] = nil
	end

	-- Register the new vote
	if votes[choice] then
		votes[choice][player.UserId] = true
	end

	GetVotedTally()
end


local rep = game:GetService("ReplicatedStorage")
local sendStepsEvent = rep:WaitForChild("SendSteps")

-- Connect only once outside of round logic
sendStepsEvent.OnServerEvent:Connect(function(player, steps)
	local stepCounter = player:FindFirstChild("StepCounter")
	if stepCounter and typeof(steps) == "number" then
		stepCounter.Value = steps
		print(player.Name .. " submitted " .. steps .. " steps")
	end
end)

local function round()	
	while true do
		
		inRound.Value = false
		rep.FinalKillActive.Value = false
		repeat
			wait(1)
			staus.Value = "Atleast ".. requiredPlayers.." players are needed to start a round"
			if game.Workspace.Maps:FindFirstChildOfClass("Model") then
				game.Workspace.Maps:FindFirstChildOfClass("Model"):Destroy()
			end
		until #game.Players:GetChildren() >= requiredPlayers

		voteConnection = voteRemote.OnServerEvent:Connect(ProcessVote)

		local minutesvalue = rep:WaitForChild("Minutes")
		local secondsvalue = rep:WaitForChild("Seconds")

		local timer = game.StarterGui.PutInStarterGui.MinutesTimer
		local timerActive = rep.TimerActive
		local timerStatus = rep.TimerStatus


		local doorTimer = game.Workspace.seconds30
		local doorTimerFavela = game.Workspace.seconds30Favela

		rep.VotingModel:Clone().Parent = game.Workspace

		local maps = rep.Maps:GetChildren()
		local isAnOption
		local randomMap

		local chosenMap
		local mapClone

		local votingSystem = game.Workspace:WaitForChild("VotingModel").Voting
		local choices = votingSystem:GetChildren()

		minutesvalue.Value = 0
		secondsvalue.Value = 40
		timerActive.Value = true

		rep.startSteps.Value = false

		local playersAtStart = #game.Players:GetChildren()
		local playersAtIntermission = playersAtStart

		for _, plr in ipairs(game.Players:GetChildren()) do
			if plr and plr.Character or plr.CharacterAdded:Wait() then
				local playerGui = plr:WaitForChild("PlayerGui")
				local votedModeGui = playerGui:WaitForChild("PutInStarterGui"):WaitForChild("VotedMode")
				votedModeGui.Visible = false
			end
		end

		for _, impact in pairs(game.Workspace:GetChildren()) do
			if impact:IsA("BasePart") and impact.Name == "EnvironmentImpact" or impact.Name == "CharacterImpact" then
				impact:Destroy()
			end
		end

		local function PickRandomMap ()

			local randomNumber = math.random(1, #maps)

			randomMap = maps[randomNumber]

			return randomMap.CanBeVoted
		end

		for i, map in pairs(maps) do
			map.CanBeVoted.Value = false
		end

		for i, choice in pairs(choices) do
			if choice:IsA("Part") then
				local name = choice.label.SurfaceGui.TextLabel
				local picture = choice.Image.SurfaceGui.ImageLabel

				isAnOption = PickRandomMap()

				if isAnOption.Value == true then
					repeat 
						isAnOption = PickRandomMap()
					until
					isAnOption.Value == false
					name.Text = randomMap.Name
					picture.Image = "rbxassetid://" ..randomMap.Image.Value
					randomMap.CanBeVoted.Value = true

				else
					name.Text = randomMap.Name
					picture.Image = "rbxassetid://" .. randomMap.Image.Value
					randomMap.CanBeVoted.Value = true		
				end	
			end				
		end	

		for _, plr in ipairs(game.Players:GetChildren()) do
			if plr and plr.Character or plr.CharacterAdded:Wait() then
				local playerGui = plr:WaitForChild("PlayerGui")
				local votingStatus = playerGui:WaitForChild("PutInStarterGui"):WaitForChild("VotingStatusFrame")

				votingStatus.Visible = true
			end
		end


		rep.ChosenMap.Value = " "
		for i = intermission, 0, -1 do

			staus.Value = "INTERMISSION"

			votingStatus.Value = "VOTING MAP " .. i

			timerStatus.Value = "0:"..i.." "
			if i < 10 then
				timerStatus.Value = "0:0"..i.." "
			end

			if i <= 0 then
				rep.MapLoaded.Value = true
				timerActive.Value = false
			end

			playersAtIntermission = #game.Players:GetChildren()
			if playersAtIntermission == 1 then
				break  -- Stop the intermission if only one player is left
			end

			task.wait(1)
		end

		local Choice1Votes = #votingSystem.Choice1.button.Votes:GetChildren()
		local Choice2Votes = #votingSystem.Choice2.button.Votes:GetChildren()
		local Choice3Votes = #votingSystem.Choice3.button.Votes:GetChildren()

		if Choice1Votes >= Choice2Votes and Choice1Votes >= Choice3Votes then

			chosenMap = votingSystem.Choice1.label.SurfaceGui.TextLabel.Text

		elseif Choice2Votes >= Choice1Votes and Choice2Votes >= Choice3Votes then

			chosenMap = votingSystem.Choice2.label.SurfaceGui.TextLabel.Text

		else

			chosenMap = votingSystem.Choice3.label.SurfaceGui.TextLabel.Text

		end

		rep.ChosenMap.Value = chosenMap

		local mapClone

		for i, map in pairs(maps) do
			if chosenMap == map.Name then
				if not game.Workspace.Maps:FindFirstChild(chosenMap) then
					mapClone = map:Clone()
					mapClone.Parent = game.Workspace.Maps
				end
			end
		end

		if game.Workspace.Maps:FindFirstChild(chosenMap) then
			rep.MapLoaded.Value = false
		end

		timerActive.Value = true

		game.Workspace.VotingModel:Destroy()

		for _, plr in ipairs(game.Players:GetChildren()) do
			if plr and plr.Character or plr.CharacterAdded:Wait() then
				local playerGui = plr:WaitForChild("PlayerGui")
				local votingMode = playerGui:WaitForChild("VotingMode")

				votingMode.Enabled = true
			end
		end


		votes = {}
		for _, mode in ipairs(rep:WaitForChild("Modes"):GetChildren()) do
			votes[mode.Name] = {}
		end

		GetVotedTally()

		for i = modeVoting, 0, -1 do

			votingStatus.Value = "VOTING GAMEMODE " .. i

			timerStatus.Value = "0:"..i.." "
			if i < 10 then
				timerStatus.Value = "0:0"..i.." "
			end

			if i == 3 then
				game.Workspace.countdown:Play()
			end

			if i == 0 then
				timerActive.Value = false
			end

			playersAtIntermission = #game.Players:GetChildren()
			if playersAtIntermission == 1 then
				break  -- Stop the intermission if only one player is left
			end

			task.wait(1)
		end


		local modeName = GetVotedTally()
		local mode

		if modeName and rep.Modes:FindFirstChild(modeName) then
			mode = rep.Modes[modeName]
		else
			local modes = rep.Modes:GetChildren()
			mode = modes[math.random(#modes)] -- Random fallback
		end

		-- Set the chosen mode's value to true
		for _, m in ipairs(rep.Modes:GetChildren()) do
			m.Value = false -- Reset all modes
		end
		mode.Value = true

		for _, plr in ipairs(game.Players:GetChildren()) do
			if plr and plr.Character or plr.CharacterAdded:Wait() then
				local playerGui = plr:WaitForChild("PlayerGui")
				local votedModeGui = playerGui:WaitForChild("PutInStarterGui"):WaitForChild("VotedMode")
				local votingMode = playerGui:WaitForChild("VotingMode")
				local votingStatus = playerGui:WaitForChild("PutInStarterGui"):WaitForChild("VotingStatusFrame")

				votingStatus.Visible = false
				votingMode.Enabled = false
				votedModeGui.Visible = true
				votedModeGui.Text = mode.Name
			end
		end


		if playersAtIntermission == 1 then
			staus.Value = "Atleast ".. requiredPlayers.." players are needed to start a round"
		else

			inRound.Value = true

			roundEnded.Value = false	

			if voteConnection then
				voteConnection:Disconnect()
				voteConnection = nil
			end

			local huntersCount = {}
			local propsCount = {}

			minutesvalue.Value = 0
			secondsvalue.Value = 30

			timerActive.Value = true

			doorTimer.SurfaceGui.TextLabel.Visible = true
			doorTimerFavela.SurfaceGui.TextLabel.Visible = true

			rep.startSteps.Value = true

			for i = huntersWillRelease, 0, -1 do

				staus.Value = "HUNTERS RELEASE IN "

				timerStatus.Value = "0:"..i.." "
				if i < 10 then
					timerStatus.Value = "0:0"..i.." "
				end

				if i == 3 then
					game.Workspace.RoundCountdown:Play()
				end

				if i == 0 then
					timerActive.Value = false
				end

				task.wait(1)
			end

			mapClone:FindFirstChild("BlueSpawns"):Destroy()

			local tweenInfo = TweenInfo.new(
				1,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out,
				0,
				false,
				0
			)

			local function createAndPlayTween(object, position, orientation)
				local tween = TweenService:Create(object, tweenInfo, {Position = position})
				local tweenRotate = TweenService:Create(object, tweenInfo, {Orientation = orientation})
				tween:Play()
				tweenRotate:Play()
			end

			local map = game.Workspace.Maps:FindFirstChildOfClass("Model")

			if map.Name == "Cubana" then
				local Door1 = game.Workspace.Maps.Cubana["Horse Stable"].Door1
				local Door3 = game.Workspace.Maps.Cubana["Horse Stable"].Door3

				local doors = {
					{object = Door1, position = Vector3.new(-24.098, 28.424, -380.082), orientation = Vector3.new(0, 0, 0)},
					{object = Door3, position = Vector3.new(-29.3, 28.424, -390.414), orientation = Vector3.new(0, 70, 0)}
				}


				for _, doorData in ipairs(doors) do
					createAndPlayTween(doorData.object, doorData.position, doorData.orientation)
				end


			elseif map.Name == "Plaza" then
				local doorPlaza1 = game.Workspace.Maps.Plaza.Garage.Model.Doors.Door1
				local doorPlaza2 = game.Workspace.Maps.Plaza.Garage.Model.Doors.Door2

				local doorPlaza3 = game.Workspace.Maps.Plaza.Garage1.Model.Doors.Door1
				local doorPlaza4 = game.Workspace.Maps.Plaza.Garage1.Model.Doors.Door2

				local plazaDoors = {
					{object = doorPlaza1, position = Vector3.new(-209.555, 54.983, -923.494), orientation = Vector3.new(-3.513, 90, -90)},
					{object = doorPlaza2, position = Vector3.new(-209.553, 54.948, -904.034), orientation = Vector3.new(-3.513, 90, -90)},
					{object = doorPlaza3, position = Vector3.new(-209.553, 54.948, -882.969), orientation = Vector3.new(-3.513, 90, -90)},
					{object = doorPlaza4, position = Vector3.new(-209.553, 54.948, -863.51), orientation = Vector3.new(-3.513, 90, -90)}
				}

				for _, plazaDoorData in ipairs(plazaDoors) do
					createAndPlayTween(plazaDoorData.object, plazaDoorData.position, plazaDoorData.orientation)
				end
			elseif map.Name == "Favela" then
				local favelaDoor1 = game.Workspace.Maps.Favela.Door1.door1
				local favelaDoor2 = game.Workspace.Maps.Favela.Door2.door2
				local favelaDoor3 = game.Workspace.Maps.Favela.Door3.door3

				local favelaDoors = {
					{object = favelaDoor1, position = Vector3.new(-668.965, 22.232, -516.476), orientation = Vector3.new(0, -172.538, 0)},
					{object = favelaDoor2, position = Vector3.new(-693.485, 22.232, -507.426), orientation = Vector3.new(0, 80.032, 0)},
					{object = favelaDoor3, position = Vector3.new(-708.969, 22.232, -510.92), orientation = Vector3.new(0, -18.238, 0)}
				}


				for _, favelaDoorData in ipairs(favelaDoors) do
					createAndPlayTween(favelaDoorData.object, favelaDoorData.position, favelaDoorData.orientation)
				end
			end

			game.Workspace.Trumpet.trumpet:Play()

			minutesvalue.Value = 4
			secondsvalue.Value = 0

			timerActive.Value = true

			doorTimer.SurfaceGui.TextLabel.Visible = false
			doorTimerFavela.SurfaceGui.TextLabel.Visible = false


			local ranks = {
				{name = "BRONZE", levelToAdvance = 3},
				{name = "SILVER", levelToAdvance = 4},
				{name = "GOLD", levelToAdvance = 4},
				{name = "PLATINUM", levelToAdvance = 5},
				{name = "DIAMOND", levelToAdvance = 5},
				{name = "MASTER", levelToAdvance = 6},
				{name = "GRANDMASTER", levelToAdvance = 6},
				{name = "LEGEND", levelToAdvance = 7},
				{name = "PHANTOM", levelToAdvance = 8},
				{name = "APEX HUNTER", levelToAdvance = math.huge}
			}

			local function incrementLevel(role)
				for _, plr in pairs(game.Players:GetChildren()) do
					local roleVal = plr:FindFirstChild("Role")
					local rank = plr:FindFirstChild("Rank")
					local level = plr:FindFirstChild("Level")

					if roleVal and rank and level and roleVal.Value == role then
						level.Value += 1

						-- Find current rank index
						local currentRankIndex
						for i, rankInfo in ipairs(ranks) do
							if rank.Value == rankInfo.name then
								currentRankIndex = i
								break
							end
						end

						-- Default to BRONZE if not found
						if not currentRankIndex then
							currentRankIndex = 1
							rank.Value = ranks[1].name
						end

						-- Check if player levels up
						local currentRankData = ranks[currentRankIndex]
						if level.Value >= currentRankData.levelToAdvance and currentRankIndex < #ranks then
							local nextRank = ranks[currentRankIndex + 1]
							rank.Value = nextRank.name
							level.Value = 1
						end
					end
				end
			end

			local function incrementLevelMVP(plr)
				local rank = plr:FindFirstChild("Rank")
				local level = plr:FindFirstChild("Level")

				if rank and level then
					level.Value += 1

					-- Find current rank index
					local currentRankIndex
					for i, rankInfo in ipairs(ranks) do
						if rank.Value == rankInfo.name then
							currentRankIndex = i
							break
						end
					end

					-- Default to BRONZE if not found
					if not currentRankIndex then
						currentRankIndex = 1
						rank.Value = ranks[1].name
					end

					-- Check if player levels up
					local currentRankData = ranks[currentRankIndex]
					if level.Value >= currentRankData.levelToAdvance and currentRankIndex < #ranks then
						local nextRank = ranks[currentRankIndex + 1]
						rank.Value = nextRank.name
						level.Value = 1
					end
				end
			end

			local function decrementLevel(role)
				for _, plr in pairs(game.Players:GetChildren()) do
					if plr:WaitForChild("Role").Value == role then
						decrementLevelModule.FireDecrementLevel(plr)
					end
				end
			end

			for i = roundLength, 0, -1 do

				staus.Value = "GAME END'S IN"

				timerStatus.Value = i 
				if i < 10 then
					timerStatus.Value = "0:0"..i.." "
				end

				if i == 0 then
					timerActive.Value = false
				end

				local remainingProps = {}
				local remainingHunters = {}

				for _, plr in pairs(game.Players:GetChildren()) do
					if plr.Team == propsTeam then

						if i == roundLength then
							table.insert(propsCount, plr.Name)
						end

						table.insert(remainingProps, plr.Name)

					elseif plr.Team == huntersTeam then

						if i == roundLength then
							table.insert(huntersCount,plr.Name)
						end

						table.insert(remainingHunters, plr.Name)

					end	
				end

				if i <= 27 then
					if #remainingProps == 1 then
						game.Workspace.Epic.Playing = true
					end
				end


				local rep = game:GetService("ReplicatedStorage")
				local players = game:GetService("Players")

				local remote = rep.DeclareWinner
				local remoteHunter = rep.DeclareWinnerHunter
				local sendStepsEvent = rep:WaitForChild("SendSteps") -- NEW

				local chosenKiller
				local highestStepper

				local function getHighestSteps()
					local highestSteps, highestSteppers = 0, {}

					for i, v in pairs(players:GetChildren()) do
						if v:FindFirstChild("Role").Value == "PROP" then
							local steps = v.StepCounter.Value 
							if steps > 0 then
								if steps > highestSteps then
									highestSteps = steps
									highestSteppers = {v}
								elseif steps == highestSteps then
									table.insert(highestSteppers, v)
								end
							end
						end
					end

					if #highestSteppers > 0 then
						local randomIndex = math.random(1, #highestSteppers)
						highestStepper = highestSteppers[randomIndex]
						remote:FireAllClients(highestStepper)
						return highestStepper
					end

					return nil
				end

				local function getHighestKills()
					local highestKills, highestKillers = 0, {}

					for _, plr in pairs(players:GetChildren()) do
						local role = plr:FindFirstChild("Role")

						if role.Value == "HUNTER" then
							local killsValue = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Kills")
							local kills = killsValue.Value
							if kills > 0 then
								if kills > highestKills then
									highestKills = kills
									highestKillers = {plr}
								elseif kills == highestKills then
									table.insert(highestKillers, plr)
								end
							end
						end
					end

					if #highestKillers > 0 then
						local randomIndex = math.random(1, #highestKillers)
						chosenKiller = highestKillers[randomIndex]
						remoteHunter:FireAllClients(chosenKiller)
						return chosenKiller
					end

					return nil
				end

				local function updatePlayerGui(plr, highestKiller, highestStepper)
					if not highestKiller then
						plr.PlayerGui.StepCounter.winnerHunter.Text = "PLAYER NOT FOUND"
					end
					if not highestStepper then
						plr.PlayerGui.StepCounter.winner.Text = "PLAYER NOT FOUND"
					end
				end

				local propWinner = game.Workspace.PropWinner
				local hunterWinner = game.Workspace.HunterWinner

				local function parallelFor(players, fn)
					local threads = {}
					for _, plr in ipairs(players) do
						local co = coroutine.create(function()
							fn(plr)
						end)
						table.insert(threads, co)
						coroutine.resume(co)
					end
					for _, co in ipairs(threads) do
						if coroutine.status(co) ~= "dead" then
							coroutine.yield(co)
						end
					end
				end

				local function loadHunters()
					local hunters = game.Teams.Hunters:GetPlayers()
					parallelFor(hunters, function(plr)
						if plr.Character then
							plr.PlayerGui.PutInStarterGui.Enabled = false
							plr.PlayerGui.PlayerCounter.Enabled     = false
							plr:LoadCharacter()
						end
					end)
				end

				local function loadProps()
					local props = game.Teams.Props:GetPlayers()
					parallelFor(props, function(plr)
						if plr.Character then
							plr.Team = game.Teams.Hunters
							plr.PlayerGui.Taunt.Enabled        = false
							plr.PlayerGui.Coin.Enabled         = false
							plr.PlayerGui.RotateGui.Enabled    = false
							plr.PlayerGui.StepCounter.steps.Visible = false
							plr.PlayerGui.PutInStarterGui.Enabled   = false
							plr.PlayerGui.PlayerCounter.Enabled     = false
							plr:LoadCharacter()
						end
					end)
				end

				local function declareMVP(highestStepper, highestKiller, propWinner, hunterWinner)
					if highestStepper then
						if highestStepper.Character then
							local mvps = highestStepper.leaderstats.MVPs
							highestStepper:WaitForChild("Cash").Value += 200
							highestStepper.Character:SetPrimaryPartCFrame(propWinner.CFrame + Vector3.new(0, 2, 0))
							highestStepper.Character.Head.NameGUI.name.TextColor3 = Color3.fromRGB(0, 0, 255)
							mvps.Value += 1
							highestStepper.Character.Humanoid.WalkSpeed = 0
							task.wait(1)
							incrementLevelMVP(highestStepper)
						end
					end

					if highestKiller then
						if highestKiller.Character then
							local mvps = highestKiller.leaderstats.MVPs
							highestKiller:WaitForChild("Cash").Value += 200
							highestKiller.Character:SetPrimaryPartCFrame(hunterWinner.CFrame + Vector3.new(0, 2, 0))
							mvps.Value += 1
							highestKiller.Character.Humanoid.WalkSpeed = 0
							task.wait(1)
							incrementLevelMVP(highestKiller)
						end
					end
				end

				local function handleRoundEnd(statusText, winnersText, propWinner, hunterWinner)
					roundEnded.Value = true
					staus.Value = statusText
					destroyTools()
					game.Workspace.Sea.CanCollide = true
					if game.Workspace.Epic.Playing then
						game.Workspace.Epic:Stop()
					end

					if rep.FinalKillActive.Value then
						task.wait(12)	
					end

					game.Workspace["Born A Winner"]:Play()

					winners.Value = winnersText
					task.wait(5)
					if winnersText == "HUNTERS" then
						incrementLevel("HUNTER")
					elseif winnersText == "PROPS" then
						incrementLevel("PROP")
						decrementLevel("HUNTER")
					end
					task.wait(4)
					task.spawn(loadHunters)
					task.spawn(loadProps)
					task.wait(1)
					winners.Value = ""
					staus.Value = "DECLARING MVPS..."
					task.wait(3)
					staus.Value = "RETURNING TO LOBBY..."

					local highestStepper = getHighestSteps()
					local highestKiller = getHighestKills()

					for _, plr in pairs(players:GetChildren()) do
						if plr and plr.Character then
							updatePlayerGui(plr, highestKiller, highestStepper)
							local outsideStorm = plr.PlayerGui:FindFirstChild("OutsideStorm")
							if outsideStorm and outsideStorm.Enabled then
								outsideStorm.Enabled = false
							end
						end
					end

					declareMVP(highestStepper, highestKiller, propWinner, hunterWinner)

					task.wait(6)
					rep.MapDestroyed.Value = true
					task.wait(2)
				end

				-- Win condition logic (unchanged)
				if #remainingHunters == 0 and #remainingProps == 0 then
					handleRoundEnd("BOTH TEAMS LOST!", "", propWinner, hunterWinner)
					break
				elseif #remainingHunters == 0 then
					handleRoundEnd("PROPS WIN!", "PROPS", propWinner, hunterWinner)
					break
				elseif #remainingProps == 0 then
					handleRoundEnd("HUNTERS WIN!", "HUNTERS", propWinner, hunterWinner)
					break
				elseif i == 0 then
					handleRoundEnd("PROPS WIN!", "PROPS", propWinner, hunterWinner)
					break
				end

				task.wait(1)
			end
		end
		task.wait(1)
	end
end

task.spawn(round)