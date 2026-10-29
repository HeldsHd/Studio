--!strict
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Parent.Config.ChestConfig)
local EconomyConfig = require(script.Parent.Parent.Config.EconomyConfig)
local ItemConfig = require(script.Parent.Parent.Config.ItemConfig)
local BaseService = require(script.Parent.BaseService)
local EconomyService = require(script.Parent.EconomyService)
local ItemMetadata = require(script.Parent.ItemMetadata)
local ChestVisuals = require(script.Parent.ChestVisuals)

type Chest = {
	uid: string, chestId: string, owner: Player,
	metadata: ItemMetadata.Metadata, model: Model,
}
type Spot = {
	base: Model, marker: BasePart, container: Folder,
	prompt: ProximityPrompt, upgradePrompts: { [string]: ProximityPrompt },
	label: TextLabel, chest: Chest?,
}
local ChestService = {}
local spots: { Spot } = {}
local lastInteraction: { [Player]: number } = {}
local feedback: RemoteEvent? = nil
local started = false

local function send(player: Player, success: boolean, message: string)
	if feedback and player.Parent == Players then feedback:FireClient(player, success, message) end
end

local function setAvailable(prompt: ProximityPrompt, available: boolean)
	prompt.Enabled = available
	prompt:SetAttribute("ActionAvailable", available)
end

local function refresh(spot: Spot)
	local chest = spot.chest
	local starting = Config.Chests[Config.StartingChestId]
	-- Atributos são projeções. Compras, melhorias e futuras aberturas usam o registro privado.
	spot.marker:SetAttribute("ChestOccupied", chest ~= nil)
	spot.marker:SetAttribute("ChestUid", if chest then chest.uid else "")
	spot.marker:SetAttribute("ChestId", if chest then chest.chestId else "")
	spot.prompt.ActionText = ("Comprar · $%d"):format(starting.Price)
	spot.prompt.ObjectText = starting.Name
	setAvailable(spot.prompt, chest == nil)
	for fromId, prompt in pairs(spot.upgradePrompts) do
		setAvailable(prompt, chest ~= nil and chest.chestId == fromId)
	end
	if not chest then
		spot.label.Text = ("%s\n$%d"):format(starting.Name, starting.Price)
	else
		local definition = Config.Chests[chest.chestId]
		spot.label.Text = if definition.NextChestId
			then ("%s\nMelhorar: $%d"):format(definition.Name, definition.UpgradePrice)
			else definition.Name .. "\nRaridade máxima"
	end
end

local function clear(spot: Spot)
	local chest = spot.chest
	spot.chest = nil
	if chest then chest.model:Destroy() end
	refresh(spot)
end

local function canInteract(player: Player, spot: Spot): boolean
	if player.Parent ~= Players or not BaseService.IsOwner(player, spot.base) then return false end
	local now = os.clock()
	if now - (lastInteraction[player] or -math.huge) < Config.InteractionCooldown then return false end
	lastInteraction[player] = now
	if not spot.marker:IsDescendantOf(spot.base) or not spot.base:IsDescendantOf(workspace) then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	if (root.Position - spot.marker.Position).Magnitude > Config.InteractionDistance then
		send(player, false, "Aproxime-se do espaço do baú.")
		return false
	end
	return true
end

local function purchase(player: Player, spot: Spot)
	if not canInteract(player, spot) then return end
	if spot.chest then
		send(player, false, "Este espaço já tem um baú.")
		return
	end

	local chestId = Config.StartingChestId
	local definition = Config.Chests[chestId]
	local balance = EconomyService.GetBalance(player)
	if not balance or balance < definition.Price then
		send(player, false, ("Saldo insuficiente. O baú custa $%d."):format(definition.Price))
		return
	end

	-- Prepara tudo antes do débito; nenhuma etapa da transação cede execução.
	local display: Model? = nil
	local prepared, result = pcall(function(): Chest
		local metadata = ItemMetadata.Normalize(definition.Metadata)
		local uid = HttpService:GenerateGUID(false)
		local model = ChestVisuals.CreateDisplay(chestId, spot.marker)
		display = model
		model:SetAttribute("ChestUid", uid)
		model:SetAttribute("ChestId", chestId)
		model:SetAttribute("OwnerUserId", player.UserId)
		ItemMetadata.ApplyAttributes(model, metadata)
		return { uid = uid, chestId = chestId, owner = player, metadata = metadata, model = model }
	end)
	if not prepared then
		if display then display:Destroy() end
		warn("[ChestService] Falha ao preparar baú: " .. tostring(result))
		send(player, false, "Não foi possível preparar o baú. Nada foi cobrado.")
		return
	end
	local chest: Chest = result
	if not EconomyService.TrySpend(player, definition.Price) then
		chest.model:Destroy()
		send(player, false, "Saldo insuficiente para comprar o baú.")
		return
	end

	local committed, message = pcall(function()
		spot.chest = chest
		chest.model.Parent = spot.container
		refresh(spot)
	end)
	if not committed then
		spot.chest = nil
		chest.model:Destroy()
		EconomyService.Credit(player, definition.Price)
		warn("[ChestService] Compra revertida: " .. tostring(message))
		pcall(refresh, spot)
		send(player, false, "A compra falhou. O valor foi devolvido.")
		return
	end
	send(player, true, ("Comprou %s por $%d."):format(definition.Name, definition.Price))
