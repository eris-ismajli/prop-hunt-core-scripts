-- Scripted by AdvancedDrone (upgraded – now fully respawn-safe)
local camera           = workspace.CurrentCamera
local TweenService     = game:GetService("TweenService")
local UIS              = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local player           = game.Players.LocalPlayer

-- Initial GUI + Bar references
local gui              = player:WaitForChild("PlayerGui"):WaitForChild("Sprint"):WaitForChild("MobileSprintGUI")
local button           = gui.Frame:WaitForChild("ImageButton")
local Bar              = script.Parent:WaitForChild("STMBackground"):WaitForChild("Bar")

-- Speeds
local NormalWalkSpeed  = 24
local NewWalkSpeed     = 30

-- State
local power            = 10
local sprinting        = false
local humanoid

-- power drain/regain rates
local DRAIN_RATE       = 0.018
local RECHARGE_RATE    = 0.02

-- update GUI bar
local function updateBar()
	Bar.Size = UDim2.new(math.clamp(power / 10, 0, 1), 0, 1, 0)
end

-- loop refs
local drainConn, rechargeConn

local function stopRecharging()
	if rechargeConn then
		rechargeConn:Disconnect()
		rechargeConn = nil
	end
end

local function stopDraining()
	if drainConn then
		drainConn:Disconnect()
		drainConn = nil
	end
end

function stopSprinting()
	if not sprinting then return end
	sprinting = false
	if humanoid then humanoid.WalkSpeed = NormalWalkSpeed end
	stopDraining()
	while power < 10 and not sprinting do
		power = power + RECHARGE_RATE
		updateBar()
		wait()
		if power >= 10 then
			power = 10
			stopRecharging()
		end
	end
end

local function startSprinting()
	if sprinting or power <= 0 or not humanoid then return end
	sprinting = true
	humanoid.WalkSpeed = NewWalkSpeed

	stopRecharging()
	while power > 0 and sprinting do
		power = power - DRAIN_RATE
		updateBar()
		wait()
		if power <= 0 then
			power = 0
			stopSprinting()
		end
	end
end

-- rebinding after respawn
local function bindCharacter(char)
	humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = sprinting and NewWalkSpeed or NormalWalkSpeed

	-- GUI rebinding for mobile input
	gui = player:WaitForChild("PlayerGui"):WaitForChild("Sprint"):WaitForChild("MobileSprintGUI")
	button = gui.Frame:WaitForChild("ImageButton")
	button.Active = false
end

-- Wait for initial character and bind
if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

-- Keyboard (desktop)
UIS.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftShift then
		startSprinting()
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftShift then
		stopSprinting()
	end
end)

-- Mobile: detect touch over ImageButton
UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		local absPos = button.AbsolutePosition
		local size = button.AbsoluteSize
		if pos.X >= absPos.X and pos.X <= absPos.X + size.X
			and pos.Y >= absPos.Y and pos.Y <= absPos.Y + size.Y then
			startSprinting()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		local absPos = button.AbsolutePosition
		local size = button.AbsoluteSize
		if pos.X >= absPos.X and pos.X <= absPos.X + size.X
			and pos.Y >= absPos.Y and pos.Y <= absPos.Y + size.Y then
			stopSprinting()
		end
	end
end)

-- Initial GUI update
updateBar()
