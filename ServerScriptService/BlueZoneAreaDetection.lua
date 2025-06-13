--#####################################################################
--  Safe & Strict Blue Zone Storm Controller
--#####################################################################

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Teams             = game:GetService("Teams")

-- References
local forcefieldPart = workspace:WaitForChild("forcefield")
local lobbyTeam     = Teams:WaitForChild("Lobby")
local propsTeam     = Teams:WaitForChild("Props")
local huntersTeam   = Teams:WaitForChild("Hunters")
local ROUND_TEAMS   = { [propsTeam] = true, [huntersTeam] = true }

local isOutsideEvent = ReplicatedStorage:WaitForChild("IsOutside")
local inRoundValue   = ReplicatedStorage:WaitForChild("InRound")
local blueZoneFlag   = ReplicatedStorage:WaitForChild("Modes"):WaitForChild("Blue Zone")

-- State
local playersStatus = {} -- [player.Name] = { inside = bool, lastDamageTime = number }
local heartbeatConn = nil

-- Utility
local function canRunZone()
	return inRoundValue.Value and blueZoneFlag.Value
end

local function isPlayerOutside(part, player)
	local char = player.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local pos = hrp.Position - part.Position
	local shrink = 3
	local sx, sy, sz = part.Size.X / 2 - shrink, part.Size.Y / 2 - shrink, part.Size.Z / 2 - shrink
	local heightRatio = math.clamp(1 - (pos.Y / sy), 0, 1)
	local rx, rz = sx * heightRatio, sz * heightRatio

	return (pos.X^2)/(rx^2) + (pos.Z^2)/(rz^2) > 1 or pos.Y > sy
end

local function getStormGui(player)
	local gui = player:FindFirstChild("PlayerGui")
	local storm = gui and gui:FindFirstChild("OutsideStorm")
	return storm and storm:FindFirstChild("Outside"), storm and storm:FindFirstChild("Run")
end

local function tweenImageTransparency(image, target)
	if image then
		TweenService:Create(image, TweenInfo.new(0.3), { ImageTransparency = target }):Play()
	end
end

local function pushOutsideState(player, isOutside)
	local showGui = blueZoneFlag.Value
	local outsideImage, runImage = getStormGui(player)

	tweenImageTransparency(outsideImage, showGui and (isOutside and 0 or 1) or 1)
	tweenImageTransparency(runImage,     showGui and (isOutside and 0 or 1) or 1)

	if not showGui then return end

	isOutsideEvent:FireClient(player, isOutside)

	if isOutside and runImage then
		task.spawn(function()
			tweenImageTransparency(runImage, 0)
			task.wait(3)
			tweenImageTransparency(runImage, 1)
		end)
	end
end

local function applyDamage(player)
	local now = tick()
	local status = playersStatus[player.Name]
	if not status or status.inside or now - status.lastDamageTime < 1 then return end

	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then hum:TakeDamage(10) end
	status.lastDamageTime = now
end

local function waitForValidTeam(player)
	while not ROUND_TEAMS[player.Team] do task.wait() end
end

local function setupPlayer(player)
	if not canRunZone() then return end

	local function init()
		waitForValidTeam(player)
		local char = player.Character or player.CharacterAdded:Wait()
		char:WaitForChild("HumanoidRootPart")

		local inside = not isPlayerOutside(forcefieldPart, player)
		playersStatus[player.Name] = {
			inside = inside,
			lastDamageTime = tick(),
		}
		pushOutsideState(player, not inside)
	end

	init()

	player.CharacterAdded:Connect(function()
		if canRunZone() then init() end
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		if canRunZone() then init() end
	end)
end

local function stopHeartbeat()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	table.clear(playersStatus)
end

local function startHeartbeat()
	if heartbeatConn then return end

	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not canRunZone() then
			stopHeartbeat()
			return
		end

		local now = tick()
		for _, player in ipairs(Players:GetPlayers()) do
			local status = playersStatus[player.Name]
			if not status then continue end

			local outside = isPlayerOutside(forcefieldPart, player)
			local isInsideNow = not outside

			if isInsideNow ~= status.inside then
				status.inside = isInsideNow
				status.lastDamageTime = now
				pushOutsideState(player, outside)
			end

			if player.Team == propsTeam and not isInsideNow then
				applyDamage(player)
			end
		end
	end)
end

local function updateHeartbeat()
	if canRunZone() then
		startHeartbeat()
		for _, player in ipairs(Players:GetPlayers()) do
			setupPlayer(player)
		end
	end
end

-- Connections
inRoundValue:GetPropertyChangedSignal("Value"):Connect(updateHeartbeat)
blueZoneFlag:GetPropertyChangedSignal("Value"):Connect(updateHeartbeat)

Players.PlayerAdded:Connect(function(player)
	if canRunZone() then
		setupPlayer(player)
	end
end)

-- Initial start
updateHeartbeat()
