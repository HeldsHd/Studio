--!strict
-- Valores do sistema de bases. A economia terá configurações próprias.
return table.freeze({
	BasesFolderName = "Bases",
	SpawnName = "Spawn",
	RuntimeFolderName = "GameRuntime",

	-- Ponto provisório no corredor para quem aguarda uma base livre.
	WaitingSpawnCFrame = CFrame.new(0, 0, 20),
	WaitingSpawnSize = Vector3.new(10, 1, 10),

	SpawnClearance = 0.5,
	CharacterReadyTimeout = 15,
	LoadRetryDelay = 5,

	OwnerSignFolderName = "BaseOwnerName",
	OwnerSignPartName = "Name",
	OwnerSignPixelsPerStud = 50,
	OwnerSignMaxDistance = 140,

	-- Identificação do ponto de espera; não é usada nas placas das bases.
	WaitingLabelSize = Vector2.new(250, 64),
	WaitingLabelOffset = Vector3.new(0, 9, 0),
	WaitingLabelMaxDistance = 140,
})
