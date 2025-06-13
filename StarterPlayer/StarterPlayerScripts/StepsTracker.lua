-- LocalScript: Optimized Step Tracker with Debugging (Only Runs When Needed)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local localPlayer = Players.LocalPlayer
local PropsTeam = Teams:WaitForChild("Props")

local STEP_THRESHOLD_SQ = 1 * 1
local UPDATE_INTERVAL = 0.7

local lastPos = nil
local heartbeatConn = nil

-- Step tracking logic
local function updateStepCounter()
	local char = localPlayer.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if not hrp or not humanoid or humanoid.MoveDirection.Magnitude == 0 then return end

	local newPos = hrp.Position
	if lastPos and (newPos - lastPos).Magnitude ^ 2 >= STEP_THRESHOLD_SQ then
		local stepCounter = localPlayer:FindFirstChild("StepCounter")
		if stepCounter then
			stepCounter.Value += 1
		end
		lastPos = newPos
	end
end

-- Start the step tracking loop
local function startTracking()
	if heartbeatConn then heartbeatConn:Disconnect() end

	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("[StepTracker] HRP missing, cannot track steps")
		return
	end

	lastPos = hrp.Position
	local accumulator = 0

	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator = 0
			updateStepCounter()
		end
	end)
end

-- Stop the step tracking loop
local function stopTracking()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	lastPos = nil
end

-- Evaluate whether to track steps
local function evaluateTracking()
	if ReplicatedStorage.InRound.Value and localPlayer.Team == PropsTeam then
		startTracking()
	else
		stopTracking()
	end
end

-- Round status change
ReplicatedStorage.InRound:GetPropertyChangedSignal("Value"):Connect(evaluateTracking)

-- Team change
localPlayer:GetPropertyChangedSignal("Team"):Connect(evaluateTracking)

-- Character added
localPlayer.CharacterAdded:Connect(function()
	task.wait(0.1)
	evaluateTracking()
end)

-- Round ended
ReplicatedStorage.RoundEnded.Changed:Connect(function()
	if ReplicatedStorage.RoundEnded.Value then
		local stepCounter = localPlayer:FindFirstChild("StepCounter")
		if stepCounter then
			local steps = stepCounter.Value
			ReplicatedStorage:WaitForChild("SendSteps"):FireServer(steps)
		end
	end
end)

-- Initial check
evaluateTracking()
