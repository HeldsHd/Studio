--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(script.Parent.Parent.Config.EconomyConfig)

type PassState = { owned: boolean }
local GamePassService = {}
local states: { [Player]: PassState } = {}
local started = false
local passId = 0
local retryDelays = { 0, 5, 15 }

local function isCurrent(player: Player, state: PassState): boolean
	return states[player] == state and player.Parent == Players
end

local function grant(player: Player, state: PassState)
	if not isCurrent(player, state) then return end
	state.owned = true
	player:SetAttribute("AutoCollectEnabled", true)
end

local function checkOwnership(player: Player, state: PassState)
	for attempt, delaySeconds in ipairs(retryDelays) do
		if delaySeconds > 0 then task.wait(delaySeconds) end
		if not isCurrent(player, state) or state.owned then return end
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		-- Uma resposta tardia não revoga compra recebida nem alcança outra sessão.
		if not isCurrent(player, state) or state.owned then return end
		if ok then
			if result == true then grant(player, state) end
			return
		end
		if attempt == #retryDelays then
			warn(("[GamePassService] Falha ao consultar coleta automática de %s: %s")
				:format(player.Name, tostring(result)))
		end
	end
end

local function addPlayer(player: Player)
	if player.Parent ~= Players or states[player] then return end
	local state: PassState = { owned = false }
	states[player] = state
	player:SetAttribute("AutoCollectEnabled", false) -- Projeção, não autoridade.
	if passId > 0 then task.spawn(checkOwnership, player, state) end
end

function GamePassService.HasAutoCollect(player: Player): boolean
	local state = states[player]
	return state ~= nil and isCurrent(player, state) and state.owned
end

function GamePassService.Start()
	assert(not started, "GamePassService já iniciado")
	local configuredId = Config.AutoCollectGamePassId
	assert(type(configuredId) == "number" and configuredId >= 0
		and configuredId <= 9_007_199_254_740_991 and configuredId % 1 == 0,
		"AutoCollectGamePassId inválido")
	passId = configuredId
	started = true
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedId, wasPurchased)
		if passId == 0 or purchasedId ~= passId or not wasPurchased then return end
		local state = states[player]
		if state then grant(player, state) end
	end)
	for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
	print(if passId > 0
		then "[GamePassService] Pronto: coleta automática vinculada à gamepass."
		else "[GamePassService] Coleta automática desativada: gamepass ainda não configurada.")
end

return GamePassService
