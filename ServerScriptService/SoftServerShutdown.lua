--[[
Author: Wheez
--]]
workspace:SetAttribute("ShuttingDown",false)
local Services={
	["TeleportService"]=game:GetService("TeleportService");
	["PlayersService"]=game:GetService("Players");
	["RunService"]=game:GetService("RunService");
}
local function getServerType()
	if game.PrivateServerId ~= "" then
		if game.PrivateServerOwnerId ~= 0 then
			return "VIPServer"
		else return "ReservedServer"
		end
	else return "StandardServer"
	end
end
local DelayFactor=5
local ServerType=getServerType()
local ServerFactors={
	["ReservedServer"]=function()
		local function TeleportPlayer(P)
			P.Content.Value=true
			Services.TeleportService:Teleport(game.PlaceId,P,{["SoftShutdown"]={true,"Removal"}})
		end
		Services.PlayersService.PlayerAdded:Connect(function(P)
			task.wait(DelayFactor)
			TeleportPlayer(P) DelayFactor/=2
		end)
		for _, P in pairs(Services.PlayersService:GetPlayers()) do 
			TeleportPlayer(P) task.wait(DelayFactor)
			DelayFactor/=2
		end
	end,
	["StandardServer"]=function()
		game:BindToClose(function()
			spawn(function()
				if Services.RunService:IsStudio() then
					warn("Soft Shutdown: System Works Only In Actual Game")
					return
				end
				workspace:SetAttribute("ShuttingDown",true)
				local UITick=os.clock()
				local ReservedCode=Services.TeleportService:ReserveServer(game.PlaceId)
				task.wait(4)
				local function TeleportPlayer(P)
					if (os.clock()-UITick)<0.5 then
						task.wait(1.25)
					end
					P.Content.Value=true
					delay(0.3,function()
						Services.TeleportService:TeleportToPrivateServer(game.PlaceId,ReservedCode,{P},nil,{["SoftShutdown"]={true,"Addition"}})
					end)
				end
				Services.PlayersService.PlayerAdded:Connect(function(P)
					TeleportPlayer(P)
				end)
				for _, P in pairs(Services.PlayersService:GetPlayers()) do 
					TeleportPlayer(P)
				end
			end)
			while #Services.PlayersService:GetPlayers()>0  do
				task.wait()
			end
		end)
	end,
}
Services.PlayersService.PlayerAdded:Connect(function(P)
	local Content=Instance.new("BoolValue")
	Content.Name="Content"
	Content.Parent=P
end)
ServerFactors[ServerType]()