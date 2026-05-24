local Config = {}

Config.IntermissionLength = 15
Config.RoundLength = 300
Config.MinPlayers = 1
Config.RoundTickInterval = 1

Config.NPCCount = 12
Config.AlienCount = 3
Config.StartingMapName = "FarmTown"
Config.Difficulty = "MVP"
Config.NPCSpawnRadius = 42
Config.NPCPromptDistance = 12
Config.NPCPromptHoldDuration = 0.5
Config.AccusationCooldown = 2
Config.ClueSpawnRadius = 24
Config.CluePromptDistance = 10
Config.CluePromptHoldDuration = 0.75
Config.ResultsLength = 10

Config.DebugPrintSecretAliens = false
Config.RandomSeed = nil

Config.DefaultPlayerClass = "Hunter"
Config.ClassAssignmentOrder = {
	"Hunter",
	"Investigator",
	"Medic",
	"Scout",
	"Engineer"
}

Config.RevealedAlienAttack = {
	Enabled = true,
	MaxHealth = 120,
	Range = 11,
	Damage = 18,
	Cooldown = 1.6,
	TickInterval = 0.35
}

Config.PlayerBaseStats = {
	MaxHealth = 100,
	WalkSpeed = 16
}

Config.PlayerCombat = {
	ToolName = "Alien Zapper",
	Range = 16,
	Damage = 34,
	Cooldown = 0.85
}

Config.NPCBehavior = {
	Enabled = true,
	TickInterval = 1.25,
	MoveSpeed = 7,
	MoveChance = 0.35,
	NearbySpawnSampleCount = 4,
	IdlePauseMin = 1.25,
	IdlePauseMax = 3.5,
	RandomFacingChance = 0.45
}

Config.AlienBehavior = {
	Enabled = true,
	TellChance = 0.28,
	PlayerNoticeRange = 28,
	LightAvoidanceChance = 0.6,
	FreezeDurationMin = 1.1,
	FreezeDurationMax = 2.4,
	StareDurationMin = 1.4,
	StareDurationMax = 2.8,
	TwitchCountMin = 2,
	TwitchCountMax = 4
}

Config.SuspicionEvents = {
	Enabled = true,
	NoticeChance = 0.45,
	Cooldown = 8,
	Messages = {
		"BEHAVIOR FLAG: one host stopped moving for too long.",
		"BEHAVIOR FLAG: one host stared without blinking.",
		"BEHAVIOR FLAG: motion pattern does not match civilian baseline.",
		"BEHAVIOR FLAG: one host recoiled from direct light.",
		"BEHAVIOR FLAG: short involuntary movement detected."
	}
}

Config.WrongAccusation = {
	TimePenalty = 20,
	AggressionDuration = 18,
	AggressionMultiplier = 1.45,
	Warning = "FALSE TARGET. TIMER REDUCED. ENTITY AGGRESSION RISING."
}

Config.ClassAbilities = {
	Hunter = {
		Name = "Stun",
		Range = 18,
		StunDuration = 3,
		Cooldown = 8
	},

	Investigator = {
		Name = "Scanner",
		Range = 28,
		Cooldown = 7
	},

	Engineer = {
		Name = "Sensor",
		Range = 18,
		Duration = 12,
		StunDuration = 2,
		Cooldown = 12
	},

	Medic = {
		Name = "Heal",
		Range = 20,
		Amount = 35,
		Cooldown = 9
	},

	Scout = {
		Name = "Mark",
		Range = 34,
		Duration = 10,
		Cooldown = 7
	}
}

Config.Traits = {
	AvoidsLight = {
		DisplayName = "Avoids bright light",
		Hint = "Witnesses say the target keeps drifting away from lantern light."
	},
	CornResidue = {
		DisplayName = "Corn residue",
		Hint = "A sweet corn smell clings to whoever left this trace."
	},
	DoesNotBlink = {
		DisplayName = "Does not blink",
		Hint = "Someone nearby watches for too long without blinking."
	},
	StrangeSpeech = {
		DisplayName = "Strange speech",
		Hint = "The target repeats human phrases with the wrong rhythm."
	},
	MirrorAvoidant = {
		DisplayName = "Mirror avoidant",
		Hint = "The target avoids reflective surfaces."
	}
}

