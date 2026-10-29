--!strict
-- Inventário de sessão autoritativo. Tools e atributos são apenas sua representação.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Parent.Config.ItemConfig)
local CharacterService = require(script.Parent.CharacterService)
local ItemVisuals = require(script.Parent.ItemVisuals)
local ItemMetadata = require(script.Parent.ItemMetadata)
local EconomyService = require(script.Parent.EconomyService)
local EconomyConfig = require(script.Parent.Parent.Config.EconomyConfig)

type Item = { uid: string, itemId: string, metadata: ItemMetadata.Metadata, slot: Instance?, tool: Tool? }
type Inventory = { items: { [string]: Item }, seeded: boolean }
local inventories: { [Player]: Inventory } = {}
local InventoryService = {}
local started = false

local function ensure(player: Player): Inventory
	local inventory = inventories[player]
	if not inventory then
		inventory = { items = {}, seeded = false }
		inventories[player] = inventory
	end
	return inventory
end

local function makeTool(item: Item): Tool
	local tool = ItemVisuals.CreateTool(item.itemId, item.metadata)
	tool:SetAttribute("ItemUid", item.uid)
	return tool
end

function InventoryService.Grant(player: Player, itemId: string, metadataInput: ItemMetadata.Input?): string
	assert(player.Parent == Players and Config.Items[itemId], "Jogador ou item inválido")
	local inventory = ensure(player)
	local item: Item = {
		uid = HttpService:GenerateGUID(false), itemId = itemId,
		metadata = ItemMetadata.Normalize(metadataInput), slot = nil, tool = nil,
	}
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		item.tool = makeTool(item)
	end
	inventory.items[item.uid] = item
	if item.tool and backpack then
		item.tool.Parent = backpack
	end
	return item.uid
end

-- Preço vem da oferta privada do servidor. Nenhuma etapa cede execução.
function InventoryService.TryPurchase(player: Player, itemId: string, price: number, metadataInput: ItemMetadata.Input?): (boolean, string?)
	if player.Parent ~= Players or not Config.Items[itemId] then return false, "Item indisponível." end
	if type(price) ~= "number" or price ~= price or price < 0
		or price > EconomyConfig.MaxBalance or price % 1 ~= 0 then
		return false, "Preço inválido."
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not humanoid or humanoid.Health <= 0 or not backpack then
		return false, "Aguarde seu personagem carregar."
	end
	local validMetadata, normalizedMetadata = pcall(ItemMetadata.Normalize, metadataInput)
	if not validMetadata then
		warn("[InventoryService] Metadados de compra inválidos: " .. tostring(normalizedMetadata))
		return false, "Características do item inválidas."
	end
	local balance = EconomyService.GetBalance(player)
	if balance == nil or balance < price then
		return false, "Dinheiro insuficiente. Colete o dinheiro dos slots."
	end
	local inventory = ensure(player)
	local item: Item = {
		uid = HttpService:GenerateGUID(false), itemId = itemId,
		metadata = normalizedMetadata :: ItemMetadata.Metadata, slot = nil, tool = nil,
	}
	-- Preparar o modelo antes do débito evita cobrar por um item que não pode ser criado.
	local prepared, result = pcall(makeTool, item)
	if not prepared then
		warn(("[InventoryService] Falha ao preparar %s: %s"):format(itemId, tostring(result)))
		return false, "Não foi possível preparar a chave."
	end
	local tool = result :: Tool
	item.tool = tool
	if not EconomyService.TrySpend(player, price) then
		tool:Destroy()
		return false, "Dinheiro insuficiente."
	end
	inventory.items[item.uid] = item
	local delivered, deliveryError = pcall(function() tool.Parent = backpack end)
	if not delivered then
		inventory.items[item.uid] = nil
		tool:Destroy()
		EconomyService.Credit(player, price)
		warn(("[InventoryService] Falha ao entregar %s: %s"):format(itemId, tostring(deliveryError)))
		return false, "Não foi possível entregar a chave."
	end
	return true, item.uid
end

function InventoryService.GetEquipped(player: Player): Item?
	local inventory = inventories[player]
	local character = player.Character
	if inventory and character then
		for _, item in pairs(inventory.items) do
			if not item.slot and item.tool and item.tool.Parent == character then
				return item
			end
		end
	end
	return nil
end

function InventoryService.Place(player: Player, uid: string, slot: Instance): boolean
	local inventory = inventories[player]
	local item = inventory and inventory.items[uid]
	if not item or item.slot or not item.tool or not player.Character or item.tool.Parent ~= player.Character then
		return false
	end
	local tool = item.tool
	item.slot = slot
	item.tool = nil
	tool:Destroy()
	return true
end

function InventoryService.Take(player: Player, uid: string, slot: Instance): boolean
	local inventory = inventories[player]
	local item = inventory and inventory.items[uid]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not item or item.slot ~= slot or not backpack then
		return false
	end
	-- Prepara o visual antes de confirmar a transferência; não há yield.
	local tool = makeTool(item)
	item.slot = nil
	item.tool = tool
	tool.Parent = backpack
	return true
end

local function onCharacterReady(player: Player)
	if player.Parent ~= Players then
		return
	end
	local inventory = ensure(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		warn("[InventoryService] Mochila indisponível para " .. player.Name)
		return
	end
	-- LoadCharacterAsync limpa a mochila. Restaurar somente após finalizar o carregamento.
	for _, item in pairs(inventory.items) do
		if item.tool then
			item.tool:Destroy()
			item.tool = nil
		end
		if not item.slot then
			item.tool = makeTool(item)
			item.tool.Parent = backpack
		end
	end
	if not inventory.seeded then
		inventory.seeded = true
		if RunService:IsStudio() then
			for _, itemId in ipairs(Config.StudioTestItems) do
				InventoryService.Grant(player, itemId)
			end
		end
	end
end

function InventoryService.Start()
	assert(not started, "InventoryService já iniciado")
	started = true
	CharacterService.CharacterReady:Connect(onCharacterReady)
	Players.PlayerRemoving:Connect(function(player)
		local inventory = inventories[player]
		inventories[player] = nil
		if inventory then
			for _, item in pairs(inventory.items) do
				if item.tool then item.tool:Destroy() end
			end
		end
	end)
end

return InventoryService
