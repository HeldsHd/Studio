--!strict
local RunService = game:GetService("RunService")

local sourceFolder = workspace:WaitForChild("GameRuntime"):WaitForChild("ConveyorKeys")
local visualFolder = Instance.new("Folder")
visualFolder.Name = "ConveyorLocalVisuals"
visualFolder.Parent = workspace

type Animation = {
	clone: Model?, anchor: BasePart, cloneAnchor: BasePart,
	gui: BillboardGui, prompt: ProximityPrompt,
	originalAdornee: Instance?, guiEnabled: boolean, promptEnabled: boolean,
	transparency: { [BasePart]: number },
	origin: Vector3, destination: Vector3, rotation: CFrame,
	spawnTime: number, duration: number, amplitude: number,
	period: number, spin: number, phase: number, expired: boolean,
}
type Entry = { animation: Animation? }
local entries: { [Model]: Entry } = {}

local function numberAttribute(model: Model, name: string): number?
	local value = model:GetAttribute(name)
	if typeof(value) == "number" and value == value and math.abs(value) < math.huge then return value end
	return nil
end

local function prepare(source: Model): Animation?
	local origin = source:GetAttribute("MotionStart")
	local destination = source:GetAttribute("MotionFinish")
	local rotation = source:GetAttribute("MotionRotation")
	local spawnTime = numberAttribute(source, "MotionSpawnTime")
	local duration = numberAttribute(source, "MotionDuration")
	local amplitude = numberAttribute(source, "FloatAmplitude")
	local period = numberAttribute(source, "FloatPeriod")
	local spin = numberAttribute(source, "SpinSpeed")
	local phase = numberAttribute(source, "AnimationPhase")
	local partCount = numberAttribute(source, "ConveyorPartCount")
	if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3"
		or typeof(rotation) ~= "CFrame" or not spawnTime
		or not duration or duration <= 0 or not amplitude or amplitude < 0
		or not period or period <= 0 or not spin or not phase
		or not partCount or partCount < 1 or partCount % 1 ~= 0 then return nil end

	local anchor = source:FindFirstChild("OfferAnchor")
	if not anchor or not anchor:IsA("BasePart") or source.PrimaryPart ~= anchor then return nil end
	local prompt = anchor:FindFirstChild("BuyKey")
	local gui = anchor:FindFirstChild("OfferLabel")
	if not prompt or not prompt:IsA("ProximityPrompt") or not gui or not gui:IsA("BillboardGui") then return nil end

	local originals: { [BasePart]: number } = {}
	local count = 0
	for _, object in ipairs(source:GetDescendants()) do
		if object:IsA("BasePart") then
			if typeof(object:GetAttribute("ConveyorLocalCFrame")) ~= "CFrame" then return nil end
			originals[object] = object.LocalTransparencyModifier
			count += 1
		end
	end
	if count ~= partCount then return nil end

	-- Os offsets originais reconstroem a geometria sem depender de pacotes de posição.
	local clone = source:Clone()
	clone.Name = "ConveyorVisual"
	local cloneAnchor = clone:FindFirstChild("OfferAnchor")
	if not cloneAnchor or not cloneAnchor:IsA("BasePart") then
		clone:Destroy()
		return nil
	end
	local clonedParts = 0
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("ProximityPrompt") or object:IsA("LayerCollector") or object:IsA("LuaSourceContainer") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			local offset = object:GetAttribute("ConveyorLocalCFrame")
			if typeof(offset) ~= "CFrame" then
				clone:Destroy()
				return nil
			end
			object.Anchored = true
			object.CanCollide = false
			object.CanTouch = false
			object.CanQuery = false
			object.LocalTransparencyModifier = 0
			object.CFrame = offset
			clonedParts += 1
		end
	end
	if clonedParts ~= partCount then
		clone:Destroy()
		return nil
	end
	clone.PrimaryPart = cloneAnchor

	local animation: Animation = {
		clone = clone, anchor = anchor, cloneAnchor = cloneAnchor,
		gui = gui, prompt = prompt, originalAdornee = gui.Adornee,
		guiEnabled = gui.Enabled, promptEnabled = prompt.Enabled, transparency = originals,
		origin = origin, destination = destination, rotation = rotation,
		spawnTime = spawnTime, duration = duration, amplitude = amplitude,
		period = period, spin = spin, phase = phase, expired = false,
	}
	for part in pairs(originals) do part.LocalTransparencyModifier = 1 end
	gui.Adornee = cloneAnchor
	clone.Parent = visualFolder
	return animation
end

local function remove(source: Model)
	local entry = entries[source]
	if not entry then return end
	entries[source] = nil
	local animation = entry.animation
	if not animation then return end
	for part, value in pairs(animation.transparency) do
		if part.Parent then part.LocalTransparencyModifier = value end
	end
	if animation.gui.Parent then
		animation.gui.Adornee = animation.originalAdornee
		if animation.expired then animation.gui.Enabled = animation.guiEnabled end
	end
	if animation.expired and animation.prompt.Parent then animation.prompt.Enabled = animation.promptEnabled end
	if animation.clone then animation.clone:Destroy() end
end

local function add(object: Instance)
	if object:IsA("Model") and object.Parent == sourceFolder and not entries[object] then
		entries[object] = { animation = nil }
	end
end

-- Conectar antes de enumerar cobre entradas novas e retorno pelo streaming.
local addedConnection = sourceFolder.ChildAdded:Connect(add)
local removedConnection = sourceFolder.ChildRemoved:Connect(function(object)
	if object:IsA("Model") then remove(object) end
end)
for _, object in ipairs(sourceFolder:GetChildren()) do add(object) end

local renderConnection = RunService.PreRender:Connect(function()
	local now = workspace:GetServerTimeNow()
	local folderPresent = sourceFolder:IsDescendantOf(workspace)
	for source, entry in pairs(entries) do
		if not folderPresent or source.Parent ~= sourceFolder then
			remove(source)
			continue
		end
		local animation = entry.animation
		if not animation then
			animation = prepare(source)
			entry.animation = animation
		end
		if not animation or animation.expired then continue end

		local age = math.max(0, now - animation.spawnTime)
		if age >= animation.duration then
			-- Ocultar até chegar a remoção do servidor evita reaparecer o modelo original.
			animation.expired = true
			animation.guiEnabled = animation.gui.Enabled
			animation.promptEnabled = animation.prompt.Enabled
			animation.gui.Enabled = false
			animation.prompt.Enabled = false
			if animation.clone then animation.clone:Destroy() end
			animation.clone = nil
			continue
		end
		local base = animation.origin:Lerp(animation.destination, age / animation.duration)
		local bob = math.sin(age * (2 * math.pi / animation.period) + animation.phase) * animation.amplitude
		local yaw = age * animation.spin + animation.phase
		local clone = animation.clone
		if clone then
			clone:PivotTo(CFrame.new(base + Vector3.new(0, bob, 0))
				* animation.rotation * CFrame.Angles(0, yaw, 0))
		end
		-- Corrigir só a âncora local mantém o prompt no percurso validado pelo servidor.
		animation.anchor.CFrame = CFrame.new(base) * animation.rotation
	end
end)

script.Destroying:Connect(function()
	renderConnection:Disconnect()
	addedConnection:Disconnect()
	removedConnection:Disconnect()
	for source in pairs(entries) do remove(source) end
	visualFolder:Destroy()
end)