Config.AlienTraitProfile = {
	"AvoidsLight",
	"CornResidue",
	"DoesNotBlink",
	"StrangeSpeech",
	"MirrorAvoidant"
}

Config.FullProfileDecoyCount = 2

Config.DecoyTraitSets = {
	{ "AvoidsLight" },
	{ "CornResidue" },
	{ "DoesNotBlink" },
	{ "StrangeSpeech" },
	{ "MirrorAvoidant" },
	{ "AvoidsLight", "CornResidue" },
	{ "DoesNotBlink", "StrangeSpeech" },
	{ "MirrorAvoidant", "AvoidsLight" },
	{},
	{ "CornResidue", "StrangeSpeech" },
	{},
	{ "DoesNotBlink" }
}

Config.Audio = {
	Enabled = true,
	MasterVolume = 0.7,

	AmbientDrone = {
		SoundId = "rbxasset://sounds/ambience/cave.wav",
		Volume = 0.38,
		PlaybackSpeed = 0.78,
		Looped = true
	},

	ClueStinger = {
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = 0.45,
		PlaybackSpeed = 0.62
	},

	WrongAccusation = {
		SoundId = "rbxasset://sounds/uuhhh.wav",
		Volume = 0.5,
		PlaybackSpeed = 0.72
	},

	AlienReveal = {
		SoundId = "rbxasset://sounds/HalloweenThunder.wav",
		Volume = 0.7,
		PlaybackSpeed = 0.85
	},

	PlayersWin = {
		SoundId = "rbxasset://sounds/victory.wav",
		Volume = 0.48,
		PlaybackSpeed = 0.72
	},

	AliensWin = {
		SoundId = "rbxasset://sounds/uuhhh.wav",
		Volume = 0.65,
		PlaybackSpeed = 0.48
	},

	EnvironmentalPulses = {
		MinDelay = 14,
		MaxDelay = 32,
		Sounds = {
			{
				SoundId = "rbxasset://sounds/snap.wav",
				Volume = 0.18,
				PlaybackSpeed = 0.45
			},
			{
				SoundId = "rbxasset://sounds/bass.wav",
				Volume = 0.16,
				PlaybackSpeed = 0.35
			},
			{
				SoundId = "rbxasset://sounds/button.wav",
				Volume = 0.12,
				PlaybackSpeed = 0.25
			}
		}
	}
}

Config.NPCNames = {
	"Mara Finch",
	"Eli Cobb",
	"Nora Vale",
	"Silas Reed",
	"Penny Grove",
	"Otto Lane",
	"Lena Pike",
	"Cal Moss",
	"June Field",
	"Rafi Wells",
	"Ivy Holt",
	"Bram Stone"
}

Config.Clues = {
	{
		Text = "Target avoids mirrors.",
		Prop = "Mirror",
		Trait = "MirrorAvoidant"
	},
	{
		Text = "Target smells faintly of corn.",
		Prop = "CornCrate",
		Trait = "CornResidue"
	},
	{
		Text = "Target stares too long.",
		Prop = "WatchPost",
		Trait = "DoesNotBlink"
	},
	{
		Text = "Target repeats phrases incorrectly.",
		Prop = "Radio",
		Trait = "StrangeSpeech"
	},
	{
		Text = "Target enters stores but never buys anything.",
		Prop = "Ledger",
		Trait = "AvoidsLight"
	}
}

Config.AlienTypes = {
	Galloid = {
		Enabled = true,
		DisplayName = "Galloid",
		Description = "Chicken-like alien infiltrator disguised as a human."
	}
}

Config.ClassDefinitions = {
	Hunter = {
		DisplayName = "Hunter",
		Description = "Tracks suspicious NPCs and leads accusations.",
		CombatDamageMultiplier = 1.35
	},

	Investigator = {
		DisplayName = "Investigator",
		Description = "Finds clues faster and verifies suspicious behavior.",
		ClueInspectMultiplier = 0.7
	},

	Engineer = {
		DisplayName = "Engineer",
		Description = "Maintains tools and future scanning equipment.",
		CombatDamageMultiplier = 1
	},

	Medic = {
		DisplayName = "Medic",
		Description = "Supports the team during future infection events.",
		MaxHealthBonus = 25
	},

	Scout = {
		DisplayName = "Scout",
		Description = "Moves quickly and spots unusual movement patterns.",
		WalkSpeedBonus = 4
	}
}

return Config
