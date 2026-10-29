--!strict
-- A propriedade das bases existe somente nas tabelas deste módulo.
-- Atributos e placas são uma projeção replicada para exibição.
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.BaseConfig)
local CharacterService = require(script.Parent.CharacterService)

type BaseRecord = {
	model: Model,
	id: number,
	spawn: SpawnLocation,
	owner: Player?,
	label: TextLabel?,
}

local BaseService = {}
local started = false
local random = Random.new()
local records: { BaseRecord } = {}
local byModel: { [Instance]: BaseRecord } = {}
local assigned: { [Player]: BaseRecord } = {}
local registered: { [Player]: boolean } = {}
local waiting: { Player } = {}
local waitingSpawn: SpawnLocation? = nil

local function createWaitingLabel(spawn: SpawnLocation, text: string): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "WaitingBaseLabel"
	gui.Adornee = spawn
	gui.Size = UDim2.fromOffset(Config.WaitingLabelSize.X, Config.WaitingLabelSize.Y)
	gui.StudsOffsetWorldSpace = Config.WaitingLabelOffset
	gui.MaxDistance = Config.WaitingLabelMaxDistance
	gui.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	label.BackgroundTransparency = 0.15
	label.TextColor3 = Color3.fromRGB(245, 245, 250)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 18
	label.TextWrapped = true
	label.RichText = false
	label.Text = text
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	gui.Parent = spawn
	return label
end

local function createOwnerLabel(model: Model): TextLabel?
	local folder = model:FindFirstChild(Config.OwnerSignFolderName)
	local sign = folder and folder:FindFirstChild(Config.OwnerSignPartName)
	if not sign or not sign:IsA("BasePart") then
		warn(("[BaseService] %s: placa BaseOwnerName.Name ausente"):format(model.Name))
		return nil
	end

	-- Remove somente a identificação flutuante antiga, inclusive em modelos copiados.
	for _, object in ipairs(model:GetDescendants()) do
		if object:IsA("BillboardGui") and object.Name == "BaseOwnerLabel" then
			object:Destroy()
		end
	end

	local existingGui = sign:FindFirstChild("BaseOwnerSign")
	local gui: SurfaceGui
	if existingGui and existingGui:IsA("SurfaceGui") then
		gui = existingGui
	else
		gui = Instance.new("SurfaceGui")
		gui.Name = "BaseOwnerSign"
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = Config.OwnerSignPixelsPerStud
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		gui.Parent = sign
	end
	gui.Adornee = sign
	gui.Face = Enum.NormalId.Front
	gui.MaxDistance = Config.OwnerSignMaxDistance

	local existingLabel = gui:FindFirstChild("OwnerName")
	if existingLabel and existingLabel:IsA("TextLabel") then return existingLabel end

	local label = Instance.new("TextLabel")
	label.Name = "OwnerName"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.94, 0.86)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(30, 25, 48)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.RichText = false
	label.Text = "Disponível"
	label.Parent = gui
	return label
end

local function reflectOwner(record: BaseRecord)
	local owner = record.owner
	record.model:SetAttribute("BaseId", record.id)
	record.model:SetAttribute("OwnerUserId", if owner then owner.UserId else 0)
	record.model:SetAttribute("OwnerName", if owner then owner.Name else "")
	record.model:SetAttribute("Occupied", owner ~= nil)

	if record.label then
		record.label.Text = if owner
			then ("%s\n@%s"):format(owner.DisplayName, owner.Name)
			else "Disponível"
	end
end

