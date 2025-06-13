local rep = game:GetService("ReplicatedStorage")
local lobbyMusic = game.Workspace.OldMusic.Sound4

if rep.InRound.Value == false then
	if not lobbyMusic.Playing then
		lobbyMusic:Play()
	end
else
	if lobbyMusic.Playing then
		lobbyMusic:Stop()
	end
end

rep.InRound.Changed:Connect(function()
	if rep.InRound.Value == false then
		if not lobbyMusic.Playing then
			lobbyMusic:Play()
		end
	else
		if lobbyMusic.Playing then
			lobbyMusic:Stop()
		end
	end

end)