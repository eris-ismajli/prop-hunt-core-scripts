--############################################################--
--  KillReplayServer (Final Killcam Time Threshold Check)     --
--############################################################--


local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams             = game:GetService("Teams")
local Debris            = game:GetService("Debris")

local killEvent         = ReplicatedStorage:WaitForChild("KillNotification")
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local SendFeed          = Remotes:WaitForChild("SendFeed")
local KillcamEnded      = ReplicatedStorage:WaitForChild("KillcamEnded")
local RoundEnded        = ReplicatedStorage:WaitForChild("RoundEnded")
local FinalKillActive   = ReplicatedStorage:WaitForChild("FinalKillActive")

local KillReplayRemote  = ReplicatedStorage:FindFirstChild("KillReplayRemote") or Instance.new("RemoteEvent")
KillReplayRemote.Name   = "KillReplayRemote"
KillReplayRemote.Parent = ReplicatedStorage

local replayFolder      = ReplicatedStorage:FindFirstChild("ReplayVictims") or Instance.new("Folder")
replayFolder.Name       = "ReplayVictims"
replayFolder.Parent     = ReplicatedStorage

local Recorder          = require(script.Parent:WaitForChild("RecorderModule"))
local lobbyTeam         = Teams:WaitForChild("Lobby")
local propsTeam         = Teams:WaitForChild("Props")

Players.CharacterAutoLoads = false
local awaitingKillcam   = {}
local respawnScheduled  = {}
local cleanupConn       = {}
local killcamConn       = {}
local charAddedConn     = {}
local lastKillTimestamp = 0
local finalKillData     = nil
local finalRoundConn    = nil

local function deepCopy(tbl)
	local result = {}
	for k, v in pairs(tbl) do
		result[k] = typeof(v) == "table" and deepCopy(v) or v
	end
	return result
end

local function safeLoadCharacter(player)
	if player and player.Parent and not respawnScheduled[player] then
		respawnScheduled[player] = true
		pcall(function() player:LoadCharacter() end)
		task.defer(function() respawnScheduled[player] = nil end)
	end
end

local function IsAlive(p)
	return p.Team == propsTeam
		and p.Character
		and p.Character:FindFirstChild("Humanoid")
		and p.Character.Humanoid.Health > 0
