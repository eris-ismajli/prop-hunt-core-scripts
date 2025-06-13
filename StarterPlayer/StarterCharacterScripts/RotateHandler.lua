local char = script.Parent
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

local rotateRight = player.PlayerGui.RotateGui.Right
local rotateLeft = player.PlayerGui.RotateGui.Left

local isRotating = false
local currentAngle = 0
local pressedKeys = {} -- Tracks which keys are currently pressed
local rotationSpeed = 0.05 -- Smaller value for slower rotation

local function StartRotation(angle)
	if isRotating then return end
	isRotating = true
	while isRotating do
		local rootPart = char:WaitForChild("HumanoidRootPart")
		rootPart.CFrame = rootPart.CFrame * CFrame.fromEulerAnglesXYZ(0.0, angle, 0.0)
		RunService.Stepped:Wait()
	end
end

local function StopRotation()
	isRotating = false
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Q then
		pressedKeys.Q = true
	elseif input.KeyCode == Enum.KeyCode.E then
		pressedKeys.E = true
	end

	RunService.Heartbeat:Wait()

	if pressedKeys.Q and pressedKeys.E then
		StopRotation()
	elseif pressedKeys.Q then
		StartRotation(rotationSpeed)
	elseif pressedKeys.E then
		StartRotation(-rotationSpeed)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Q then
		pressedKeys.Q = false
	elseif input.KeyCode == Enum.KeyCode.E then
		pressedKeys.E = false
	end

	RunService.Heartbeat:Wait()

	if not pressedKeys.Q and not pressedKeys.E then
		StopRotation()
	elseif pressedKeys.Q then
		StartRotation(rotationSpeed)
	elseif pressedKeys.E then
		StartRotation(-rotationSpeed)
	end
end)

-- Mobile Support: Connect buttons
rotateLeft.MouseButton1Down:Connect(function()
	StartRotation(rotationSpeed)
end)
rotateLeft.MouseButton1Up:Connect(function()
	StopRotation()
end)

rotateRight.MouseButton1Down:Connect(function()
	StartRotation(-rotationSpeed)
end)
rotateRight.MouseButton1Up:Connect(function()
	StopRotation()
end)
