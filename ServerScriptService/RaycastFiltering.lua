-- Ultra-optimized NON_STATIC tagging for Prop Hunt, gated by roundEnded

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local roundEnded = ReplicatedStorage:WaitForChild("RoundEnded")
local Constants  = require(ReplicatedStorage.Blaster.Constants)

-- State to manage our connections
local initialized = false
local connections  = {}

-- CORE PARTS for quick tagging
local CORE_PARTS = {
	"Head", "Torso", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "RightUpperArm",
	"LeftUpperLeg", "RightUpperLeg",
}

-- Utility: quick-tag core hitzones
local function quickTag(character)
	for _, name in ipairs(CORE_PARTS) do
		local part = character:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			CollectionService:AddTag(part, Constants.NON_STATIC_TAG)
		end
	end
end

-- Utility: full async, chunked scan
local function tagCharacterAsync(character)
	task.spawn(function()
		local descs = character:GetDescendants()
		for i = 1, #descs do
			local inst = descs[i]
			if inst:IsA("BasePart") then
				CollectionService:AddTag(inst, Constants.NON_STATIC_TAG)
			end
			if i % 10 == 0 then
				task.wait()
			end
		end
	end)
end

-- Manage per-character tagging + cleanup
local taggedChars = setmetatable({}, { __mode = "k" })
local respawnTimers = {}

local function onCharacter(character)
	if taggedChars[character] then return end
	taggedChars[character] = true

	-- Debounce rapid respawns
	local player = Players:GetPlayerFromCharacter(character)
	local now = os.clock()
	if player then
		if respawnTimers[player] and now - respawnTimers[player] < 0.5 then
			return
		end
		respawnTimers[player] = now
	end

	-- Quick-tag core parts
	quickTag(character)
	-- Delayed full scan
	task.delay(1, function() tagCharacterAsync(character) end)

	-- Per-character listener for new parts
	local conn = character.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") then
			CollectionService:AddTag(desc, Constants.NON_STATIC_TAG)
		end
	end)
	table.insert(connections, conn)

	-- Cleanup when character despawns
	conn = character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			conn:Disconnect()
			taggedChars[character] = nil
		end
	end)
	table.insert(connections, conn)
end

-- Main initialization of all looping logic
local function startTagging()
	if initialized then return end
	initialized = true

	local forceField = game.Workspace.forcefield
	CollectionService:AddTag(forceField, Constants.RAY_EXCLUDE_TAG)
	
	-- 2) Hook up player character handlers
	local conn = Players.PlayerAdded:Connect(function(player)
		local cconn = player.CharacterAdded:Connect(onCharacter)
		table.insert(connections, cconn)
		if player.Character then
			onCharacter(player.Character)
		end
	end)
	table.insert(connections, conn)
end

-- Tear everything down
local function stopTagging()
	if not initialized then return end
	initialized = false
	-- Disconnect all stored connections
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	taggedChars = setmetatable({}, { __mode = "k" })
	respawnTimers = {}
end

-- Listen for roundEnded flips
roundEnded:GetPropertyChangedSignal("Value"):Connect(function()
	if roundEnded.Value then
		startTagging()
	else
		stopTagging()
	end
end)

-- If it starts true, begin immediately
if roundEnded.Value then
	startTagging()
end
