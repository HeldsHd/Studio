--!strict
-- Único responsável por carregar personagens e executar respawns.
local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.Config.BaseConfig)

type CharacterState = {
	player: Player,
	spawn: SpawnLocation,
	character: Model?,
	connections: { RBXScriptConnection },
	deathConnection: RBXScriptConnection?,
	loading: boolean,
	pending: boolean,
	version: number,
	reloadAfterLoad: boolean,
}

local CharacterService = {}
local characterReady = Instance.new("BindableEvent")
CharacterService.CharacterReady = characterReady.Event
local states: { [Player]: CharacterState } = {}
local requestLoad: (CharacterState) -> ()

local function isCurrent(state: CharacterState): boolean
	return states[state.player] == state and state.player.Parent == Players
end

local function moveToSpawn(state: CharacterState): boolean
	local character = state.player.Character
	if not isCurrent(state) or not character or character ~= state.character then
		return false
	end
	if not character:IsDescendantOf(workspace) or not state.spawn:IsDescendantOf(workspace) then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Alinha o HumanoidRootPart, sem depender do pivot particular do rig.
	local legHeight = 0
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		if not leg or not leg:IsA("BasePart") then
			return false
		end
		legHeight = leg.Size.Y
	end
	local height = state.spawn.Size.Y / 2 + humanoid.HipHeight + legHeight + root.Size.Y / 2 + Config.SpawnClearance
	local target = state.spawn.CFrame * CFrame.new(0, height, 0)
	character:PivotTo(target * root.CFrame:Inverse() * character:GetPivot())
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function scheduleLoad(state: CharacterState, delaySeconds: number)
	if not isCurrent(state) or state.pending then
		return
	end
	state.pending = true
	state.version += 1
	local version = state.version

	task.delay(delaySeconds, function()
		if not isCurrent(state) or state.version ~= version then
			return
		end
		state.pending = false
		if state.loading then
			-- Não sobrepor duas chamadas de LoadCharacterAsync.
			state.reloadAfterLoad = true
			return
		end
		requestLoad(state)
	end)
end

local function bindCharacter(state: CharacterState, character: Model)
	if not isCurrent(state) or state.character == character then
		return
	end
	state.version += 1
	state.pending = false
	state.reloadAfterLoad = false
	state.character = character
	if state.deathConnection then
		state.deathConnection:Disconnect()
		state.deathConnection = nil
	end

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", Config.CharacterReadyTimeout)
		if not isCurrent(state) or state.character ~= character then
			return
		end
		if not humanoid or not humanoid:IsA("Humanoid") then
			warn(("[CharacterService] Humanoid ausente para %s."):format(state.player.Name))
			scheduleLoad(state, Config.LoadRetryDelay)
			return
		end

		state.deathConnection = humanoid.Died:Connect(function()
			if isCurrent(state) and state.character == character then
				scheduleLoad(state, Players.RespawnTime)
			end
		end)
		if humanoid.Health <= 0 then
			scheduleLoad(state, Players.RespawnTime)
		end
	end)
end

requestLoad = function(state: CharacterState)
	if not isCurrent(state) or state.loading then
		return
	end
	state.loading = true
	state.player.RespawnLocation = state.spawn

	task.spawn(function()
		if not isCurrent(state) then
			return
		end
		local ok, message = pcall(function()
			state.player:LoadCharacterAsync()
		end)
		if not isCurrent(state) then
			return
		end
		state.loading = false

		if not ok then
			warn(("[CharacterService] Falha ao carregar %s: %s"):format(state.player.Name, tostring(message)))
			scheduleLoad(state, Config.LoadRetryDelay)
			return
		end
		if state.reloadAfterLoad then
			state.reloadAfterLoad = false
			scheduleLoad(state, 0)
			return
		end

		local character = state.player.Character
		if character and state.character ~= character then
			bindCharacter(state, character)
		end
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			scheduleLoad(state, Players.RespawnTime)
		elseif not moveToSpawn(state) then
			warn(("[CharacterService] Personagem incompleto para %s; nova tentativa agendada."):format(state.player.Name))
			scheduleLoad(state, Config.LoadRetryDelay)
		else
			characterReady:Fire(state.player)
		end
	end)
end

function CharacterService.AddPlayer(player: Player, spawn: SpawnLocation)
	assert(not states[player], "Jogador já registrado no CharacterService")
	local state: CharacterState = {
		player = player,
		spawn = spawn,
		character = nil,
		connections = {},
		deathConnection = nil,
		loading = false,
		pending = false,
		version = 0,
		reloadAfterLoad = false,
	}
	states[player] = state
	player.RespawnLocation = spawn
	table.insert(state.connections, player.CharacterAdded:Connect(function(character)
		bindCharacter(state, character)
	end))
	table.insert(state.connections, player.CharacterRemoving:Connect(function(character)
		if not isCurrent(state) or state.character ~= character then
			return
		end
		state.character = nil
		if state.deathConnection then
			state.deathConnection:Disconnect()
			state.deathConnection = nil
		end
		if not state.loading then
			scheduleLoad(state, Players.RespawnTime)
		end
	end))
	-- Também cobre um jogador já presente quando o serviço inicializa.
	requestLoad(state)
end

function CharacterService.SetSpawn(player: Player, spawn: SpawnLocation)
	local state = states[player]
	if not state or not isCurrent(state) then
		return
	end
	state.spawn = spawn
	player.RespawnLocation = spawn
	task.defer(function()
		if isCurrent(state) and not state.loading then
			moveToSpawn(state)
		end
	end)
end

function CharacterService.RemovePlayer(player: Player)
	local state = states[player]
	if not state then
		return
	end
	states[player] = nil -- Invalida callbacks e tarefas antes de desconectar.
	state.version += 1
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	if state.deathConnection then
		state.deathConnection:Disconnect()
	end
	player.RespawnLocation = nil
end

return CharacterService
