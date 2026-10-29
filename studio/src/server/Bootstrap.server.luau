--!strict
-- Ponto único de inicialização. Adicionar sistemas aqui conforme forem validados.
local Players = game:GetService("Players")
local previousAutoLoads = Players.CharacterAutoLoads

-- A base e o RespawnLocation precisam ser definidos antes do primeiro personagem.
Players.CharacterAutoLoads = false

local ok, message = xpcall(function()
	local BaseService = require(script.Parent.Services.BaseService)
	local InventoryService = require(script.Parent.Services.InventoryService)
	local SlotService = require(script.Parent.Services.SlotService)
	local EconomyService = require(script.Parent.Services.EconomyService)
	local GamePassService = require(script.Parent.Services.GamePassService)
	local SlotIncomeService = require(script.Parent.Services.SlotIncomeService)
	EconomyService.Start()
	GamePassService.Start()
	SlotIncomeService.Start()
	InventoryService.Start()
	SlotService.Start()
	local ChestService = require(script.Parent.Services.ChestService)
	ChestService.Start()
	BaseService.Start()
	local ConveyorService = require(script.Parent.Services.ConveyorService)
	ConveyorService.Start()
end, debug.traceback)

if not ok then
	Players.CharacterAutoLoads = previousAutoLoads
	error("[Bootstrap] Falha na inicialização:\n" .. tostring(message))
end
