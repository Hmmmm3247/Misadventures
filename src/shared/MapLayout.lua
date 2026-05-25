local MapLayout = {}

-- FarmTown is a compact MVP arena. The ZoneRoles table is design metadata for
-- future systems; current map generation still reads the authored parts below.
MapLayout.ZoneRoles = {
	SouthernEntry = {
		Purpose = "Player staging and safe round orientation.",
		Gameplay = "Low-threat spawn area that points players toward the well.",
		FutureUse = "Mission board or class staging."
	},

	TownWell = {
		Purpose = "Central navigation anchor and team regroup point.",
		Gameplay = "Sickly light source and future scanner pulse location.",
		FutureUse = "Extraction marker or shared team objective."
	},

	GeneralStore = {
		Purpose = "Civilian routine landmark.",
		Gameplay = "Ledger clue area for suspicious store behavior.",
		FutureUse = "Alibi board or locked back room."
	},

	Barn = {
		Purpose = "High-risk farm supply landmark.",
		Gameplay = "Corn clue area and future revealed-alien chase loop.",
		FutureUse = "Ambush route or stronger Galloid tell zone."
	},

	FeedSilo = {
		Purpose = "Tall sightline breaker.",
		Gameplay = "Radio/static clue area and combat cover.",
		FutureUse = "Timed warning transmission or repair objective."
	},

	ChickenCoop = {
		Purpose = "Primary Galloid flavor landmark.",
		Gameplay = "Suspicious NPC gathering area near the southern lane.",
		FutureUse = "Feather clues and local clucking audio."
	},

	ObservationPole = {
		Purpose = "Behavior-watching landmark.",
		Gameplay = "Does-not-blink clue area for Scout and Investigator play.",
		FutureUse = "Temporary motion ping or high-visibility scan."
	},

	AbandonedTruck = {
		Purpose = "Failed evacuation story prop and cover.",
		Gameplay = "Outer-lane route marker during combat.",
		FutureUse = "Escape clue or supply cache."
	}
}

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
	-- SouthernEntry
	Vector3.new(-8, 1, -58),
	Vector3.new(8, 1, -58)
}

MapLayout.NPCSpawns = {
	-- Western lane, near AbandonedTruck and GeneralStore.
	Vector3.new(-42, 0, -16),
	Vector3.new(-34, 0, 18),
	Vector3.new(-24, 0, 40),
	-- Southern approach and Windmill lane.
	Vector3.new(-10, 0, -32),
	Vector3.new(4, 0, 34),
	Vector3.new(14, 0, -42),
	-- Eastern barn and silo lane.
	Vector3.new(24, 0, 20),
	Vector3.new(34, 0, -20),
	Vector3.new(42, 0, 8),
	-- Town center and north pressure points.
	Vector3.new(-4, 0, 8),
	Vector3.new(18, 0, 46),
	Vector3.new(-46, 0, -38)
}

MapLayout.ClueSpawns = {
	{
		Name = "MirrorClueSpawn",
		Zone = "GeneralStore",
		Position = Vector3.new(-28, 0, -4),
		Prop = "Mirror"
	},
	{
		Name = "CornCrateClueSpawn",
		Zone = "Barn",
		Position = Vector3.new(30, 0, 26),
		Prop = "CornCrate"
	},
	{
		Name = "WatchPostClueSpawn",
		Zone = "ObservationPole",
		Position = Vector3.new(2, 0, 44),
		Prop = "WatchPost"
	},
	{
		Name = "RadioClueSpawn",
		Zone = "FeedSilo",
		Position = Vector3.new(36, 0, -32),
		Prop = "Radio"
	},
	{
		Name = "LedgerClueSpawn",
		Zone = "GeneralStore",
		Position = Vector3.new(-34, 0, 32),
		Prop = "Ledger"
	}
}

MapLayout.Props = {
	{
		Name = "GeneralStore",
		Zone = "GeneralStore",
		Position = Vector3.new(-36, 4, 30),
		Size = Vector3.new(18, 8, 14),
		Color = Color3.fromRGB(88, 62, 48),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "Barn",
		Zone = "Barn",
		Position = Vector3.new(34, 5, 28),
		Size = Vector3.new(22, 10, 16),
		Color = Color3.fromRGB(92, 34, 34),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "FeedSilo",
		Zone = "FeedSilo",
		Position = Vector3.new(42, 7, -28),
		Size = Vector3.new(8, 14, 8),
		Color = Color3.fromRGB(82, 94, 91),
		Material = Enum.Material.CorrodedMetal,
		Shape = Enum.PartType.Cylinder
	},
	{
		Name = "TownWell",
		Zone = "TownWell",
		Position = Vector3.new(0, 1, 0),
		Size = Vector3.new(8, 2, 8),
		Color = Color3.fromRGB(54, 62, 60),
		Material = Enum.Material.Slate,
		Shape = Enum.PartType.Cylinder
	},
	{
		Name = "ChickenCoop",
		Zone = "ChickenCoop",
		Position = Vector3.new(-42, 3, -34),
		Size = Vector3.new(14, 6, 10),
		Color = Color3.fromRGB(94, 68, 48),
		Material = Enum.Material.WoodPlanks
	},
	{
		Name = "BrokenWindmill",
		Zone = "SouthernEntry",
		Position = Vector3.new(12, 8, -52),
		Size = Vector3.new(4, 16, 4),
		Color = Color3.fromRGB(68, 59, 52),
		Material = Enum.Material.Wood
	},
	{
		Name = "ObservationPole",
		Zone = "ObservationPole",
		Position = Vector3.new(-4, 7, 48),
		Size = Vector3.new(3, 14, 3),
		Color = Color3.fromRGB(42, 48, 48),
		Material = Enum.Material.CorrodedMetal
	},
	{
		Name = "AbandonedTruck",
		Zone = "AbandonedTruck",
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
