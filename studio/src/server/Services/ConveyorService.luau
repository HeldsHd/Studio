--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(script.Parent.Parent.Config.ConveyorConfig)
local ItemConfig = require(script.Parent.Parent.Config.ItemConfig)
local EconomyConfig = require(script.Parent.Parent.Config.EconomyConfig)
local BaseService = require(script.Parent.BaseService)
local InventoryService = require(script.Parent.InventoryService)
local ItemVisuals = require(script.Parent.ItemVisuals)
local ItemMetadata = require(script.Parent.ItemMetadata)

type Definition = { ItemId: string, Price: number, Weight: number, Metadata: ItemMetadata.Metadata }
type Offer = {
	model: Model, prompt: ProximityPrompt, itemId: string, price: number,
	bornAt: number, available: boolean, metadata: ItemMetadata.Metadata,
}
local ConveyorService = {}
local offers: { [Model]: Offer } = {}
local lastPurchase: { [Player]: number } = {}
local definitions: { Definition } = {}
local random = Random.new()
local started = false
local count = 0
local totalWeight = 0
local origin = Vector3.zero
local destination = Vector3.zero
local rotation = CFrame.new()
local duration = 1
local runtime: Folder? = nil
local feedback: RemoteEvent? = nil

local function send(player: Player, success: boolean, message: string)
	if feedback and player.Parent == Players then feedback:FireClient(player, success, message) end
end

local function positionAt(offer: Offer, now: number): Vector3
	return origin:Lerp(destination, math.clamp((now - offer.bornAt) / duration, 0, 1))
end

local function removeOffer(offer: Offer)
	if offers[offer.model] ~= offer then return end
	offers[offer.model] = nil
	count -= 1
	offer.available = false
	offer.prompt.Enabled = false
	offer.model:Destroy()
end

local function purchase(player: Player, offer: Offer)
	if player.Parent ~= Players then return end
	local now = workspace:GetServerTimeNow()
	if now - (lastPurchase[player] or -math.huge) < Config.PurchaseCooldown then return end
	lastPurchase[player] = now
	if offers[offer.model] ~= offer or not offer.available then
		send(player, false, "Essa chave já foi comprada.")
		return
	end
	if now - offer.bornAt >= duration or not offer.model.Parent then
		removeOffer(offer)
		send(player, false, "Essa chave já saiu da esteira.")
		return
	end
	if not BaseService.GetBase(player) then
		send(player, false, "Aguarde receber uma base para comprar.")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end
	-- Distância até a posição calculada no servidor, nunca enviada pelo cliente.
	if (root.Position - positionAt(offer, now)).Magnitude > Config.InteractionDistance then
		send(player, false, "Aproxime-se da chave para comprar.")
		return
	end
	offer.available = false
	offer.prompt.Enabled = false
	local success, message = InventoryService.TryPurchase(player, offer.itemId, offer.price, offer.metadata)
	if success then
		local text = ("Comprou %s por $%d."):format(ItemConfig.Items[offer.itemId].Name, offer.price)
		removeOffer(offer)
		send(player, true, text)
	else
		offer.available = true
		offer.prompt.Enabled = true
		send(player, false, message or "Não foi possível comprar.")
	end
end

