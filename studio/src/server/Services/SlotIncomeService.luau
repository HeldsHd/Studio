--!strict
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.EconomyConfig)
local ItemConfig = require(script.Parent.Parent.Config.ItemConfig)
local BaseService = require(script.Parent.BaseService)
local EconomyService = require(script.Parent.EconomyService)
local GamePassService = require(script.Parent.GamePassService)
local Visuals = require(script.Parent.CollectionPadVisuals)

type Source = {
	base: Model, folder: Instance, pad: Visuals.Pad,
	owner: Player?, rate: number, pending: number, updatedAt: number,
}
local SlotIncomeService = {}
local sources: { [Instance]: Source } = {}
local started = false

local function owns(source: Source, player: Player): boolean
	return source.owner == player and player.Parent == Players and BaseService.IsOwner(player, source.base)
end

local function settle(source: Source, now: number)
	local elapsed = math.max(0, now - source.updatedAt)
	source.updatedAt = now
	local owner = source.owner
	if owner and owns(source, owner) then
		source.pending = math.min(Config.MaxBalance, source.pending + elapsed * source.rate)
	end
end

local function reflect(source: Source)
	local amount = math.floor(source.pending)
	source.folder:SetAttribute("StoredMoney", amount)
	Visuals.SetState(source.pad, source.rate > 0 or amount > 0, amount)
end

local function publishPlayer(player: Player)
	if player.Parent ~= Players then return end
	local rate, pending = 0, 0
	for _, source in pairs(sources) do
		if owns(source, player) then
			rate += source.rate
			pending += math.floor(source.pending)
		end
	end
	EconomyService.SetIncomeRate(player, rate)
	player:SetAttribute("PendingMoney", pending)
end

local function collect(source: Source, player: Player)
	if not owns(source, player) then return end
	local amount = math.floor(source.pending)
	if amount <= 0 then return end
	-- Debita apenas o crédito efetivo, sem yield: toque repetido/auto não duplica.
	local credited = EconomyService.Credit(player, amount)
	source.pending -= credited
end

local function tryManualCollect(source: Source)
	local owner = source.owner
	if not owner or not owns(source, owner) or not Visuals.IsStandingOn(owner, source.pad) then return end
	settle(source, os.clock())
	collect(source, owner)
	reflect(source)
	publishPlayer(owner)
end

function SlotIncomeService.Register(base: Model, folder: Instance, pedestal: BasePart)
	assert(started and not sources[folder], "Registro de coleta inválido")
	local spawn = base:FindFirstChild("Spawn")
	assert(spawn and spawn:IsA("BasePart"), base.Name .. ": Spawn ausente")
	local source: Source = {
		base = base, folder = folder, pad = Visuals.Create(folder, pedestal, spawn),
		owner = nil, rate = 0, pending = 0, updatedAt = os.clock(),
	}
	sources[folder] = source
	reflect(source)
	source.pad.touchPart.Touched:Connect(function(hit)
		local owner = source.owner
		local character = owner and owner.Character
		if character and hit:IsDescendantOf(character) then tryManualCollect(source) end
	end)
end

function SlotIncomeService.SetItem(folder: Instance, player: Player?, itemId: string?)
	local source = sources[folder]
	assert(source, "Slot sem registro de coleta")
	local previousOwner = source.owner
	settle(source, os.clock())
	if itemId then
		assert(player and player.Parent == Players and BaseService.IsOwner(player, source.base),
			"Dono inválido para renda")
		local item = ItemConfig.Items[itemId]
		assert(item, "Item de renda desconhecido")
		if source.owner ~= player then source.pending = 0 end
		source.owner = player
		source.rate = if item.Kind == "Weapon" then item.IncomePerSecond else 0
	else
		-- Retirar uma arma para a produção; o valor anterior continua para coleta.
		source.rate = 0
	end
	reflect(source)
	if previousOwner then publishPlayer(previousOwner) end
	if player and player ~= previousOwner then publishPlayer(player) end
end

function SlotIncomeService.Start()
	assert(not started, "SlotIncomeService já iniciado")
	assert(Config.PayoutInterval > 0 and Config.PayoutInterval < math.huge, "Intervalo de coleta inválido")
	started = true
	Players.PlayerRemoving:Connect(function(player)
		for _, source in pairs(sources) do
			if source.owner == player then
				source.owner = nil
				source.rate = 0
				source.pending = 0
				source.updatedAt = os.clock()
				reflect(source)
			end
		end
	end)
	task.spawn(function()
		while started do
			task.wait(Config.PayoutInterval)
			local now = os.clock()
			for _, source in pairs(sources) do
				settle(source, now)
				local owner = source.owner
				if owner and owns(source, owner) then
					if GamePassService.HasAutoCollect(owner) or Visuals.IsStandingOn(owner, source.pad) then
						collect(source, owner)
					end
				end
				reflect(source)
			end
			for _, player in ipairs(Players:GetPlayers()) do publishPlayer(player) end
		end
	end)
	print("[SlotIncomeService] Pronto: dinheiro acumulado por slot e coleta pelo dono.")
end

return SlotIncomeService
