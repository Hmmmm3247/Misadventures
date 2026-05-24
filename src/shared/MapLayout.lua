local MapLayout = {}

MapLayout.Ground = {
	Size = Vector3.new(140, 1, 140),
	Position = Vector3.new(0, -0.5, 0),
	Color = Color3.fromRGB(34, 48, 38),
	Material = Enum.Material.Ground
}

MapLayout.Lighting = {
	ClockTime = 1.7,
	Brightness = 0.55,
	Ambient = Color3.fromRGB(28, 35, 34),
	OutdoorAmbient = Color3.fromRGB(18, 24, 25),
	FogColor = Color3.fromRGB(20, 28, 27),
	FogStart = 18,
	FogEnd = 115,
	AtmosphereColor = Color3.fromRGB(79, 92, 86),
	AtmosphereDecay = Color3.fromRGB(20, 28, 24),
	AtmosphereDensity = 0.48,
	AtmosphereGlare = 0.08,
	AtmosphereHaze = 2.6,
	ColorCorrectionTint = Color3.fromRGB(184, 207, 188),
	ColorCorrectionBrightness = -0.08,
	ColorCorrectionContrast = 0.22,
	ColorCorrectionSaturation = -0.35
}

MapLayout.PlayerSpawns = {
	Vector3.new(-8, 1, -58),
	Vector3.new(8, 1, -58)
}

MapLayout.NPCSpawns = {
	Vector3.new(-42, 0, -16),
	Vector3.new(-34, 0, 18),
	Vector3.new(-24, 0, 40),
	Vector3.new(-10, 0, -32),
	Vector3.new(4, 0, 34),
	Vector3.new(14, 0, -42),
	Vector3.new(24, 0, 20),
	Vector3.new(34, 0, -20),
	Vector3.new(42, 0, 8),
	Vector3.new(-4, 0, 8),
	Vector3.new(18, 0, 46),
	Vector3.new(-46, 0, -38)
}

MapLayout.ClueSpawns = {
	{
		Name = "MirrorClueSpawn",
		Position = Vector3.new(-28, 0, -4),
		Prop = "Mirror"
	},
	{
		Name = "CornCrateClueSpawn",
		Position = Vector3.new(30, 0, 26),
		Prop = "CornCrate"
	},
	{
		Name = "WatchPostClueSpawn",
		Position = Vector3.new(2, 0, 44),
		Prop = "WatchPost"
	},
	{
		Name = "RadioClueSpawn",
		Position = Vector3.new(36, 0, -32),
		Prop = "Radio"
	},
	{
		Name = "LedgerClueSpawn",
		Position = Vector3.new(-34, 0, 32),
		Prop = "Ledger"
	}
}

MapLayout.Props = {
	{
		Name = "GeneralStore",
		Position = Vector3.new(-36, 4, 30),
		Size = Vector3.new(18, 8, 14),
		Color = Color3.fromRGB(88, 62, 48),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "Barn",
		Position = Vector3.new(34, 5, 28),
		Size = Vector3.new(22, 10, 16),
		Color = Color3.fromRGB(92, 34, 34),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "FeedSilo",
		Position = Vector3.new(42, 7, -28),
		Size = Vector3.new(8, 14, 8),
		Color = Color3.fromRGB(82, 94, 91),
		Material = Enum.Material.CorrodedMetal,
		Shape = Enum.PartType.Cylinder
	},
	{
		Name = "TownWell",
		Position = Vector3.new(0, 1, 0),
		Size = Vector3.new(8, 2, 8),
		Color = Color3.fromRGB(54, 62, 60),
		Material = Enum.Material.Slate,
		Shape = Enum.PartType.Cylinder
	},
	{
		Name = "ChickenCoop",
		Position = Vector3.new(-42, 3, -34),
		Size = Vector3.new(14, 6, 10),
		Color = Color3.fromRGB(94, 68, 48),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "BrokenWindmill",
		Position = Vector3.new(12, 8, -52),
		Size = Vector3.new(4, 16, 4),
		Color = Color3.fromRGB(68, 59, 52),
		Material = Enum.Material.Wood
	},
	{
		Name = "ObservationPole",
		Position = Vector3.new(-4, 7, 48),
		Size = Vector3.new(3, 14, 3),
		Color = Color3.fromRGB(42, 48, 48),
		Material = Enum.Material.CorrodedMetal
	},
	{
		Name = "AbandonedTruck",
		Position = Vector3.new(-52, 2, 6),
		Size = Vector3.new(12, 4, 6),
		Color = Color3.fromRGB(53, 70, 65),
		Material = Enum.Material.CorrodedMetal
	}
}

MapLayout.Fences = {
	Vector3.new(-58, 2, -28),
	Vector3.new(-58, 2, 0),
	Vector3.new(-58, 2, 28),
	Vector3.new(58, 2, -28),
	Vector3.new(58, 2, 0),
	Vector3.new(58, 2, 28),
	Vector3.new(-28, 2, 58),
	Vector3.new(0, 2, 58),
	Vector3.new(28, 2, 58)
}

MapLayout.WarningPosts = {
	Vector3.new(-16, 3, -18),
	Vector3.new(22, 3, 2),
	Vector3.new(-24, 3, 46)
}

MapLayout.LightSources = {
	{
		Name = "StoreLantern",
		Position = Vector3.new(-26, 7, 22),
		Color = Color3.fromRGB(255, 166, 88),
		Brightness = 1.1,
		Range = 18
	},
	{
		Name = "BarnSickLight",
		Position = Vector3.new(24, 7, 22),
		Color = Color3.fromRGB(132, 255, 154),
		Brightness = 0.65,
		Range = 15
	},
	{
		Name = "WellGlow",
		Position = Vector3.new(0, 3, 0),
		Color = Color3.fromRGB(105, 190, 170),
		Brightness = 0.7,
		Range = 16
	}
}

return MapLayout
