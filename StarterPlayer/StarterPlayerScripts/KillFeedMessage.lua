local rep = game:GetService("ReplicatedStorage")
local remoteConnection

local function triggerMSG(msg)
	-- Display a system message in the chat
	game.StarterGui:SetCore("ChatMakeSystemMessage", 
		{
			Text = msg,
			Color = Color3.fromRGB(5, 255, 63),
			Font = Enum.Font.LuckiestGuy,
			TextSize = 20,
		})
end

rep.InRound.Changed:Connect(function()
	if rep.InRound.Value then
		-- Ensure the connection is made only once
		if not remoteConnection then
			remoteConnection = rep.OnPlayerKilled.OnClientEvent:Connect(triggerMSG)
		end
	else
		-- Disconnect the event when the round ends
		if remoteConnection then
			remoteConnection:Disconnect()
			remoteConnection = nil
		end
	end
end)
