local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local cam               = workspace.CurrentCamera

-- RemoteEvent to tell the server the current LookVector
local remote = ReplicatedStorage:FindFirstChild("CamDirRemote")
	or Instance.new("RemoteEvent", ReplicatedStorage)
remote.Name   = "CamDirRemote"

-- Send every RenderStepped (≈   frame)
RunService.RenderStepped:Connect(function()
	if cam then
		remote:FireServer(cam.CFrame.LookVector)
	end
end)
