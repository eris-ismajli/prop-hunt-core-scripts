local rep = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local minutesvalue = rep:WaitForChild("Minutes")
local secondsvalue = rep:WaitForChild("Seconds")
local minutes  --minutes
local seconds  --seconds

local timerActive = game.ReplicatedStorage.TimerActive

minutes = minutesvalue.Value
seconds = secondsvalue.Value

while true do
	repeat
		if secondsvalue.Value == 0 then
			minutesvalue.Value = minutesvalue.Value - 1
			secondsvalue.Value = 59
		else
			secondsvalue.Value = secondsvalue.Value - 1
		end
		
		task.wait(1)
	until secondsvalue.Value == 0 and minutesvalue.Value == 0
	
	if minutesvalue.Value == 0 and secondsvalue.Value == 0 then
		repeat
			minutesvalue.Value = 0
			secondsvalue.Value = 0
			task.wait(1)
		until timerActive.Value == true
	end
	
	task.wait(1)
	
end