--!strict
local ServerStorage = game:GetService("ServerStorage")
local Config = require(script.Parent.Parent.Config.ChestConfig)
local ChestVisuals = {}

function ChestVisuals.GetTemplate(chestId: string): Model
	local definition = Config.Chests[chestId]
	assert(definition, "Baú desconhecido: " .. chestId)
	local folder = ServerStorage:FindFirstChild("Chests")
	local group = folder and folder:FindFirstChild(definition.TemplateGroup)
	local template = group and group:FindFirstChild(definition.TemplateName)
	assert(template and template:IsA("Model") and template.Archivable,
		"Modelo de baú ausente ou não clonável: " .. chestId)
	assert(template:FindFirstChildWhichIsA("BasePart", true), "Modelo de baú sem peças")
	return template
end

function ChestVisuals.CreateDisplay(chestId: string, marker: BasePart): Model
	local definition = Config.Chests[chestId]
	local model = ChestVisuals.GetTemplate(chestId):Clone()
	local ok, message = pcall(function()
		model.Name = "ChestDisplay"
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("LuaSourceContainer") or object:IsA("JointInstance")
				or object:IsA("Constraint") or object:IsA("ProximityPrompt") or object:IsA("LayerCollector") then
				object:Destroy()
			elseif object:IsA("BasePart") then
				object.Anchored = true
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
			end
		end
		model:ScaleTo(definition.DisplayScale)
		local bounds, size = model:GetBoundingBox()
		local target = marker.CFrame
			* CFrame.new(0, Config.SurfaceOffset + size.Y / 2, 0)
			* CFrame.Angles(0, math.rad(definition.DisplayYawDegrees), 0)
		model:PivotTo(target * bounds:ToObjectSpace(model:GetPivot()))
	end)
	if not ok then
		model:Destroy()
		error(tostring(message))
	end
	return model
end

return ChestVisuals
