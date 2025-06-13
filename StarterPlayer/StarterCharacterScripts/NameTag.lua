local char = script.Parent
local replicated = game:GetService("ReplicatedStorage")
local NameGui = replicated.NameGUI
local RankGui = replicated.RankGUI
local plr = game.Players:GetPlayerFromCharacter(char)

local nameClone = NameGui:Clone()
local rankClone = RankGui:Clone()

local playerRank = plr:WaitForChild("Rank")

-- Rank-to-color mapping
local rankColors = {
	["BRONZE"] = Color3.fromRGB(143, 88, 0),
	["SILVER"] = Color3.fromRGB(179, 219, 222),
	["GOLD"] = Color3.fromRGB(255, 204, 0),
	["PLATINUM"] = Color3.fromRGB(0, 145, 255),
	["DIAMOND"] = Color3.fromRGB(85, 255, 255),
	["MASTER"] = Color3.fromRGB(170, 0, 255),
	["GRANDMASTER"] = Color3.fromRGB(255, 0, 208),
	["LEGEND"] = Color3.fromRGB(255, 100, 0),
	["PHANTOM"] = Color3.fromRGB(90, 0, 120),
	["APEX HUNTER"] = Color3.fromRGB(0, 0, 0),
}

-- Setup name GUI
nameClone.name.Text = plr.DisplayName
nameClone.Adornee = char.Head
nameClone.name.TextColor3 = plr.Team.TeamColor.Color
nameClone.Parent = char.Head

-- Setup rank GUI
rankClone.rank.Text = playerRank.Value
rankClone.Adornee = char.Head
rankClone.rank.TextColor3 = rankColors[playerRank.Value] or Color3.new(1, 1, 1) -- fallback: white
rankClone.Parent = char.Head

if playerRank.Value == "APEX HUNTER" then
	rankClone.rank.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
else
	rankClone.rank.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
end

-- Update rank GUI when rank changes
playerRank:GetPropertyChangedSignal("Value"):Connect(function()
	rankClone.rank.Text = playerRank.Value
	rankClone.rank.TextColor3 = rankColors[playerRank.Value] or Color3.new(1, 1, 1)
	if playerRank.Value == "APEX HUNTER" then
		rankClone.rank.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	else
		rankClone.rank.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end
end)

-- Update name color when team changes
plr:GetPropertyChangedSignal("Team"):Connect(function()
	nameClone.name.TextColor3 = plr.Team.TeamColor.Color
end)

-- Hide default name
local human = char:WaitForChild("Humanoid")
human.DisplayDistanceType = "None"
