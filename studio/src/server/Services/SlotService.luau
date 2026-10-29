--!strict
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.SlotConfig)
local ItemConfig = require(script.Parent.Parent.Config.ItemConfig)
local BaseService = require(script.Parent.BaseService)
local InventoryService = require(script.Parent.InventoryService)
local ItemVisuals = require(script.Parent.ItemVisuals)
local ItemMetadata = require(script.Parent.ItemMetadata)
local SlotIncomeService = require(script.Parent.SlotIncomeService)

type Slot = {
	base: Model, folder: Instance, pedestal: BasePart, prompt: ProximityPrompt,
	uid: string?, itemId: string?, owner: Player?, display: Model?, metadata: ItemMetadata.Metadata?,
}
local SlotService = {}
local slots: { Slot } = {}
local lastInteraction: { [Player]: number } = {}
local started = false

local function refresh(slot: Slot)
	slot.folder:SetAttribute("Occupied", slot.uid ~= nil)
	slot.folder:SetAttribute("ItemId", slot.itemId or "")
	slot.folder:SetAttribute("ItemUid", slot.uid or "")
	ItemMetadata.ApplyAttributes(slot.folder, slot.metadata)
	if slot.itemId then
		slot.prompt.ActionText = "Retirar"
		local item = ItemConfig.Items[slot.itemId]
		slot.prompt.ObjectText = if item.Kind == "Weapon"
			then ("%s · $%d/s"):format(item.Name, item.IncomePerSecond)
			else item.Name
	else
		slot.prompt.ActionText = "Colocar"
		slot.prompt.ObjectText = "Equipe uma arma ou chave"
	end
end

local function clear(slot: Slot)
	local previousOwner = slot.owner
	if slot.display then slot.display:Destroy() end
	slot.display = nil
	slot.uid = nil
	slot.itemId = nil
	slot.metadata = nil
	slot.owner = nil
	refresh(slot)
	SlotIncomeService.SetItem(slot.folder, previousOwner, nil)
end

local function interact(player: Player, slot: Slot)
	if player.Parent ~= Players or not BaseService.IsOwner(player, slot.base) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end
	if (root.Position - slot.pedestal.Position).Magnitude > Config.InteractionDistance then
		return
	end
	local now = os.clock()
	if now - (lastInteraction[player] or -math.huge) < Config.InteractionCooldown then
		return
	end
	lastInteraction[player] = now

	if slot.uid then
		if slot.owner == player and InventoryService.Take(player, slot.uid, slot.folder) then
			clear(slot)
		end
		return
	end

	local item = InventoryService.GetEquipped(player)
	if not item then return end
	local display = ItemVisuals.CreateDisplay(item.itemId, item.metadata)
	-- Apoia a parte inferior do modelo sobre o pedestal, inclusive na fileira girada.
	local bounds, size = display:GetBoundingBox()
	local centerHeight = slot.pedestal.Size.Y / 2 + Config.DisplayClearance + size.Y / 2
	local targetBounds = slot.pedestal.CFrame * CFrame.new(0, centerHeight, 0)
	display:PivotTo(targetBounds * bounds:Inverse() * display:GetPivot())
	if not InventoryService.Place(player, item.uid, slot.folder) then
		display:Destroy()
		return
	end
	slot.uid = item.uid
	slot.itemId = item.itemId
	slot.metadata = item.metadata
	slot.owner = player
	slot.display = display
	display.Parent = slot.folder
	refresh(slot)
	SlotIncomeService.SetItem(slot.folder, player, item.itemId)
end

function SlotService.Start()
	assert(not started, "SlotService já iniciado")
	for id, item in pairs(ItemConfig.Items) do
		local rate = item.IncomePerSecond
		assert(type(rate) == "number" and rate >= 0 and rate < math.huge and rate % 1 == 0,
			id .. ": renda inválida")
		assert(item.Kind == "Weapon" or rate == 0, id .. ": somente armas geram renda")
	end
	started = true
	for _, base in ipairs(workspace.Bases:GetChildren()) do
		assert(base:IsA("Model"), ("%s: precisa ser Model, mas é %s"):format(base.Name, base.ClassName))
		local folder = base:FindFirstChild(Config.SlotsFolderName)
		assert(folder, base.Name .. ": pasta " .. Config.SlotsFolderName .. " ausente")
		for _, slotFolder in ipairs(folder:GetChildren()) do
			local pedestal = slotFolder:FindFirstChild(Config.PedestalName)
			assert(pedestal and pedestal:IsA("BasePart"), slotFolder:GetFullName() .. ": pedestal ausente")
			assert(not pedestal:FindFirstChild("SlotPrompt"), "SlotPrompt duplicado")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SlotPrompt"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.MaxActivationDistance = Config.InteractionDistance
			prompt.HoldDuration = Config.HoldDuration
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("BaseName", base.Name)
			prompt:SetAttribute("IsSlotPrompt", true)
			local slot: Slot = { base = base, folder = slotFolder, pedestal = pedestal, prompt = prompt }
			SlotIncomeService.Register(base, slotFolder, pedestal)
			table.insert(slots, slot)
			refresh(slot)
			prompt.Triggered:Connect(function(player) interact(player, slot) end)
			prompt.Parent = pedestal
		end
	end
	-- Registrado antes do BaseService: limpa os itens antes de a base ser reutilizada.
	Players.PlayerRemoving:Connect(function(player)
		lastInteraction[player] = nil
		for _, slot in ipairs(slots) do
			if slot.owner == player then clear(slot) end
		end
	end)
	print(("[SlotService] Pronto: %d slots registrados."):format(#slots))
end

return SlotService