end

-- Cada prompt representa uma única passagem de raridade. Um evento atrasado do
-- prompt de Comum não consegue comprar também o upgrade de Prata.
local function upgrade(player: Player, spot: Spot, fromId: string)
	if not canInteract(player, spot) then return end
	local chest = spot.chest
	if not chest or chest.owner ~= player or chest.chestId ~= fromId then return end
	local definition = Config.Chests[fromId]
	local nextId = definition.NextChestId
	if not nextId then return end
	local nextDefinition = Config.Chests[nextId]
	local price = definition.UpgradePrice
	local balance = EconomyService.GetBalance(player)
	if not balance or balance < price then
		send(player, false, ("Saldo insuficiente. A melhoria custa $%d."):format(price))
		return
	end

	local replacement: Model? = nil
	local prepared, result = pcall(function(): Model
		local model = ChestVisuals.CreateDisplay(nextId, spot.marker)
		replacement = model
		model:SetAttribute("ChestUid", chest.uid)
		model:SetAttribute("ChestId", nextId)
		model:SetAttribute("OwnerUserId", chest.owner.UserId)
		ItemMetadata.ApplyAttributes(model, chest.metadata)
		return model
	end)
	if not prepared then
		if replacement then replacement:Destroy() end
		warn("[ChestService] Falha ao preparar melhoria: " .. tostring(result))
		send(player, false, "Não foi possível preparar a melhoria. Nada foi cobrado.")
		return
	end
	local newModel: Model = result
	if not EconomyService.TrySpend(player, price) then
		newModel:Destroy()
		send(player, false, "Saldo insuficiente para melhorar o baú.")
		return
	end

	-- Mantém UID, dono e a mesma tabela de metadados. Guarda o visual antigo
	-- até concluir a transação inteira, sem yield entre débito e confirmação.
	local oldModel = chest.model
	local committed, message = pcall(function()
		newModel.Parent = spot.container
		chest.chestId = nextId
		chest.model = newModel
		refresh(spot)
	end)
	if not committed then
		chest.chestId = fromId
		chest.model = oldModel
		newModel:Destroy()
		EconomyService.Credit(player, price)
		pcall(refresh, spot)
		warn("[ChestService] Melhoria revertida: " .. tostring(message))
		send(player, false, "A melhoria falhou. O valor foi devolvido.")
		return
	end
	oldModel:Destroy()
	send(player, true, ("Melhorou para %s por $%d."):format(nextDefinition.Name, price))
end

local function createLabel(marker: BasePart, baseName: string): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "ChestLabel"
	gui.Adornee = marker
	gui.Size = UDim2.fromOffset(160, 46)
	gui.StudsOffsetWorldSpace = Config.LabelOffset
	gui.MaxDistance = 35
	gui.AlwaysOnTop = false
	gui:SetAttribute("IsChestLabel", true)
	gui:SetAttribute("BaseName", baseName)
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(28, 25, 35)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(255, 242, 213)
	label.TextSize = 16
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.RichText = false
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	gui.Parent = marker
	return label
end

