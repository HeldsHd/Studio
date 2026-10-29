--!strict
-- Protótipo: preços e frequência precisam ser calibrados junto dos baús e da sorte.
return {
	FolderName = "treadmill",
	BeltName = "treadmill",
	StartName = "Start",
	FinishName = "Finish",
	SpawnInterval = 6,
	Speed = 8, -- studs por segundo
	UpdateInterval = 1 / 30, -- Atualização do servidor; o visual é animado por quadro no cliente.
	FloatAmplitude = 0.35,
	FloatPeriod = 2.5,
	SpinDegreesPerSecond = 45,
	MaxOffers = 8,
	InteractionDistance = 10,
	HoldDuration = 0.25,
	PurchaseCooldown = 0.4,
	-- Metadata vazio cria exemplares normais. Eventos/mutações ficam para o futuro.
	Offers = {
		{ ItemId = "DefaultKey", Price = 100, Weight = 70, Metadata = {} },
		{ ItemId = "SilverKey", Price = 400, Weight = 25, Metadata = {} },
		{ ItemId = "GoldKey", Price = 1500, Weight = 5, Metadata = {} },
	},
}
