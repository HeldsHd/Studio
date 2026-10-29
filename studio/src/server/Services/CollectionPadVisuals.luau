--!strict
local ServerStorage = game:GetService("ServerStorage")
local Config = require(script.Parent.Parent.Config.SlotConfig)

export type Pad = {
	model: Model,
	touchPart: BasePart,
	label: TextLabel,
	gui: SurfaceGui,
	parts: { [BasePart]: number },
	raycast: RaycastParams,
	visible: boolean,
}
local CollectionPadVisuals = {}

local function formatMoney(amount: number): string
	local text = ("%.0f"):format(math.max(0, math.floor(amount)))
	text = text:reverse():gsub("(%d%d%d)", "%1."):reverse()
	text = text:gsub("^%.", "")
	return text
end

function CollectionPadVisuals.SetState(pad: Pad, visible: boolean, amount: number)
	if pad.visible ~= visible then
		pad.visible = visible
		for part, originalTransparency in pairs(pad.parts) do
			part.Transparency = if visible then originalTransparency else 1
			part.CanTouch = visible
			part.CanQuery = visible
			part.CanCollide = false
		end
		pad.gui.Enabled = visible
	end
	local text = "COLETAR\n$ " .. formatMoney(amount)
	if pad.label.Text ~= text then pad.label.Text = text end
end

function CollectionPadVisuals.Create(folder: Instance, pedestal: BasePart, baseSpawn: BasePart): Pad
	local template = ServerStorage:FindFirstChild("CollectionPadTemplate")
	assert(template and template:IsA("Model"), "CollectionPadTemplate ausente")
	assert(not folder:FindFirstChild("CollectionPad"), "CollectionPad duplicado")
	local model = template:Clone()
	model.Name = "CollectionPad"
	local surface = model:FindFirstChild("CollectSurface")
	assert(surface and surface:IsA("BasePart"), "CollectSurface ausente")

	local parts: { [BasePart]: number } = {}
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BasePart") then
			parts[object] = object.Transparency
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.Transparency = 1
		end
	end
	local bounds, size = model:GetBoundingBox()
	local localPosition = baseSpawn.CFrame:PointToObjectSpace(pedestal.Position)
	local direction = baseSpawn.CFrame.RightVector * (if localPosition.X < 0 then 1 else -1)
	local distance = pedestal.Size.X / 2 + size.Z / 2 + Config.CollectionPadGap
	local floorY = pedestal.Position.Y - pedestal.Size.Y / 2 - 1
	local support = folder:FindFirstChild("Part")
	if support and support:IsA("BasePart") then floorY = support.Position.Y - support.Size.Y / 2 end
	local center = pedestal.Position + direction * distance
	center = Vector3.new(center.X, floorY + size.Y / 2, center.Z)
	local targetBounds = CFrame.lookAt(center, center - direction)
	model:PivotTo(targetBounds * bounds:Inverse() * model:GetPivot())

	local gui = Instance.new("SurfaceGui")
	gui.Name = "CollectionAmount"
	gui.Adornee = surface
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	gui.Enabled = false
	gui.Parent = surface

	local label = Instance.new("TextLabel")
	label.Name = "Amount"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.94, 0.9)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.fromRGB(20, 40, 15)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.TextWrapped = true
	label.RichText = false
	label.Text = "COLETAR\n$ 0"
	label.Parent = gui

	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Include
	raycast.FilterDescendantsInstances = { model }
	raycast.RespectCanCollide = false
	local pad: Pad = {
		model = model, touchPart = surface, label = label, gui = gui,
		parts = parts, raycast = raycast, visible = false,
	}
	model.Parent = folder
	return pad
end

function CollectionPadVisuals.IsStandingOn(player: Player, pad: Pad): boolean
	if not pad.visible or not pad.model.Parent then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	local legHeight = 0
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character and character:FindFirstChild("Left Leg")
		if leg and leg:IsA("BasePart") then legHeight = leg.Size.Y end
	end
	local reach = root.Size.Y / 2 + humanoid.HipHeight + legHeight + Config.CollectionFootTolerance
	return workspace:Raycast(root.Position, Vector3.new(0, -reach, 0), pad.raycast) ~= nil
end

return CollectionPadVisuals