function ChestService.Start()
	assert(not started, "ChestService já iniciado")
	local starting = Config.Chests[Config.StartingChestId]
	assert(starting and starting.Price > 0 and starting.Price <= EconomyConfig.MaxBalance
		and starting.Price % 1 == 0, "Preço do baú inválido")
	assert(Config.InteractionDistance > 0 and Config.InteractionDistance < math.huge
		and Config.InteractionCooldown >= 0 and Config.InteractionCooldown < math.huge
		and Config.HoldDuration >= 0 and Config.HoldDuration < math.huge
		and Config.UpgradeHoldDuration > 0 and Config.UpgradeHoldDuration < math.huge
		and math.abs(Config.SurfaceOffset) < math.huge, "Configuração de interação inválida")
	for id, definition in pairs(Config.Chests) do
		assert(definition.DisplayScale > 0 and definition.DisplayScale < math.huge
			and math.abs(definition.DisplayYawDegrees) < math.huge, id .. ": escala/rotação inválida")
		local key = ItemConfig.Items[definition.KeyId]
		assert(key and key.Kind == "Key", id .. ": chave correspondente inválida")
		ChestVisuals.GetTemplate(id)
		if definition.NextChestId then
			assert(Config.Chests[definition.NextChestId], id .. ": próxima raridade ausente")
			local price = definition.UpgradePrice
			assert(type(price) == "number" and price > 0 and price <= EconomyConfig.MaxBalance
				and price % 1 == 0, id .. ": custo de melhoria inválido")
		else
			assert(definition.UpgradePrice == nil, id .. ": custo sem próxima raridade")
		end
	end
	local seen: { [string]: boolean } = {}
	local nextId: string? = Config.StartingChestId
	while nextId do
		assert(not seen[nextId], "Ciclo na sequência de upgrades dos baús")
		seen[nextId] = true
		nextId = Config.Chests[nextId].NextChestId
	end
	for id in pairs(Config.Chests) do assert(seen[id], id .. ": baú fora da sequência de upgrades") end
	ItemMetadata.Normalize(starting.Metadata)

	-- Confere toda a construção antes de criar prompts.
	local pending: { { base: Model, markers: { BasePart } } } = {}
	local bases = workspace:FindFirstChild("Bases")
	assert(bases, "Pasta Bases ausente")
	for _, base in ipairs(bases:GetChildren()) do
		assert(base:IsA("Model"), "Base precisa ser Model")
		local balcony = base:FindFirstChild(Config.BalconyName)
		local positions = balcony and balcony:FindFirstChild(Config.PositionsName)
		assert(positions, base.Name .. ": ChestPosition ausente")
		assert(not base:FindFirstChild(Config.RuntimeFolderName), "ChestDisplays duplicado")
		local markers: { BasePart } = {}
		for _, name in ipairs(Config.PositionNames) do
			local marker = positions:FindFirstChild(name)
			assert(marker and marker:IsA("BasePart") and marker.Anchored,
				base.Name .. ": marcador de baú ausente ou desancorado: " .. name)
			assert(not marker:FindFirstChild("BuyChest") and not marker:FindFirstChild("ChestLabel"),
				"Interação de baú duplicada")
			table.insert(markers, marker)
		end
		table.insert(pending, { base = base, markers = markers })
	end
	assert(#pending > 0, "Nenhuma base para registrar baús")

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	assert(remotes:IsA("Folder") and not remotes:FindFirstChild("ChestPurchaseResult"),
		"Remote de baús inválido/duplicado")
	local event = Instance.new("RemoteEvent")
	event.Name = "ChestPurchaseResult"
	event.Parent = remotes
	feedback = event
	started = true
	for _, entry in ipairs(pending) do
		local container = Instance.new("Folder")
		container.Name = Config.RuntimeFolderName
		container.Parent = entry.base
		for _, marker in ipairs(entry.markers) do
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuyChest"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.HoldDuration = Config.HoldDuration
			prompt.MaxActivationDistance = Config.InteractionDistance
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("BaseName", entry.base.Name)
			prompt:SetAttribute("IsChestPrompt", true)
			local spot: Spot = {
				base = entry.base, marker = marker, container = container,
				prompt = prompt, upgradePrompts = {}, label = createLabel(marker, entry.base.Name),
			}
			for fromId, definition in pairs(Config.Chests) do
				if definition.NextChestId then
					local nextDefinition = Config.Chests[definition.NextChestId]
					local upgradePrompt = Instance.new("ProximityPrompt")
					upgradePrompt.Name = "UpgradeChest_" .. fromId
					upgradePrompt.KeyboardKeyCode = Enum.KeyCode.F
					upgradePrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
					upgradePrompt.HoldDuration = Config.UpgradeHoldDuration
					upgradePrompt.MaxActivationDistance = Config.InteractionDistance
					upgradePrompt.RequiresLineOfSight = false
					upgradePrompt.ActionText = ("Melhorar para %s · $%d"):format(nextDefinition.Name, definition.UpgradePrice)
					upgradePrompt.ObjectText = definition.Name
					upgradePrompt:SetAttribute("BaseName", entry.base.Name)
					upgradePrompt:SetAttribute("IsChestPrompt", true)
					upgradePrompt:SetAttribute("UpgradeFromChestId", fromId)
					spot.upgradePrompts[fromId] = upgradePrompt
					setAvailable(upgradePrompt, false)
					upgradePrompt.Triggered:Connect(function(player) upgrade(player, spot, fromId) end)
					upgradePrompt.Parent = marker
				end
			end
			table.insert(spots, spot)
			refresh(spot)
			prompt.Triggered:Connect(function(player) purchase(player, spot) end)
			prompt.Parent = marker
		end
	end
	-- Start deve ocorrer antes de BaseService.Start, limpando antes da reatribuição.
	Players.PlayerRemoving:Connect(function(player)
		lastInteraction[player] = nil
		for _, spot in ipairs(spots) do
			if spot.chest and spot.chest.owner == player then clear(spot) end
		end
	end)
	print(("[ChestService] Pronto: %d espaços de baús registrados."):format(#spots))
end

return ChestService
