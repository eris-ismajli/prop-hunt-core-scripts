--#####################################################################
--  Universal Zip‑Line Controller  ·  with Magnet mesh support
--  Safe, Optimized, Cleaned
--#####################################################################

-- CONFIG
local TAG_NAME      = "ZiplineScript"
local SPEED         = 50
local OFFSET_FACTOR = 1.5
local COOLDOWN_TIME = 2
local ACTION_TEXT   = "Ride"
local OBJECT_TEXT   = "Zip-line"
local KEY           = Enum.KeyCode.F

-- SERVICES
local CollectionService = game:GetService("CollectionService")
local TweenService      = game:GetService("TweenService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

-- HELPERS
local PITCH = math.rad(-90)

local function makeMagnetCF(pos, dir)
	return CFrame.new(pos, pos + dir) * CFrame.Angles(PITCH, 0, 0)
end

local function getHRP(player)
	local char = player.Character or player.CharacterAdded:Wait()
	return char:FindFirstChild("HumanoidRootPart")
end

-- ZIPLINE SETUP
local function setupZipLine(model)
	if not (model and model:IsA("Model")) then return end

	local startPart = model:FindFirstChild("Start")
	local endPart   = model:FindFirstChild("End")
	if not (startPart and endPart and startPart:IsA("BasePart") and endPart:IsA("BasePart")) then return end

	local magnet = model:FindFirstChild("Magnet")
	if magnet and not magnet:IsA("BasePart") then
		magnet = nil
	end

	local slideEffect = magnet and magnet:FindFirstChildWhichIsA("ParticleEmitter", true)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent               = startPart
	prompt.ActionText           = ACTION_TEXT
	prompt.ObjectText           = OBJECT_TEXT
	prompt.KeyboardKeyCode      = KEY
	prompt.HoldDuration         = 0.5
	prompt.RequiresLineOfSight  = false
	prompt.MaxActivationDistance = 20

	local a0 = Instance.new("Attachment", startPart)
	local a1 = Instance.new("Attachment", endPart)
	local beam = Instance.new("Beam", startPart)
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.FaceCamera     = true
	beam.Transparency   = NumberSequence.new(0)
	beam.Width0         = 0.2
	beam.Width1         = 0.2

	local zipSound = startPart:FindFirstChild("zipline")
	local busy = false

	local function ride(player)
		local hrp = getHRP(player)
		if not hrp then return end
		if not player:IsDescendantOf(game) then return end

		local yOffset   = hrp.Size.Y * OFFSET_FACTOR
		local startCF   = startPart.CFrame - Vector3.new(0, yOffset, 0)
		local endCF     = endPart.CFrame   - Vector3.new(0, yOffset, 0)
		local dir       = (endPart.Position - startPart.Position).Unit

		hrp.Anchored = true
		hrp.CFrame = startCF * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0)

		local distance  = (startCF.Position - endCF.Position).Magnitude
		local travelT   = distance / SPEED
		local moveInfo  = TweenInfo.new(travelT, Enum.EasingStyle.Linear)

		local hrpTween = TweenService:Create(hrp, moveInfo, {CFrame = endCF})

		local magStartCF, magEndCF, magTween, returnTween
		if magnet then
			magnet.Anchored = true
			magStartCF = makeMagnetCF(startPart.Position, dir)
			magEndCF   = makeMagnetCF(endPart.Position, dir)
			magnet.CFrame = magStartCF
			magTween   = TweenService:Create(magnet, moveInfo, {CFrame = magEndCF})
		end

		if zipSound then zipSound:Play() end
		if magTween then magTween:Play() end
		if slideEffect then slideEffect.Enabled = true end

		hrpTween:Play()
		hrpTween.Completed:Wait()

		if slideEffect then slideEffect.Enabled = false end
		hrp.Anchored = false

		task.wait(1)

		if magnet then
			returnTween = TweenService:Create(
				magnet,
				TweenInfo.new(COOLDOWN_TIME, Enum.EasingStyle.Linear),
				{CFrame = magStartCF}
			)
			returnTween:Play()
			if slideEffect then slideEffect.Enabled = true end
			returnTween.Completed:Wait()
			if slideEffect then slideEffect.Enabled = false end
		else
			task.wait(COOLDOWN_TIME)
		end
	end

	prompt.Triggered:Connect(function(player)
		if busy then return end
		busy, prompt.Enabled = true, false
		local success = pcall(ride, player)
		prompt.Enabled, busy = true, false
	end)
end

game.ReplicatedStorage.InRound.Changed:Connect(function()
	if game.ReplicatedStorage.InRound.Value == true then
		local map = game.Workspace.Maps:FindFirstChildOfClass("Model")
		if not map then return end

		for _, zip in ipairs(CollectionService:GetTagged(TAG_NAME)) do
			if zip:IsDescendantOf(map) then
				setupZipLine(zip)
			end 
		end

		CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupZipLine)
	end
end)