local function chooseDefinition(): Definition
	local choice = random:NextNumber(0, totalWeight)
	local accumulated = 0
	for _, definition in ipairs(definitions) do
		accumulated += definition.Weight
		if choice < accumulated then return definition end
	end
	return definitions[#definitions]
end

local function spawnOffer(now: number)
	local definition = chooseDefinition()
	-- Futuro sorteio/evento define os metadados antes da criação da oferta.
	-- A cópia congelada permanece com o exemplar depois de um evento terminar.
	local metadata = ItemMetadata.Normalize(definition.Metadata)
	local model = ItemVisuals.CreateDisplay(definition.ItemId, metadata)
	model.Name = definition.ItemId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- Dados de apresentação. Validação da compra usa somente os registros privados.
	model:SetAttribute("MotionStart", origin)
	model:SetAttribute("MotionFinish", destination)
	model:SetAttribute("MotionRotation", rotation)
	model:SetAttribute("MotionSpawnTime", now)
	model:SetAttribute("MotionDuration", duration)
	model:SetAttribute("FloatAmplitude", Config.FloatAmplitude)
	model:SetAttribute("FloatPeriod", Config.FloatPeriod)
	model:SetAttribute("SpinSpeed", math.rad(Config.SpinDegreesPerSecond))
	model:SetAttribute("AnimationPhase", random:NextNumber(0, math.pi * 2))
	model:SetAttribute("ItemId", definition.ItemId)
	model:SetAttribute("Price", definition.Price) -- Apenas exibição; oferta privada define a compra.

	local anchor = Instance.new("Part")
	anchor.Name = "OfferAnchor"
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Parent = model
	model.PrimaryPart = anchor
	-- Offset estável evita copiar peças de pacotes de movimento de instantes distintos.
	local partCount = 0
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part:SetAttribute("ConveyorLocalCFrame", anchor.CFrame:ToObjectSpace(part.CFrame))
			partCount += 1
		end
	end
	model:SetAttribute("ConveyorPartCount", partCount)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyKey"
	prompt.ActionText = ("Comprar · $%d"):format(definition.Price)
	prompt.ObjectText = ItemConfig.Items[definition.ItemId].Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = Config.HoldDuration
	prompt.MaxActivationDistance = Config.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor

	local gui = Instance.new("BillboardGui")
	gui.Name = "OfferLabel"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(170, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = 65
	gui.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 26, 35)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextWrapped = true
	label.RichText = false
	label.Text = ("%s\n$%d"):format(ItemConfig.Items[definition.ItemId].Name, definition.Price)
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	gui.Parent = anchor

	local offer: Offer = {
		model = model, prompt = prompt, itemId = definition.ItemId, price = definition.Price,
		bornAt = now, available = true, metadata = metadata,
	}
	model:PivotTo(CFrame.new(origin) * rotation)
	offers[model] = offer
	count += 1
	prompt.Triggered:Connect(function(player) purchase(player, offer) end)
	model.Parent = runtime
end

local function positive(value: number): boolean
	return value == value and value > 0 and value < math.huge
end

function ConveyorService.Start()
	assert(not started, "ConveyorService já iniciado")
	assert(positive(Config.Speed) and positive(Config.SpawnInterval) and positive(Config.UpdateInterval),
		"Velocidade/frequência da esteira inválidas")
	assert(Config.FloatAmplitude >= 0 and Config.FloatAmplitude < math.huge
		and positive(Config.FloatPeriod) and math.abs(Config.SpinDegreesPerSecond) < math.huge,
		"Animação da esteira inválida")
	assert(Config.MaxOffers >= 1 and Config.MaxOffers % 1 == 0, "Limite de ofertas inválido")
	local templates = ServerStorage:FindFirstChild("ItemTemplates")
	assert(templates, "ItemTemplates ausente")
	for _, definition in ipairs(Config.Offers) do
		local item = ItemConfig.Items[definition.ItemId]
		local template = templates:FindFirstChild(definition.ItemId)
		assert(item and item.Kind == "Key" and template and template:IsA("Model"), "Chave inválida na esteira")
		assert(positive(definition.Price) and definition.Price <= EconomyConfig.MaxBalance
			and definition.Price % 1 == 0 and positive(definition.Weight), "Preço/peso inválido")
		table.insert(definitions, {
			ItemId = definition.ItemId, Price = definition.Price, Weight = definition.Weight,
			Metadata = ItemMetadata.Normalize(definition.Metadata),
		})
		totalWeight += definition.Weight
	end
	assert(#definitions > 0 and positive(totalWeight), "Nenhuma oferta válida")
	local folder = workspace:FindFirstChild(Config.FolderName)
	local belt = folder and folder:FindFirstChild(Config.BeltName)
	assert(belt and belt:IsA("BasePart") and belt.Anchored, ("%s.%s deve ser uma peça ancorada"):format(Config.FolderName, Config.BeltName))
	local startPoint = belt:FindFirstChild(Config.StartName)
	local finishPoint = belt:FindFirstChild(Config.FinishName)
	assert(startPoint and startPoint:IsA("Attachment") and finishPoint and finishPoint:IsA("Attachment"),
		"Attachments Start/Finish ausentes")
	origin = startPoint.WorldPosition
	destination = finishPoint.WorldPosition
	rotation = startPoint.WorldCFrame.Rotation
	assert((destination - origin).Magnitude > 1, "Percurso da esteira muito curto")
	duration = (destination - origin).Magnitude / Config.Speed
	local gameRuntime = workspace:FindFirstChild("GameRuntime")
	assert(gameRuntime and not gameRuntime:FindFirstChild("ConveyorKeys"), "Runtime da esteira inválido")
	local offerFolder = Instance.new("Folder")
	offerFolder.Name = "ConveyorKeys"
	offerFolder.Parent = gameRuntime
	runtime = offerFolder
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	assert(remotes:IsA("Folder") and not remotes:FindFirstChild("ConveyorPurchaseResult"), "Remote da esteira duplicado")
	local event = Instance.new("RemoteEvent")
	event.Name = "ConveyorPurchaseResult"
	event.Parent = remotes
	feedback = event
	Players.PlayerRemoving:Connect(function(player) lastPurchase[player] = nil end)
	started = true
	local now = workspace:GetServerTimeNow()
	local nextSpawn = now + Config.SpawnInterval
	local lastUpdate = now
	spawnOffer(now)
	RunService.Heartbeat:Connect(function()
		local current = workspace:GetServerTimeNow()
		if current - lastUpdate < Config.UpdateInterval then return end
		lastUpdate = current
		for _, offer in pairs(offers) do
			if current - offer.bornAt >= duration or not offer.model.Parent then
				removeOffer(offer)
			else
				offer.model:PivotTo(CFrame.new(positionAt(offer, current)) * rotation)
			end
		end
		if current >= nextSpawn then
			nextSpawn = current + Config.SpawnInterval
			if count < Config.MaxOffers then spawnOffer(current) end
		end
	end)
	print("[ConveyorService] Pronto: esteira de chaves e compras ativadas.")
end

return ConveyorService
