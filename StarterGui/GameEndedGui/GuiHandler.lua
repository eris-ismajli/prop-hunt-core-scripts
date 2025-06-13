local TweenService = game:GetService("TweenService")
local blur = game.Lighting:WaitForChild("Blur")
local player = game.Players.LocalPlayer

local guiParent = player:WaitForChild("PlayerGui"):WaitForChild("GameEnded")

local Hunters = guiParent.Hunters
local Props = guiParent.Props
local win = guiParent.Win
local rankStatusFrame = guiParent.RankStatusFrame

local rankImage = rankStatusFrame.Rank
local levelStatus = rankStatusFrame.LevelStatus
local rankStatus = rankStatusFrame.RankStatus

local level = player:WaitForChild("Level")
local rank = player:WaitForChild("Rank")

local rankUpSound = guiParent.RankUp
local levelUpSound = guiParent.LevelUp
local rankDownSound = guiParent.RankDown


local winners = game:GetService("ReplicatedStorage").Winners

local ranks = {
	{name = "BRONZE", levelToAdvance = 3},
	{name = "SILVER", levelToAdvance = 4},
	{name = "GOLD", levelToAdvance = 4},
	{name = "PLATINUM", levelToAdvance = 5},
	{name = "DIAMOND", levelToAdvance = 5},
	{name = "MASTER", levelToAdvance = 6},
	{name = "GRANDMASTER", levelToAdvance = 6},
	{name = "LEGEND", levelToAdvance = 7},
	{name = "PHANTOM", levelToAdvance = 8},
	{name = "APEX HUNTER", levelToAdvance = math.huge}
}

local function getRankIndex(rankName)
	for i, v in ipairs(ranks) do
		if v.name == rankName then
			return i
		end
	end
	return -1
end

local function tweenPosition(guiObject, targetPosition, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quint,
		easingDirection or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(guiObject, tweenInfo, { Position = targetPosition })
	tween:Play()
	return tween
end

local function fadeInOut(elements, duration, waitTime)
	for _, element in ipairs(elements) do
		local targetProp = element:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
		local tweenOut = TweenService:Create(element, TweenInfo.new(duration), { [targetProp] = 1 })
		tweenOut:Play()
	end
	task.wait(waitTime)
	for _, element in ipairs(elements) do
		local targetProp = element:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
		local tweenIn = TweenService:Create(element, TweenInfo.new(duration), { [targetProp] = 0 })
		tweenIn:Play()
	end
end

local function fade(elements, duration, transparency)
	for _, element in ipairs(elements) do
		local targetProp = element:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
		local tween = TweenService:Create(element, TweenInfo.new(duration), {
			[targetProp] = transparency
		})
		tween:Play()
	end
end

local function transparent(elements)
	for _, element in ipairs(elements) do
		if element:IsA("ImageLabel") then
			element.ImageTransparency = 1
		elseif element:IsA("TextLabel") then
			element.TextTransparency = 1
		end
	end
end


local function tweenUI(winnerObject, startPosition, endPosition)
	guiParent.Enabled = true
	blur.Enabled = true

	tweenPosition(winnerObject, startPosition, 0.5)
	tweenPosition(win, UDim2.new(0.277, 0, 0.376, 0), 0.5)

	transparent({rankImage, levelStatus, rankStatus})

	task.wait(2)

	tweenPosition(winnerObject, endPosition, 0.5)
	tweenPosition(win, UDim2.new(0.999, 0, 0.376, 0), 0.5)

	local oldLevel = level.Value
	local oldRank = rank.Value

	task.wait(1)

	fade({rankImage, levelStatus, rankStatus}, 0.6, 0)
	rankStatus.Text = ""

	local function handleChanges()
		local newLevel = level.Value
		local newRank = rank.Value
		local levelChanged = newLevel ~= oldLevel
		local rankChanged = newRank ~= oldRank

		if not levelChanged and not rankChanged then return end

		local statusText = ""
		local statusColor = Color3.new(1, 1, 1)

		if rankChanged then
			local oldRankIndex = getRankIndex(oldRank)
			local newRankIndex = getRankIndex(newRank)
			if newRankIndex > oldRankIndex then
				statusText = "RANK UP"
				statusColor = Color3.fromRGB(150, 225, 0)
				rankUpSound:Play()
			elseif newRankIndex < oldRankIndex then
				statusText = "RANK DOWN"
				statusColor = Color3.fromRGB(255, 0, 0)
				rankDownSound:Play()
			end
		elseif levelChanged then
			if newLevel > oldLevel then
				statusText = "LEVEL UP"
				statusColor = Color3.fromRGB(0, 170, 255)

				levelUpSound:Play()
			elseif newLevel < oldLevel then
				statusText = "LEVEL DOWN"
				statusColor = Color3.fromRGB(255, 170, 0)
			end
		end

		rankStatus.Text = statusText
		rankStatus.TextColor3 = statusColor
		fadeInOut({rankImage, levelStatus, rankStatus}, 0.5, 0.2)

		oldLevel = newLevel
		oldRank = newRank
	end


	if winners.Value ~= "" then
		level:GetPropertyChangedSignal("Value"):Connect(handleChanges)
		rank:GetPropertyChangedSignal("Value"):Connect(handleChanges)	
	end

	task.wait(6)

	-- Reset visuals
	fade({rankImage, levelStatus, rankStatus}, 0.6, 1)
	rankStatus.Text = ""
	rankStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
	blur.Enabled = false
	guiParent.Enabled = false
end

game.ReplicatedStorage:WaitForChild("Winners").Changed:Connect(function()
	local winner = game.ReplicatedStorage.Winners.Value
	if winner == "PROPS" then
		tweenUI(Props, UDim2.new(0.276, 0, 0.172, 0), UDim2.new(-0.5, 0, 0.172, 0))
	elseif winner == "HUNTERS" then
		tweenUI(Hunters, UDim2.new(0.287, 0, 0.172, 0), UDim2.new(-0.5, 0, 0.172, 0))
	end
end)
