--!strict
local ServerStorage = game:GetService("ServerStorage")
local ItemConfig = require(script.Parent.Parent.Config.ItemConfig)
local ItemMetadata = require(script.Parent.ItemMetadata)
local ItemVisuals = {}

local function createModel(itemId: string, maxSizeField: string)
	local definition = ItemConfig.Items[itemId]
	assert(definition, "Item desconhecido: " .. itemId)
	local templates = ServerStorage:FindFirstChild("ItemTemplates")
	local template = templates and templates:FindFirstChild(itemId)
	assert(template and template:IsA("Model"), "Modelo ausente: " .. itemId)
	local model = template:Clone()
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") or descendant:IsA("JointInstance") or descendant:IsA("Constraint") then
			descendant:Destroy()
		end
	end
	model:PivotTo(CFrame.new())
	local _, size = model:GetBoundingBox()
	local limit = definition[maxSizeField]
	local factor = math.min(1, limit.X / math.max(size.X, 0.001), limit.Y / math.max(size.Y, 0.001), limit.Z / math.max(size.Z, 0.001))
	if factor < 1 then
		model:ScaleTo(model:GetScale() * factor)
	end
	return model, definition
end

local function configurePart(part: BasePart, anchored: boolean)
	part.Anchored = anchored
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
end

function ItemVisuals.CreateDisplay(itemId: string, metadata: ItemMetadata.Input?): Model
	local model = createModel(itemId, "DisplayMaxSize")
	model.Name = "ItemDisplay"
	ItemMetadata.ApplyAttributes(model, metadata)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			configurePart(part, true)
		end
	end
	return model
end

function ItemVisuals.CreateTool(itemId: string, metadata: ItemMetadata.Input?): Tool
	local model, definition = createModel(itemId, "HandMaxSize")
	local bounds, size = model:GetBoundingBox()
	local tool = Instance.new("Tool")
	tool.Name = definition.Name
	tool.ToolTip = definition.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = definition.Grip or CFrame.new()
	tool:SetAttribute("ItemId", itemId)
	tool:SetAttribute("ItemKind", definition.Kind)
	ItemMetadata.ApplyAttributes(tool, metadata)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 0.25, 0.25)
	handle.Transparency = 1
	handle.CastShadow = false
	handle.CFrame = bounds * CFrame.new(0, -size.Y / 2, 0)
	configurePart(handle, false)
	handle.Parent = tool
	model.Name = "Visual"
	model.Parent = tool
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			configurePart(part, false)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = handle
		end
	end
	return tool
end

return ItemVisuals
