--############################################################--
--  RecorderModule  (60 FPS · Now records moveSpeed)
--############################################################--

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RecorderModule = {}
RecorderModule.Recordings   = {}   -- [UserId] = { buffer, start, count }
RecorderModule.Connections  = {}   -- [UserId] = RBXScriptConnection
RecorderModule.Actions      = {}   -- [UserId] = "Shoot", "Reload", etc.
RecorderModule.CamDirs      = {}   -- [UserId] = Vector3

local MAX_DURATION    = 6
local TARGET_FPS      = 60
local RECORD_INTERVAL = 1 / TARGET_FPS
local MAX_FRAMES      = math.ceil(TARGET_FPS * MAX_DURATION)

-----------------------------------------------------------------
--  Listen for camera vectors sent by clients
-----------------------------------------------------------------
local camRemote = ReplicatedStorage:FindFirstChild("CamDirRemote")
	or Instance.new("RemoteEvent", ReplicatedStorage)
camRemote.Name = "CamDirRemote"

camRemote.OnServerEvent:Connect(function(player, vec3)
	if typeof(vec3) == "Vector3" then
		RecorderModule.CamDirs[player.UserId] = vec3
	end
end)

-----------------------------------------------------------------
--  PUBLIC · StartRecording
-----------------------------------------------------------------
function RecorderModule:StartRecording(player)
	local userId = player.UserId

	self.Recordings[userId] = {
		buffer = table.create(MAX_FRAMES),
		start  = 1,
		count  = 0
	}

	if self.Connections[userId] then
		self.Connections[userId]:Disconnect()
	end

	local accumulated = 0
	self.Connections[userId] = RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < RECORD_INTERVAL then return end
		accumulated = 0

		local char = player.Character
		if not char then return end

		local head = char:FindFirstChild("Head")
		local hrp  = char:FindFirstChild("HumanoidRootPart")
		if not head or not hrp then return end

		local look = self.CamDirs[userId] or hrp.CFrame.LookVector
		if look.Magnitude < 0.001 then
			look = hrp.CFrame.LookVector
		end
		local camCF = CFrame.lookAt(head.Position, head.Position + look)

		-- NEW ► horizontal move-speed (for view-model bobbing)
		local moveSpeed = (hrp.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude

		local frame = {
			time       = tick(),
			camCFrame  = camCF,
			rootCFrame = hrp.CFrame,
			moveSpeed  = moveSpeed,          -- ◄ NEW
			action     = self.Actions[userId]
		}
		self.Actions[userId] = nil

		local log  = self.Recordings[userId]
		local i    = (log.start + log.count - 1) % MAX_FRAMES + 1
		log.buffer[i] = frame

		if log.count < MAX_FRAMES then
			log.count += 1
		else
			log.start = (log.start % MAX_FRAMES) + 1
		end
	end)
end

-----------------------------------------------------------------
--  PUBLIC · StopRecording / GetRecording / RecordAction
-----------------------------------------------------------------
function RecorderModule:StopRecording(player)
	local userId = player.UserId
	if self.Connections[userId] then
		task.delay(0.5, function()
			if self.Connections[userId] then
				self.Connections[userId]:Disconnect()
				self.Connections[userId] = nil
			end
			self.Recordings[userId] = nil
			self.Actions[userId]     = nil
			self.CamDirs[userId]     = nil
		end)
	end
end

function RecorderModule:GetRecording(userId)
	local data = self.Recordings[userId]
	if not data then return nil end

	local ordered = {}
	for i = 1, data.count do
		local index   = (data.start + i - 2) % MAX_FRAMES + 1
		ordered[i]    = data.buffer[index]
	end
	return ordered
end

function RecorderModule:RecordAction(player, action)
	self.Actions[player.UserId] = action
end

function RecorderModule:GetRecordingSince(userId, sinceTime)
	local data = self:GetRecording(userId)
	if not data then return nil end

	local filtered = {}
	for _, frame in ipairs(data) do
		if frame.time >= sinceTime then
			table.insert(filtered, frame)
		end
	end
	return filtered
end

return RecorderModule

