local rep = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local hum = player.Character:WaitForChild("Humanoid")
local endPart = workspace:WaitForChild("EndPart")
local realFocusPart = workspace:WaitForChild("RealFocusPart")

local label = script.Parent.winner
local mvp = script.Parent.mvp
local title = script.Parent.Title
local labelHunter = script.Parent.winnerHunter
local mvpHunter = script.Parent.mvpHunter

local mvpSound = player.PlayerGui.StepCounter.WinnerDeclared
local TweenService = game:GetService("TweenService")

-- Remote events
local remote = rep:WaitForChild("DeclareWinner")
local remoteHunter = rep:WaitForChild("DeclareWinnerHunter")

-- Tween helpers
local function tweenTransparency(guiObject, duration, transparency)
	if guiObject:IsA("TextLabel") then
		local tween = TweenService:Create(guiObject, TweenInfo.new(duration), {TextTransparency = transparency})
		tween:Play()
		tween.Completed:Wait()
	end
end

local function tweenImage(guiObject, duration, transparency)
	if guiObject:IsA("ImageLabel") then
		local tween = TweenService:Create(guiObject, TweenInfo.new(duration), {ImageTransparency = transparency})
		tween:Play()
		tween.Completed:Wait()
	end
end

local function tweenPosition(guiObject, duration)
	if guiObject:IsA("ImageLabel") then
		guiObject.ImageTransparency = 0
		local tween = TweenService:Create(guiObject, TweenInfo.new(duration), {
			Position = UDim2.new(0.525, 0, 0.633, 0)
		})
		tween:Play()
		tween.Completed:Wait()
	end
end

-- Cinematic setup
local function setupCinematic(winner)
	label.Visible = true
	mvp.Visible = true
	labelHunter.Visible = true
	mvpHunter.Visible = true
	title.Visible = true

	mvpSound:Play()
	mvpSound.Volume = 0.5

	if winner then
		local playerGui = winner:FindFirstChild("PlayerGui")
		if playerGui then
			local staminaHandler = playerGui:FindFirstChild("Stamina") and playerGui.Stamina:FindFirstChild("SprintHandler")
			if staminaHandler then
				staminaHandler.Enabled = false
			end

			local sprintGui = playerGui:FindFirstChild("Sprint")
			if sprintGui and sprintGui.MobileSprintGUI.Frame.ImageButton.Visible then
				sprintGui.MobileSprintGUI.Frame.ImageButton.Device.Enabled = false
			end

			local notificationGui = playerGui.KillFeed
			local cashImage = notificationGui.Cash
			local cashAmount = cashImage.Amount

			local gameEndedGui = playerGui.GameEnded
			local rankStatusFrame = gameEndedGui.RankStatusFrame
			local rankImage = rankStatusFrame.Rank
			local levelStatus = rankStatusFrame.LevelStatus
			local rankStatus = rankStatusFrame.RankStatus

			local function fade(elements, duration, transparency)
				for _, element in ipairs(elements) do
					local targetProp = element:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
					local tween = TweenService:Create(element, TweenInfo.new(duration), {
						[targetProp] = transparency
					})
					tween:Play()
				end
			end

			coroutine.wrap(function()
				gameEndedGui.Enabled = true
				fade({rankImage, levelStatus, rankStatus}, 0.7, 0)

				cashAmount.Text = "MVP +200"
				cashAmount.TextTransparency = 0
				tweenPosition(cashImage, 0.2)
				task.wait(1)
				tweenImage(cashImage, 1, 1)
				tweenTransparency(cashAmount, 1, 1)
				task.wait(1)
				cashImage.Position = UDim2.new(0.525, 0, 0.695, 0)

				task.wait(2)
				fade({rankImage, levelStatus, rankStatus}, 0.7, 1)
				gameEndedGui.Enabled = false
			end)()
		end
	end

	-- INSTANT camera snap
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(endPart.Position, realFocusPart.Position)

	task.wait(8)

	-- Reset camera and controls
	player.CameraMode = Enum.CameraMode.Classic
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum

	label.Visible = false
	mvp.Visible = false
	labelHunter.Visible = false
	mvpHunter.Visible = false
	title.Visible = false

	if winner then
		local playerGui = winner:FindFirstChild("PlayerGui")
		if playerGui then
			local staminaHandler = playerGui:FindFirstChild("Stamina") and playerGui.Stamina:FindFirstChild("SprintHandler")
			if staminaHandler then
				staminaHandler.Enabled = true
			end

			local sprintGui = playerGui:FindFirstChild("Sprint")
			if sprintGui and sprintGui.MobileSprintGUI.Frame.ImageButton.Visible then
				sprintGui.MobileSprintGUI.Frame.ImageButton.Device.Enabled = true
			end
		end
	end
end

-- Winner display logic
local function handleWinnerEvent(winner)
	if winner and winner:FindFirstChild("StepCounter") then
		label.Text = winner.DisplayName .. " - " .. winner.StepCounter.Value .. " STUDS WALKED"
	else
		label.Text = "No valid walker - 0 STUDS"
	end
	setupCinematic(winner)
end

local function handleWinnerHunterEvent(winner)
	if winner and winner:FindFirstChild("leaderstats") then
		local kills = winner.leaderstats:FindFirstChild("Kills") and winner.leaderstats.Kills.Value or 0
		labelHunter.Text = winner.DisplayName .. " - " .. kills .. " KILLS"
	else
		labelHunter.Text = "No valid hunter - 0 KILLS"
	end
	setupCinematic(winner)
end

-- Manage connections
local remoteConnection1, remoteConnection2

local function disconnectRemote(connection)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

rep.RoundEnded.Changed:Connect(function()
	if rep.RoundEnded.Value then
		remoteConnection1 = remote.OnClientEvent:Connect(handleWinnerEvent)
		remoteConnection2 = remoteHunter.OnClientEvent:Connect(handleWinnerHunterEvent)
	else
		disconnectRemote(remoteConnection1)
		disconnectRemote(remoteConnection2)
	end
end)
