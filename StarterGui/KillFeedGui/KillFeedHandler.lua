--// Variables \\--
local gui = script.Parent
local holder = gui:WaitForChild("Holder", 10)
local template = holder:WaitForChild("Template", 10)
local list = holder:WaitForChild("List", 10)
local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes", 10)
local sendFeed = remotes:WaitForChild("SendFeed", 10)
local inRound = replicatedStorage:WaitForChild("InRound", 10)
local debris = game:GetService("Debris")

--// Functions \\--

local function CloneTemplate()
	local clone = template:Clone()
	clone.Parent = list
	return clone
end

local function CreateMessage(killerPlayer, victimPlayer)
	local message = CloneTemplate()
	local killer = message:WaitForChild("Killer", 10)
	local victim = message:WaitForChild("Victim", 10)
	local killerBG = message:WaitForChild("KillerBG", 10)
	local victimBG = message:WaitForChild("VictimBG", 10)
	local action = message:WaitForChild("Action", 10)
	local clip = message:WaitForChild("clip", 10)

	-- Apply names and colors
	killer.Text = killerPlayer and killerPlayer.DisplayName or "Unknown"
	killerBG.BackgroundColor3 = killerPlayer and killerPlayer.TeamColor.Color or Color3.fromRGB(255, 255, 255)

	victim.Text = victimPlayer and victimPlayer.DisplayName or "Unknown"
	victimBG.BackgroundColor3 = victimPlayer and victimPlayer.TeamColor.Color or Color3.fromRGB(255, 255, 255)

	-- Apply layout order
	local messages = list:GetChildren()
	message.LayoutOrder = (message.LayoutOrder + #messages) + 1

	message.Name = "Message"
	message.Visible = true

	-- Fade out over time
	task.wait(5)
	for i = 0, 1, 0.2 do
		killer.TextTransparency += i
		victim.TextTransparency += i
		killerBG.BackgroundTransparency += i
		killerBG.UIStroke.Transparency += i
		victimBG.BackgroundTransparency += i
		victimBG.UIStroke.Transparency += i
		action.ImageTransparency += i
		clip.ImageLabel.ImageTransparency += i
		task.wait(0.05)
	end

	debris:AddItem(message, 10)
end

--// Connection Handling \\--

local remoteConnection

local function ConnectToFeed()
	if not remoteConnection then
		remoteConnection = sendFeed.OnClientEvent:Connect(CreateMessage)
	end
end

local function DisconnectFeed()
	if remoteConnection then
		remoteConnection:Disconnect()
		remoteConnection = nil
	end
end

-- Initial state
if inRound.Value then
	ConnectToFeed()
end

-- React to round changes
inRound.Changed:Connect(function()
	if inRound.Value then
		ConnectToFeed()
	else
		DisconnectFeed()
	end
end)
