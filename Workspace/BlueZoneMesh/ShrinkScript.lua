-- Scripted by AdvancedDrone (upgraded & optimized)
local TweenService    = game:GetService("TweenService")
local Players         = game:GetService("Players")
local ReplicatedStore = game:GetService("ReplicatedStorage")

local trumpetCall    = workspace:WaitForChild("StormClosing")  -- Sound
local InRound        = ReplicatedStore:WaitForChild("InRound")
local Modes          = ReplicatedStore:WaitForChild("Modes")
local blueZoneFlag   = Modes:WaitForChild("Blue Zone")

local objectToShrink = script.Parent
local pathEnd        = objectToShrink:WaitForChild("PathEnd")

-- Config
local duration     = 10      -- seconds per shrink tween
local breakTime    = 25      -- seconds between shrinks
local steps        = 5       -- how many times we shrink
local finalSizeX   = 70
local finalSizeZ   = 70

-- How far above the bottom face should PathEnd sit?
local offsetHeight = 20  -- studs; increase to move it higher

-- State
local isShrinking  = false
local initialSize  = objectToShrink.Size
local finalSize    = Vector3.new(finalSizeX, initialSize.Y, finalSizeZ)
local stepDelta    = (initialSize - finalSize) / steps

-- Position PathEnd at bottom-center + offsetHeight
local function updatePathEnd()
	local pos   = objectToShrink.Position
	local halfY = objectToShrink.Size.Y * 0.5
	pathEnd.Position = Vector3.new(
		pos.X,
		pos.Y - halfY + offsetHeight,
		pos.Z
	)
end

-- place once at startup
updatePathEnd()

-- Utility: animate each player's UI indicator
local function flashPlayerUI()
	for _, plr in ipairs(Players:GetPlayers()) do
		local gui      = plr:FindFirstChild("PlayerGui")
		local stormGui = gui and gui:FindFirstChild("OutsideStorm")
		local icon     = stormGui and stormGui:FindFirstChild("Shrinking")
		if icon then
			TweenService:Create(icon, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
			task.delay(4, function()
				TweenService:Create(icon, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
			end)
		end
	end
end

-- Reset object when round ends
local function resetObject()
	isShrinking = false
	objectToShrink.Size        = initialSize
	objectToShrink.Transparency = 1 
	updatePathEnd()
end

-- The shrink loop
local function shrinkLoop()
	if isShrinking then return end
	isShrinking = true

	objectToShrink.Transparency = 0
	task.wait(breakTime)  -- initial delay

	for i = 1, steps do
		if not InRound.Value or not blueZoneFlag.Value then
			break
		end

		-- play trumpet
		if trumpetCall:IsA("Sound") then
			trumpetCall:Play()
		end

		task.spawn(flashPlayerUI)  -- flash UI

		-- tween to next size
		local targetSize = initialSize - stepDelta * i
		local tween = TweenService:Create(
			objectToShrink,
			TweenInfo.new(duration, Enum.EasingStyle.Linear),
			{ Size = targetSize }
		)
		tween:Play()
		tween.Completed:Wait()

		updatePathEnd()  -- reposition after size change

		if i < steps then
			task.wait(breakTime)
		end
	end

	isShrinking = false
end

-- Listen for round start/end
InRound:GetPropertyChangedSignal("Value"):Connect(function()
	if InRound.Value and blueZoneFlag.Value then
		shrinkLoop()
	else
		resetObject()
	end
end)

-- Clean up if Blue Zone toggles off mid-shrink
blueZoneFlag:GetPropertyChangedSignal("Value"):Connect(function()
	if not blueZoneFlag.Value then
		resetObject()
	elseif InRound.Value then
		shrinkLoop()
	end
end)
