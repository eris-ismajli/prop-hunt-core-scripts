local backgroundColor = Color3.fromRGB(0, 132, 255)
local maxOnHotbar = 10 
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local p = Players.LocalPlayer
local Backpack = p.Backpack
local Character = p.Character
local Frame = script.Parent.Frame
local Template = Frame.Contents.objTemplate
local COLOR_DARKER = 0.65
local KEY_DICTIONARY = { Zero = 10, One = 1, Two = 2, Three = 3, Four = 4, Five = 5, Six = 6, Seven = 7, Eight = 8, Nine = 9 }
local EQUIP_TWEENINFO = TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local items = {}
local tweens = {}


local function handleEquip(tool)
	if tool.Parent ~= Character then
		Character.Humanoid:EquipTool(tool)
	else
		Character.Humanoid:UnequipTools()
	end
end

local function ensureInteractive(guiObject)
    while guiObject do
        if guiObject:IsA("GuiObject") then
            guiObject.Active = true
        end
        guiObject = guiObject.Parent
    end
end


local EQUIP_POSITION_ON = UDim2.new(0.514, 0, 0.37, 0)
local EQUIP_POSITION_OFF = UDim2.new(0.514, 0, 0.5, 0)  -- Change this to your desired off position

local function updateToolCircle(toolCircle, isEquipped)
	if tweens[toolCircle] then
		tweens[toolCircle]:Cancel()
		tweens[toolCircle] = nil
	end

	-- Tween for UIStroke
	tweens[toolCircle] = TweenService:Create(toolCircle.Background.In.UIStroke, EQUIP_TWEENINFO, {
		Enabled = isEquipped
	})
	tweens[toolCircle]:Play()

	-- Tween for Position
	local targetPosition = isEquipped and EQUIP_POSITION_ON or EQUIP_POSITION_OFF
	local positionTween = TweenService:Create(toolCircle.Background, EQUIP_TWEENINFO, {
		Position = targetPosition
	})
	positionTween:Play()
end

local function checkHotbar(removeIndex)
	if removeIndex then
		for _, toolCircle in pairs(Frame.Contents:GetChildren()) do
			if toolCircle:IsA("GuiObject") then
				if tonumber(toolCircle.Name) >= removeIndex then
					local newIndex = (tonumber(toolCircle.Name) == 11) and 0 or tonumber(toolCircle.Name) - 1
					local isVisible = (maxOnHotbar == 10) and (newIndex <= 9 and true or false) or ((newIndex ~= 0 and newIndex <= maxOnHotbar) and true or false)

					toolCircle.LayoutOrder -= 1
					toolCircle.Name -= 1
					toolCircle.Visible = isVisible
					toolCircle.Background.Index.Text = newIndex
				end
			end
		end
	end

	local additionalIndex = Frame.AdditionalIndex
	additionalIndex.Size = UDim2.new(0, Frame.Contents.UIListLayout.AbsoluteContentSize.X + Frame.Contents.AbsoluteSize.Y + 15, 0, 25)
	additionalIndex.Text = "+" .. (#items - maxOnHotbar)
	additionalIndex.Visible = (#items > maxOnHotbar)

	for index, tool in ipairs(items) do
		local toolCircle = Frame.Contents:FindFirstChild(index)
		local isEquipped = (tool.Parent == Character)

		if not toolCircle then
			return
		end

		updateToolCircle(toolCircle, isEquipped)
	end
end

local function create(tool)
	local nextIndex = (#items == 10) and 0 or #items
	local isVisible = (maxOnHotbar == 10) and (nextIndex <= 9 and true or false) or ((nextIndex ~= 0 and nextIndex <= maxOnHotbar) and true or false)
	local toolCircle = Template:Clone()
	toolCircle.LayoutOrder = #items
	toolCircle.Name = #items
	toolCircle.Size = UDim2.new(0, Frame.Contents.AbsoluteSize.Y, 0, Frame.Contents.AbsoluteSize.Y)
	toolCircle.Visible = isVisible
	toolCircle.Background.Image.Image = tool.TextureId
	toolCircle.Background.Index.Text = nextIndex
	toolCircle.Background.FixedName.Text = tool.TextureId == "" and tool.Name or ""
	toolCircle.Parent = Frame.Contents

	-- Ensure all parent frames are interactive
	ensureInteractive(toolCircle.Background.Image)

	toolCircle.Background.Image.MouseButton1Click:Connect(function()
		handleEquip(tool)
	end)

	checkHotbar()
end

local function updateAdd(tool)
	if not tool:IsA("Tool") then
		return
	end
	
	checkHotbar()
	
	if table.find(items, tool) then
		return
	end
	
	table.insert(items, tool)
		
	create(tool)
end

local function updateRemove(tool)
	if not tool:IsA("Tool") then
		return
	end
	
	if tool.Parent == Character or tool.Parent == Backpack then
		return
	end
	
	if table.find(items, tool) then
		local index = table.find(items, tool)
		local toolCircle = Frame.Contents:FindFirstChild(index)
		
		if toolCircle then
			toolCircle:Destroy()
		end
		
		table.remove(items, index)
		checkHotbar(index)
	end
end


while true do
	local success, err = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	if success then
		break
	end
	task.wait()
end

if maxOnHotbar > 10 then
	maxOnHotbar = 10
end

Template.Visible = true
Template.Parent = nil
for _, tool in pairs(Backpack:GetChildren()) do
	updateAdd(tool)
end
Backpack.ChildAdded:Connect(updateAdd)
Backpack.ChildRemoved:Connect(updateRemove)
Character.ChildAdded:Connect(updateAdd)
Character.ChildRemoved:Connect(updateRemove)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	
	if KEY_DICTIONARY[input.KeyCode.Name] then
		local index = KEY_DICTIONARY[input.KeyCode.Name]
		
		if items[index] then
			handleEquip(items[index])
		end
	end
end)