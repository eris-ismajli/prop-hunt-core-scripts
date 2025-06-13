
-- // Services

-- External services
local tweenService = game:GetService("TweenService")

-- Default services
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")

-- // Variables

-- Comms variables
local killEvent = replicatedStorage:WaitForChild("KillNotification")
local decoyEvent = replicatedStorage:WaitForChild("DecoyNotification")

-- Player variables
local player = playersService.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- UI variables
local killGUI = script.Parent
local notification = killGUI:WaitForChild("Notification")
local decoyNotification = killGUI:WaitForChild("DestroyedDecoy")
local cashNotification = killGUI:WaitForChild("Cash")
local cashText = cashNotification:WaitForChild("Amount")

local killSound = script:WaitForChild("KillSound")
local poofSound = script:WaitForChild("Poof")
local cashSound = script:WaitForChild("CashSound")

-- // Functions

local function tweenTransparency(guiObject, duration, transparency)
	spawn(function()

		local tween = nil

		if guiObject:IsA("TextLabel") then
			local tween = tweenService:Create(guiObject, TweenInfo.new(duration), {TextTransparency = transparency})

			tween:Play()

			spawn(function()
				tween.Completed:Wait()
				tween:Destroy()
			end)
		end

		if tween ~= nil then
			return tween
		end

	end)
end

local function tweenImage(guiObject, duration, transparency)
	spawn(function()

		local tween = nil

		if guiObject:IsA("ImageLabel") then
			local tween = tweenService:Create(guiObject, TweenInfo.new(duration), {ImageTransparency = transparency})

			tween:Play()

			spawn(function()
				tween.Completed:Wait()
				tween:Destroy()
			end)
		end

		if tween ~= nil then
			return tween
		end

	end)
end

local function tweenPosition(guiObject, duration)
	if not guiObject:IsA("ImageLabel") then
		return -- Exit if it's not an ImageLabel
	end

	task.spawn(function()
		guiObject.ImageTransparency = 0
		local tween = tweenService:Create(guiObject, TweenInfo.new(duration), {Position = UDim2.new(0.525, 0, 0.633, 0)})

		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()
	end)
end


local function notify(victim)

	notification.TextTransparency = 1

	notification.Text = "<font color='#ff3a3a'> ELIMINATED </font>" .. victim.DisplayName

	if notification.UIGradient.Enabled == true then
		notification.UIGradient.Enabled = false
	end

	killSound:Play()
	
	cashText.Text = "KILL +150"
	
	tweenTransparency(notification, 0.5, 0) 
	task.wait(0.5)
	cashSound:Play()
	cashText.TextTransparency = 0
	tweenPosition(cashNotification, 0.2)
	task.wait(1)
	tweenImage(cashNotification, 1, 1)
	tweenTransparency(cashText, 1, 1)
	task.wait(1)
	cashNotification.Position = UDim2.new(0.525, 0, 0.695, 0)
	tweenTransparency(notification, 0.3, 1)
end

local function decoyNotify()
	decoyNotification.ImageTransparency = 1

	poofSound:Play()

	tweenImage(decoyNotification, 0.5, 0) 
	task.wait(2.5)
	tweenImage(decoyNotification, 0.5, 1)
end

-- // Connections
local killEventConnection
local decoyEventConnection

local function disconnectKillEvent()
	if killEventConnection then
		killEventConnection:Disconnect()
		killEventConnection = nil
	end
end

local function disconnectDecoyEvent()
	if decoyEventConnection then
		decoyEventConnection:Disconnect()
		decoyEventConnection = nil
	end
end

if replicatedStorage.InRound.Value == true then
	if not killEventConnection then
		killEventConnection = killEvent.OnClientEvent:Connect(notify)
	end
	if not decoyEventConnection then
		decoyEventConnection = decoyEvent.OnClientEvent:Connect(decoyNotify)
	end
else
	disconnectKillEvent()
	disconnectDecoyEvent()
end

replicatedStorage.InRound.Changed:Connect(function()
	if replicatedStorage.InRound.Value == true then
		if not killEventConnection then
			killEventConnection = killEvent.OnClientEvent:Connect(notify)
		end
		if not decoyEventConnection then
			decoyEventConnection = decoyEvent.OnClientEvent:Connect(decoyNotify)
		end
	else
		disconnectKillEvent()
		disconnectDecoyEvent()
	end
end)