local function chooseFreeBase(): BaseRecord?
	local free: { BaseRecord } = {}
	for _, record in ipairs(records) do
		if record.owner == nil then
			table.insert(free, record)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[random:NextInteger(1, #free)]
end

local function reserve(player: Player, record: BaseRecord)
	assert(record.owner == nil and assigned[player] == nil, "Tentativa de atribuição duplicada")
	-- Reserva completa sem yield; carregar personagem é uma etapa posterior.
	record.owner = player
	assigned[player] = record
	reflectOwner(record)
	player:SetAttribute("BaseName", record.model.Name)
	player:SetAttribute("BaseStatus", "Assigned")
end

local function fillVacancies()
	while #waiting > 0 do
		local record = chooseFreeBase()
		if not record then
			return
		end
		local player = table.remove(waiting, 1)
		if registered[player] and player.Parent == Players then
			reserve(player, record)
			CharacterService.SetSpawn(player, record.spawn)
		end
	end
end

local function onPlayerAdded(player: Player)
	if registered[player] or player.Parent ~= Players then
		return
	end
	registered[player] = true
	player:SetAttribute("BaseName", "")
	player:SetAttribute("BaseStatus", "Waiting")

	local record = chooseFreeBase()
	local spawn = waitingSpawn
	if record then
		reserve(player, record)
		spawn = record.spawn
	else
		table.insert(waiting, player)
	end
	assert(spawn, "Spawn de espera não inicializado")
	CharacterService.AddPlayer(player, spawn)
end

local function onPlayerRemoving(player: Player)
	if not registered[player] then
		return
	end
	registered[player] = nil
	CharacterService.RemovePlayer(player)
	for index = #waiting, 1, -1 do
		if waiting[index] == player then
			table.remove(waiting, index)
		end
	end

	local record = assigned[player]
	assigned[player] = nil
	if record then
		record.owner = nil
		reflectOwner(record)
	end
	player:SetAttribute("BaseName", "")
	player:SetAttribute("BaseStatus", "Leaving")
	fillVacancies()
end

function BaseService.GetBase(player: Player): Model?
	local record = assigned[player]
	return if record then record.model else nil
end

function BaseService.GetOwner(base: Instance): Player?
	local record = byModel[base]
	return if record then record.owner else nil
end

function BaseService.IsOwner(player: Player, base: Instance): boolean
	local record = assigned[player]
	return record ~= nil and record.model == base
end

function BaseService.Start()
	assert(not started, "BaseService.Start já foi chamado")
	local folder = workspace:FindFirstChild(Config.BasesFolderName)
	assert(folder and folder:IsA("Folder"), "Workspace.Bases precisa ser uma Folder")
	assert(not workspace:FindFirstChild(Config.RuntimeFolderName), "GameRuntime já existe; confira a inicialização duplicada")

	-- Valida todas as bases antes de alterar o estado do mundo.
	local ids: { [number]: boolean } = {}
	for _, model in ipairs(folder:GetChildren()) do
		local suffix = model.Name:match("^Base(%d+)$")
		assert(model:IsA("Model") and suffix, "Cada filho de Bases deve ser um Model chamado Base1, Base2, etc.")
		local id = tonumber(suffix)
		assert(id and id > 0 and not ids[id], "Número de base inválido ou duplicado")
		ids[id] = true
		local spawn = model:FindFirstChild(Config.SpawnName)
		assert(spawn and spawn:IsA("SpawnLocation"), model.Name .. " precisa de um SpawnLocation chamado Spawn")
		local record: BaseRecord = { model = model, id = id, spawn = spawn, owner = nil, label = nil }
		table.insert(records, record)
	end
	assert(#records > 0, "Nenhuma base disponível no mapa")
	table.sort(records, function(a, b)
		return a.id < b.id
	end)

	started = true
	local runtime = Instance.new("Folder")
	runtime.Name = Config.RuntimeFolderName
	runtime.Parent = workspace

	local lobby = Instance.new("SpawnLocation")
	lobby.Name = "WaitingSpawn"
	lobby.Size = Config.WaitingSpawnSize
	lobby.CFrame = Config.WaitingSpawnCFrame
	lobby.Anchored = true
	lobby.Transparency = 1
	lobby.CanCollide = false
	lobby.CanTouch = false
	lobby.CanQuery = false
	lobby.Neutral = true
	lobby.Enabled = true
	lobby.AllowTeamChangeOnTouch = false
	lobby.Duration = 0
	lobby.Parent = runtime
	waitingSpawn = lobby
	createWaitingLabel(lobby, "Aguardando uma base livre")

	for _, record in ipairs(records) do
		record.spawn.Enabled = true
		record.spawn.Neutral = true
		record.spawn.AllowTeamChangeOnTouch = false
		record.label = createOwnerLabel(record.model)
		byModel[record.model] = record
		reflectOwner(record)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	print(("[BaseService] Pronto: %d bases registradas."):format(#records))
end

return BaseService
