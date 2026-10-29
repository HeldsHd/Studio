--!strict
-- Valores provisórios: calibrar junto das chaves e recompensas.
return {
	BalconyName = "Balconi",
	PositionsName = "ChestPosition",
	PositionNames = { "Chest1Middle", "Chest2Left", "Chest3Right" },
	RuntimeFolderName = "ChestDisplays",
	StartingChestId = "DefaultChest",
	InteractionDistance = 9,
	InteractionCooldown = 0.4,
	HoldDuration = 0.35,
	UpgradeHoldDuration = 0.6,
	-- Os marcadores atuais ficam 1 stud acima da superfície do balcão.
	SurfaceOffset = -1,
	LabelOffset = Vector3.new(0, 4, 0),
	Chests = {
		DefaultChest = {
			Name = "Baú comum",
			Price = 50,
			KeyId = "DefaultKey",
			NextChestId = "SilverChest",
			UpgradePrice = 150,
			TemplateGroup = "DefaultChest",
			TemplateName = "DefaultChestM",
			DisplayScale = 0.3,
			DisplayYawDegrees = -90,
			Metadata = {}, -- Apenas na compra; upgrades preservam os dados do exemplar.
		},
		SilverChest = {
			Name = "Baú de prata",
			KeyId = "SilverKey",
			NextChestId = "GoldChest",
			UpgradePrice = 550,
			TemplateGroup = "SilverChest",
			TemplateName = "SilverChestM",
			DisplayScale = 0.3,
			DisplayYawDegrees = -90,
		},
		GoldChest = {
			Name = "Baú de ouro",
			KeyId = "GoldKey",
			TemplateGroup = "GoldChest",
			TemplateName = "GoldChestM",
			DisplayScale = 0.3,
			DisplayYawDegrees = -90,
		},
	},
}
