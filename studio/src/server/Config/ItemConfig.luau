--!strict
-- Renda por segundo de protótipo. Preços e sorte serão definidos nas próximas etapas.
return {
	StudioTestItems = { "Sword", "DragonSlayer", "DefaultKey", "SilverKey", "GoldKey" },
	Items = {
		Sword = { Name = "Espada", Kind = "Weapon", IncomePerSecond = 5, DisplayMaxSize = Vector3.new(3.5, 6, 3.5), HandMaxSize = Vector3.new(3, 5, 3) },
		DragonSlayer = { Name = "Dragon Slayer", Kind = "Weapon", IncomePerSecond = 15, DisplayMaxSize = Vector3.new(3.5, 6, 3.5), HandMaxSize = Vector3.new(3, 6, 3) },
		DefaultKey = { Name = "Chave comum", Kind = "Key", IncomePerSecond = 0, DisplayMaxSize = Vector3.new(3.5, 4, 3.5), HandMaxSize = Vector3.new(2.5, 2.5, 2.5) },
		SilverKey = { Name = "Chave de prata", Kind = "Key", IncomePerSecond = 0, DisplayMaxSize = Vector3.new(3.5, 4, 3.5), HandMaxSize = Vector3.new(2.5, 2.5, 2.5) },
		GoldKey = { Name = "Chave de ouro", Kind = "Key", IncomePerSecond = 0, DisplayMaxSize = Vector3.new(3.5, 4, 3.5), HandMaxSize = Vector3.new(2.5, 2.5, 2.5) },
	},
}
