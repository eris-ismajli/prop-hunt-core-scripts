-- LocalScript (StarterPlayerScripts)

-------------------------------------------------
-- Services & references
-------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player        = Players.LocalPlayer
local isOutsideEvt  = ReplicatedStorage:WaitForChild("IsOutside")
local inRound  = ReplicatedStorage:WaitForChild("InRound")

local forcefield    = workspace:WaitForChild("forcefield")
local pathEnd       = forcefield:WaitForChild("PathEnd")
local beam          = pathEnd:WaitForChild("Beam")

-------------------------------------------------
-- Character tracking
-------------------------------------------------
local currentRoot

local function onCharacterAdded(char)
	currentRoot = char:WaitForChild("HumanoidRootPart")
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-------------------------------------------------
-- Helpers to manage the beam attachment
-------------------------------------------------
local function attachBeam()
	if not currentRoot then return end

	local attach = currentRoot:FindFirstChild("A2")
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "A2"
		attach.Parent = currentRoot
	end
	beam.Attachment1 = attach
end

local function detachBeam()
	beam.Attachment1 = nil
	if currentRoot then
		local attach = currentRoot:FindFirstChild("A2")
		if attach then attach:Destroy() end
	end
end

-------------------------------------------------
-- Outside/inside listener (created on demand)
-------------------------------------------------
local outsideConn -- RBXScriptConnection (or nil)

local function connectOutsideListener()
	if outsideConn then return end -- already active
	outsideConn = isOutsideEvt.OnClientEvent:Connect(function(isOutside)
		if isOutside then
			attachBeam()
		else
			detachBeam()
		end
	end)
end

local function disconnectOutsideListener()
	if outsideConn then
		outsideConn:Disconnect()
		outsideConn = nil
	end
	detachBeam()  -- just in case we were still attached
end

-------------------------------------------------
-- Round state watcher
-------------------------------------------------
local function onRoundStateChanged()
	if inRound.Value then
		connectOutsideListener()
	else
		disconnectOutsideListener()
	end
end

-- initial state + react to future changes
onRoundStateChanged()
inRound:GetPropertyChangedSignal("Value"):Connect(onRoundStateChanged)
