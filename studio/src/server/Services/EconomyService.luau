--!strict
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.EconomyConfig)

type Account = { balance: number, income: number }
local EconomyService = {}
local accounts: { [Player]: Account } = {}
local started = false

local function validAmount(value: number): boolean
	return value == value and value >= 0 and value <= Config.MaxBalance and value % 1 == 0
end

local function publish(player: Player, account: Account)
	player:SetAttribute("Money", account.balance)
	player:SetAttribute("IncomePerSecond", account.income)
end

local function addPlayer(player: Player)
	if player.Parent ~= Players or accounts[player] then return end
	local account: Account = { balance = Config.StartingMoney, income = 0 }
	accounts[player] = account
	player:SetAttribute("PendingMoney", 0)
	publish(player, account)
end

-- Taxa apenas para exibição. A renda acumula por slot no SlotIncomeService.
function EconomyService.SetIncomeRate(player: Player, income: number): boolean
	assert(validAmount(income), "Renda inválida")
	local account = accounts[player]
	if not account or player.Parent ~= Players then return false end
	account.income = income
	publish(player, account)
	return true
end

-- Retorna quanto entrou na carteira; o chamador conserva qualquer excedente.
-- Nenhum yield entre verificar o saldo e creditá-lo.
function EconomyService.Credit(player: Player, amount: number): number
	assert(validAmount(amount), "Crédito inválido")
	local account = accounts[player]
	if not account or player.Parent ~= Players then return 0 end
	local credited = math.min(amount, Config.MaxBalance - account.balance)
	account.balance += credited
	publish(player, account)
	return credited
end

-- Débito validado no servidor, sem yield entre conferir e descontar.
function EconomyService.TrySpend(player: Player, amount: number): boolean
	assert(validAmount(amount), "Valor de compra inválido")
	local account = accounts[player]
	if not account or player.Parent ~= Players or account.balance < amount then return false end
	account.balance -= amount
	publish(player, account)
	return true
end

function EconomyService.GetBalance(player: Player): number?
	local account = accounts[player]
	return if account and player.Parent == Players then account.balance else nil
end

function EconomyService.Start()
	assert(not started, "EconomyService já iniciado")
	assert(Config.MaxBalance > 0 and Config.MaxBalance <= 9_007_199_254_740_991
		and Config.MaxBalance % 1 == 0, "Limite de saldo inválido")
	assert(validAmount(Config.StartingMoney), "Dinheiro inicial inválido")
	started = true
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player) accounts[player] = nil end)
	for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
	print("[EconomyService] Pronto: carteira sem pagamentos automáticos.")
end

return EconomyService
