local rep = game:GetService("ReplicatedStorage")
local voteRemote = rep:WaitForChild("Vote")
local gui = script.Parent

local remoteConnection

-- Connect buttons to send votes
for _, btn in ipairs(gui.frmVote:GetChildren()) do
	if not btn:IsA("TextButton") then continue end

	btn.Activated:Connect(function()
		voteRemote:FireServer(btn.Name)
	end)
end

-- Update vote counts when receiving data from the server
if rep.InRound.Value == false then
	if not remoteConnection then
		remoteConnection = voteRemote.OnClientEvent:Connect(function(voteCount)
			for name, count in pairs(voteCount) do
				local btn = gui.frmVote:FindFirstChild(name)
				if btn and btn:FindFirstChild("txtCounter") then
					btn.txtCounter.Text = tostring(count) -- Ensure the text is updated properly
				end
			end
		end)
	end
end
rep.InRound.Changed:Connect(function()
	if rep.InRound.Value == false then
		if not remoteConnection then
			remoteConnection = voteRemote.OnClientEvent:Connect(function(voteCount)
				for name, count in pairs(voteCount) do
					local btn = gui.frmVote:FindFirstChild(name)
					if btn and btn:FindFirstChild("txtCounter") then
						btn.txtCounter.Text = tostring(count) -- Ensure the text is updated properly
					end
				end
			end)
		end
	else
		if remoteConnection then
			remoteConnection:Disconnect()
			remoteConnection = nil
		end
	end
end)