end


Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	Instance.new("IntValue", stats).Name = "Kills"
	Instance.new("IntValue", stats).Name = "MVPs"

	task.defer(function()
		if not awaitingKillcam[player] then
			safeLoadCharacter(player)
		end
	end)

	local function updateTeam(team)
		if team == lobbyTeam then
			Recorder:StopRecording(player)
		else
			Recorder:StartRecording(player)
		end
	end
	updateTeam(player.Team)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		updateTeam(player.Team)
	end)

	if killcamConn[player] then killcamConn[player]:Disconnect() end
	killcamConn[player] = KillcamEnded.OnServerEvent:Connect(function(p)
		if p == player and awaitingKillcam[player] then
			print("[KillcamEnded] Received from:", player.Name)
			awaitingKillcam[player] = nil
			safeLoadCharacter(player)
		end
	end)

	if charAddedConn[player] then charAddedConn[player]:Disconnect() end
	charAddedConn[player] = player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		if cleanupConn[player] then cleanupConn[player]:Disconnect() end

		cleanupConn[player] = humanoid.Died:Connect(function()
			awaitingKillcam[player] = nil
			local tag = char:FindFirstChild("creator")
			local killer = tag and tag.Value


			if killer and killer:IsA("Player") then
				killer:WaitForChild("Cash").Value += 150
				killer.leaderstats.Kills.Value    += 1
				killEvent:FireClient(killer, player)
				SendFeed:FireAllClients(killer, player)
			else
				task.delay(5, function()
					if not awaitingKillcam[player] then
						safeLoadCharacter(player)
					end
				end)
			end

			for _, item in ipairs(replayFolder:GetChildren()) do
				if item:GetAttribute("ReplayOwner") == player.Name then
					item:Destroy()
				end
			end

			for _, acc in ipairs(char:GetChildren()) do
				if acc:IsA("Accessory") and acc:FindFirstChild("Handle") then
					acc.Handle.Transparency = 1
				end
			end

			local clone = char:Clone()
			clone.Name = player.Name
			clone:SetAttribute("ReplayOwner", player.Name)
			clone.Parent = replayFolder
			Debris:AddItem(clone, 90)

			local root = clone:FindFirstChild("HumanoidRootPart")
			local attach = root and root:FindFirstChild("Attachment")
			if attach then
				for _, em in ipairs(attach:GetChildren()) do
					if em:IsA("ParticleEmitter") then em.Enabled = false end
				end
			end

			if not player or not player.Parent then return end

			local timeNow = tick()
			local victimReplay = Recorder:GetRecordingSince(player.UserId, timeNow - 6)
			Recorder:StopRecording(player)

			local killerReplay
			if killer and killer:IsA("Player") then
				killerReplay = Recorder:GetRecordingSince(killer.UserId, timeNow - 6)
				-- Only stop if they're dead (or you’ll break the next kill!)
				if killer.Team == lobbyTeam then
					Recorder:StopRecording(killer)
				end
			end
			local hasReplay = killer and killer:IsA("Player") and killerReplay and victimReplay and player.Team ~= lobbyTeam

			if hasReplay then
				lastKillTimestamp = timeNow

				local aliveEnemies = 0
				for _, p in ipairs(Players:GetPlayers()) do
					local alive = IsAlive(p)
					if p ~= player and alive then
						aliveEnemies += 1
					end
				end

				awaitingKillcam[player] = true
				KillReplayRemote:FireClient(player, killer.Name, deepCopy(killerReplay), deepCopy(victimReplay), false, clone.Name, timeNow)

				if aliveEnemies == 0 then

					if not finalKillData or timeNow > finalKillData.timestamp then
						finalKillData = {
							killer = killer,
							victim = player,
							killerReplay = deepCopy(killerReplay),
							victimReplay = deepCopy(victimReplay),
							cloneName = clone.Name,
							timestamp = timeNow,
							playbackTime = tick() + 1.5  -- 🆕 ADD THIS LINE
						}
					end

					if finalRoundConn then
						finalRoundConn:Disconnect()
						finalRoundConn = nil
					end

					finalRoundConn = RoundEnded.Changed:Connect(function()

						if RoundEnded.Value then

							local roundEndTime = tick()

							if finalKillData and (roundEndTime - finalKillData.timestamp) < 60 then
								FinalKillActive.Value = true

								for _, p in ipairs(Players:GetPlayers()) do
									if p ~= finalKillData.victim and p.Team ~= lobbyTeam then

										awaitingKillcam[p] = true
										KillReplayRemote:FireClient(
											p,
											finalKillData.killer.Name,
											finalKillData.killerReplay,
											finalKillData.victimReplay,
											true,
											finalKillData.cloneName,
											finalKillData.timestamp,
											finalKillData.playbackTime -- 🧠 the magic sync timestamp
										)
									end
								end

								task.delay(10, function()
									for _, p in ipairs(Players:GetPlayers()) do
										if awaitingKillcam[p] then
											awaitingKillcam[p] = nil
											safeLoadCharacter(p)
										end
									end
								end)
								for _, p in ipairs(Players:GetPlayers()) do
									if p.Team == lobbyTeam and Recorder:IsRecording(p) then
										Recorder:StopRecording(p)
									end
								end

							end

							if finalRoundConn then
								finalRoundConn:Disconnect()
								finalRoundConn = nil
							end

						end
					end)
				end
			end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	Recorder:StopRecording(player)
	awaitingKillcam[player] = nil
	Recorder.Recordings[player.UserId] = nil

	if cleanupConn[player]   then cleanupConn[player]:Disconnect()   end
	if killcamConn[player]   then killcamConn[player]:Disconnect()   end
	if charAddedConn[player] then charAddedConn[player]:Disconnect() end

	cleanupConn[player], killcamConn[player], charAddedConn[player] = nil, nil, nil
	respawnScheduled[player] = nil
end)
