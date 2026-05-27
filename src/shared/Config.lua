local Config = {}

Config.IntermissionLength = 15
Config.RoundLength = 360
Config.MinPlayers = 1
Config.RoundTickInterval = 1

Config.NPCCount = 12
Config.AlienCount = 3
Config.StartingMapName = "FarmTown"
Config.Difficulty = "MVP"
Config.NPCSpawnRadius = 42
Config.NPCPromptDistance = 12
Config.NPCPromptHoldDuration = 0.5
Config.AccusationCooldown = 1.5
Config.ClueSpawnRadius = 24
Config.CluePromptDistance = 10
Config.CluePromptHoldDuration = 0.75
Config.ResultsLength = 10

Config.DebugPrintSecretAliens = false
Config.RandomSeed = nil

Config.DebugTesting = {
	Enabled = false,
	ControlsEnabled = true,
	CommandCooldown = 0.5,
	MinPlayersOverride = 1,
	IntermissionLength = 3,
	RoundLength = 90,
	ResultsLength = 6,
	RevealFirstAlienAfter = nil,
	ChaseTestSpawnDistance = 24
}

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
	Cooldown = 1.45,
	TickInterval = 0.35
}

Config.RevealedAlienChase = {
	Enabled = true,
	Range = 62,
	StopDistance = 9,
	Speed = 10.5,
	LeashDistance = 76,
	WarningCooldown = 7,
	StartWarning = "CHASE WARNING: confirmed entity has locked onto you.",
	StopWarning = "CHASE UPDATE: entity pursuit signal dropped.",
	ScreenPulseDuration = 0.75
}

Config.AlienEscape = {
	Enabled = true,
	EscapeChanceOnReveal = 0.25,
	EscapeDelaySeconds = 10,
	EscapeSpeed = 13,
	EscapePointNames = {
		"SouthernEntry",
		"BarnBackExit",
		"CornfieldEdge"
	},
	EscapeRadius = 6,
	EscapeWarningLeadTime = 3,
	Warning = "CONTAINMENT BREACH: revealed alien is escaping.",
	EscapedWarning = "CONTAINMENT FAILED: alien escaped the perimeter."
}

Config.NestingEvent = {
	Enabled = true,
	Chance = 0.18,
	JuvenileHealth = 45,
	JuvenileSpeed = 4.2,
	RageDuration = 24,
	AggressionMultiplier = 1.65,
	DamageMultiplier = 1.35,
	ChaseSpeedMultiplier = 1.45,
	TriggerOnJuvenileDeath = true,
	TimidMoveChance = 0.42,
	HideNearGroupChance = 0.34,
	HideNearLandmarkChance = 0.3,
	DistressSoundChance = 0.18,
	ModelScale = 0.78,
	WarningSignChanceOnRoundStart = 0.75,
	WarningSignDelayMin = 4,
	WarningSignDelayMax = 9,
	JuvenileRevealWarning = "NESTING EVENT: juvenile Galloid confirmed. Protector response uncertain.",
	RageWarning = "NESTING EVENT: juvenile entity eliminated. Protector rage state active.",
	PreEscalationWarning = "RADIO HINT: small distress calls under the farm channel."
}

Config.PlayerBaseStats = {
	MaxHealth = 100,
	WalkSpeed = 16
}

Config.DownedPlayers = {
	Enabled = true,
	DownHealth = 1,
	WalkSpeed = 3,
	EliminationDelay = 18,
	ReviveRange = 12,
	ReviveHoldDuration = 2.75,
	ReviveHealth = 45,
	MedicReviveHealth = 70,
	ReviveCooldown = 1.5,
	PromptActionText = "Revive",
	PromptObjectText = "Downed Teammate",
	DownedWarning = "OPERATIVE DOWN: teammate needs help.",
	RevivedWarning = "OPERATIVE REVIVED: teammate back on feet.",
	SelfDownedWarning = "YOU ARE DOWN: wait for a teammate revive."
}

Config.MimicConversion = {
	Enabled = true,
	Chance = 0.12,
	MaxMimicPlayersPerRound = 1,
	RequiresMinimumSurvivors = 2,
	ConversionDelay = 4,
	MimicHealth = 90,
	MimicWalkSpeed = 18,
	MimicDamage = 28,
	MimicAttackRange = 9,
	MimicAttackCooldown = 4,
	ObjectiveText = "NEW OBJECTIVE: ELIMINATE THE PARTY",
	ConversionWarning = "SIGNAL LOST: operative vitals went dark.",
	MimicAwakenedText = "MIMIC HOST ONLINE: stay hidden, isolate, strike."
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
	MoveSpeed = 5.75,
	MoveChance = 0.32,
	ClusterChance = 0.14,
	LookAtPlayerChance = 0.18,
	ClusterSpawnSampleCount = 4,
	NearbySpawnSampleCount = 4,
	IdlePauseMin = 1.5,
	IdlePauseMax = 4.25,
	RandomFacingChance = 0.52,
	ShortPauseChance = 0.18,
	ShortPauseMin = 0.6,
	ShortPauseMax = 1.35
}

Config.NPCSocialBehavior = {
	Enabled = true,
	GroupSearchRange = 38,
	GroupClusterRadius = 15,
	GroupClusterChance = 0.14,
	LandmarkStandChance = 0.18,
	LandmarkStandMin = 1.2,
	LandmarkStandMax = 2.8,
	FaceNearbyNPCChance = 0.1
}

Config.AlienBehavior = {
	Enabled = true,
	TellChance = 0.30,
	PlayerNoticeRange = 28,
	LightAvoidanceChance = 0.6,
	FollowPlayerChance = 0.18,
	FollowStepDistance = 10,
	DelayedReactionChance = 0.22,
	SuspiciousPauseMin = 0.8,
	SuspiciousPauseMax = 1.8,
	FreezeDurationMin = 1.1,
	FreezeDurationMax = 2.4,
	StareDurationMin = 1.4,
	StareDurationMax = 2.8,
	TwitchCountMin = 2,
	TwitchCountMax = 4
}

Config.NPCSuspicion = {
	Enabled = true,
	BehaviorAmount = 14,
	ClueMatchAmount = 18,
	WrongAccusationAmount = 10,
	HighThreshold = 45,
	MaxScore = 100,
	SnapshotCooldown = 3,
	HighlySuspiciousLimit = 4
}

Config.RevealPresentation = {
	Warning = "ENTITY REVEALED: hostile disguise collapsed.",
	ScreenPulseDuration = 1.1,
	PanicRadius = 34,
	PanicMoveChance = 0.7,
	PanicHighlightDuration = 1.25
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

Config.FalsePositiveEvents = {
	Enabled = true,
	NPCBehaviorChance = 0.09,
	SuspicionAmount = 6,
	HesitationMin = 0.7,
	HesitationMax = 1.6,
	TwitchCountMin = 1,
	TwitchCountMax = 2,
	TwitchAngleMin = -10,
	TwitchAngleMax = 10,
	TwitchStepWait = 0.1,
	PanicMoveChance = 0.55,
	FakeClueWarningChance = 0.35,
	HarmlessSuspiciousText = "BEHAVIOR FLAG: harmless hesitation matched an entity tell.",
	MovementAnomalyText = "BEHAVIOR FLAG: non-host movement anomaly logged.",
	PanicText = "BEHAVIOR FLAG: innocent resident panicked at the wrong moment.",
	FakeClueText = "FALSE SIGNAL: residue trace collapsed into ordinary farm dust."
}

Config.WrongAccusation = {
	TimePenalty = 16,
	AggressionDuration = 18,
	AggressionMultiplier = 1.45,
	ChaseAggressionMultiplier = 1.3,
	Warning = "EMERGENCY: false target. Timer reduced. Revealed entity pursuit elevated.",
	ScreenPulseDuration = 0.85,
	AlarmPulse = {
		Enabled = true,
		Text = "ALARM PULSE: false accusation destabilized the containment field.",
		Severity = "Emergency",
		EventType = "Alarm",
		Zone = "FarmTown"
	}
}

Config.MapEvents = {
	Enabled = true,
	MinInterval = 28,
	MaxInterval = 46,
	PanicEventChance = 0.35,
	FalsePositiveEventChance = 0.18,
	AlienPulseEventChance = 0.12,
	CorruptionEventChance = 0,
	BlackoutFlickerDuration = 1.4,
	BlackoutBrightness = 0.12,
	BlackoutOffWait = 0.12,
	BlackoutOnWait = 0.1,
	MinimumIntervalDivisor = 0.1,
	LightFlickerBrightnessMin = 0.05,
	LightFlickerBrightnessMax = 0.22,
	LightFlickerOffMin = 0.07,
	LightFlickerOffMax = 0.18,
	LightFlickerOnMin = 0.08,
	LightFlickerOnMax = 0.2,
	PanicScreenPulseDuration = 0.55,
	EmergencyScreenPulseDuration = 0.9,
	MinimumCorruptionBrightness = 0.08,
	TensionScaling = {
		Enabled = true,
		MidRoundRemainingRatio = 0.6,
		LateRoundRemainingRatio = 0.3,
		MidRoundIntervalMultiplier = 1.25,
		LateRoundIntervalMultiplier = 1.8,
		AfterRevealIntervalMultiplier = 1.45,
		AfterRevealChanceBonus = 0.12,
		LateRoundChanceBonus = 0.18
	},
	Events = {
		{
			Zone = "Barn",
			EventType = "Radio",
			AudioCue = "RadioInterference",
			Severity = "MapPing",
			Text = "RADIO PING: barn static rising. Watch movement near the feed crates."
		},
		{
			Zone = "ChickenCoop",
			EventType = "Audio",
			AudioCue = "DistantClucking",
			Severity = "MapPing",
			Text = "AUDIO FLAG: faint clucking reported near the chicken coop."
		},
		{
			Zone = "FeedSilo",
			EventType = "Radio",
			AudioCue = "RadioInterference",
			Severity = "MapPing",
			Text = "RADIO PING: broken speech looping from the silo channel."
		},
		{
			Zone = "TownWell",
			EventType = "Scanner",
			AudioCue = "Whispers",
			Severity = "MapPing",
			Text = "SCANNER PING: cold movement around the town well."
		},
		{
			Zone = "ObservationPole",
			EventType = "Scanner",
			AudioCue = "Footsteps",
			Severity = "MapPing",
			Text = "MOTION PING: someone near the observation pole stopped moving."
		},
		{
			Zone = "GeneralStore",
			EventType = "Radio",
			AudioCue = "Scratching",
			Severity = "MapPing",
			Text = "RADIO PING: store ledger signal repeating without a source."
		},
		{
			Zone = "GeneralStore",
			EventType = "LightFlicker",
			AudioCue = "LightFlicker",
			Severity = "MapPing",
			Text = "LIGHT FLICKER: store lanterns stuttered without wind."
		},
		{
			Zone = "Barn",
			EventType = "BarnDoorSlam",
			AudioCue = "BarnDoorSlam",
			Severity = "MapPing",
			Text = "BARN IMPACT: a door slammed somewhere inside the barn."
		}
	},
	PanicEvents = {
		{
			Zone = "FarmTown",
			EventType = "Blackout",
			AudioCue = "LightFlicker",
			Severity = "Panic",
			Text = "BLACKOUT FLICKER: lantern grid dropped for a heartbeat."
		},
		{
			Zone = "FeedSilo",
			EventType = "RadioBurst",
			AudioCue = "RadioInterference",
			Severity = "Panic",
			Text = "RADIO BURST: do not trust the still ones."
		},
		{
			Zone = "SouthernEntry",
			EventType = "Siren",
			AudioCue = "MetalCreak",
			Severity = "Emergency",
			Text = "SIREN: perimeter breach sensors waking up."
		},
		{
			Zone = "TownWell",
			EventType = "Announcement",
			AudioCue = "Whispers",
			Severity = "Panic",
			Text = "ANNOUNCEMENT: farm residents should remain calm and visible."
		}
	},
	FalsePositiveEvents = {
		{
			Zone = "GeneralStore",
			EventType = "FakeClue",
			AudioCue = "Scratching",
			Severity = "MapPing",
			Text = "FALSE CLUE: dust pattern looked deliberate, then scattered."
		},
		{
			Zone = "ObservationPole",
			EventType = "MovementAnomaly",
			AudioCue = "Footsteps",
			Severity = "MapPing",
			Text = "MOTION PING: harmless resident took three steps backward."
		},
		{
			Zone = "ChickenCoop",
			EventType = "CoopPanic",
			AudioCue = "CoopPanic",
			Severity = "Panic",
			Text = "COOP PANIC: chickens erupted, then settled too quickly."
		}
	},
	AlienPulseEvents = {
		{
			Zone = "FarmTown",
			EventType = "AlienPulse",
			AudioCue = "Whispers",
			Severity = "Panic",
			Text = "ENVIRONMENTAL PULSE: the farm bent toward an active signal.",
			Duration = 1.1
		}
	},
	CorruptionEvents = {
		{
			Zone = "FarmTown",
			EventType = "CorruptionPulse",
			AudioCue = "MetalCreak",
			Severity = "Panic",
			Text = "CORRUPTION PULSE: the air turned sour around the farm.",
			Duration = 1.3,
			BrightnessDrop = 0.22
		}
	},
	NestingHintEvents = {
		{
			Zone = "ChickenCoop",
			EventType = "NestingHint",
			AudioCue = "JuvenileCluck",
			Severity = "MapPing",
			Text = "AUDIO FLAG: smaller clucking pattern under the coop noise."
		},
		{
			Zone = "Barn",
			EventType = "NestingHint",
			AudioCue = "JuvenileCry",
			Severity = "MapPing",
			Text = "TRACE FLAG: small feather fragments found near stacked feed."
		},
		{
			Zone = "FeedSilo",
			EventType = "NestingHint",
			AudioCue = "RadioInterference",
			Severity = "MapPing",
			Text = "RADIO HINT: repeating distress chirps below the silo channel."
		}
	},
	NestingRageEvents = {
		{
			Zone = "FarmTown",
			EventType = "NestingRage",
			AudioCue = "JuvenileCry",
			Severity = "Emergency",
			Text = "EMERGENCY: protector rage response detected across FarmTown.",
			Duration = 1.4,
			BrightnessDrop = 0.28
		}
	}
}

Config.PlayerPings = {
	Enabled = true,
	Cooldown = 4,
	WorldMarkersEnabled = true,
	MarkerDuration = 8,
	Types = {
		Suspicious = {
			Label = "Suspicious",
			Color = { 255, 210, 80 }
		},
		Clue = {
			Label = "Clue",
			Color = { 105, 220, 255 }
		},
		Help = {
			Label = "Help",
			Color = { 255, 105, 105 }
		}
	}
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
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/ambience/cave.wav",
		Volume = 0.38,
		PlaybackSpeed = 0.78,
		Looped = true
	},

	ClueStinger = {
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/electronicpingshort.wav",
		Volume = 0.45,
		PlaybackSpeed = 0.62
	},

	WrongAccusation = {
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/uuhhh.wav",
		Volume = 0.5,
		PlaybackSpeed = 0.72
	},

	AlienReveal = {
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/HalloweenThunder.wav",
		Volume = 0.7,
		PlaybackSpeed = 0.85
	},

	PlayersWin = {
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/victory.wav",
		Volume = 0.48,
		PlaybackSpeed = 0.72
	},

	AliensWin = {
		MarketplaceId = "",
		SoundId = "rbxasset://sounds/uuhhh.wav",
		Volume = 0.65,
		PlaybackSpeed = 0.48
	},

	EnvironmentalPulses = {
		MinDelay = 14,
		MaxDelay = 32,
		Sounds = {
			{
				MarketplaceId = "",
				SoundId = "rbxasset://sounds/snap.wav",
				Volume = 0.18,
				PlaybackSpeed = 0.45
			},
			{
				MarketplaceId = "",
				SoundId = "rbxasset://sounds/bass.wav",
				Volume = 0.16,
				PlaybackSpeed = 0.35
			},
			{
				MarketplaceId = "",
				SoundId = "rbxasset://sounds/button.wav",
				Volume = 0.12,
				PlaybackSpeed = 0.25
			}
		}
	},

	PositionalCues = {
		DistantClucking = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/impact_water.mp3",
			Volume = 0.18,
			PlaybackSpeed = 1.7,
			RollOffMinDistance = 8,
			RollOffMaxDistance = 72,
			Lifetime = 5
		},

		Footsteps = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
			Volume = 0.16,
			PlaybackSpeed = 0.72,
			RollOffMinDistance = 8,
			RollOffMaxDistance = 64,
			Lifetime = 5
		},

		Whispers = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/bass.wav",
			Volume = 0.12,
			PlaybackSpeed = 0.32,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 85,
			Lifetime = 6
		},

		Scratching = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/snap.wav",
			Volume = 0.14,
			PlaybackSpeed = 0.55,
			RollOffMinDistance = 7,
			RollOffMaxDistance = 58,
			Lifetime = 4
		},

		RadioInterference = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/electronicpingshort.wav",
			Volume = 0.18,
			PlaybackSpeed = 0.35,
			RollOffMinDistance = 12,
			RollOffMaxDistance = 90,
			Lifetime = 5
		},

		LightFlicker = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/button.wav",
			Volume = 0.12,
			PlaybackSpeed = 0.45,
			RollOffMinDistance = 8,
			RollOffMaxDistance = 70,
			Lifetime = 4
		},

		CoopPanic = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/impact_water.mp3",
			Volume = 0.22,
			PlaybackSpeed = 2.0,
			RollOffMinDistance = 10,
			RollOffMaxDistance = 78,
			Lifetime = 5
		},

		MetalCreak = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/uuhhh.wav",
			Volume = 0.2,
			PlaybackSpeed = 0.38,
			RollOffMinDistance = 14,
			RollOffMaxDistance = 95,
			Lifetime = 6
		},

		BarnDoorSlam = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/HalloweenThunder.wav",
			Volume = 0.22,
			PlaybackSpeed = 0.55,
			RollOffMinDistance = 12,
			RollOffMaxDistance = 90,
			Lifetime = 6
		},

		JuvenileCluck = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/impact_water.mp3",
			Volume = 0.14,
			PlaybackSpeed = 2.25,
			RollOffMinDistance = 8,
			RollOffMaxDistance = 70,
			Lifetime = 5
		},

		JuvenileCry = {
			MarketplaceId = "",
			SoundId = "rbxasset://sounds/uuhhh.wav",
			Volume = 0.18,
			PlaybackSpeed = 0.62,
			RollOffMinDistance = 12,
			RollOffMaxDistance = 90,
			Lifetime = 6
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
	"Bram Stone",
	"Dot Thorn",
	"Huck Vane",
	"Wren Barley",
	"Amos Flint",
	"Clem Dray",
	"Sable Cork",
	"Rue Patcher",
	"Gideon Marsh",
	"Fern Lacey",
	"Cord Bale",
	"Vesper Knoll",
	"Thad Greer"
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
		Text = "Target lingers in dark corners and drifts away from light.",
		Prop = "Ledger",
		Trait = "AvoidsLight"
	}
}

Config.AlienTypes = {
	Galloid = {
		Enabled = true,
		DisplayName = "Galloid",
		Description = "Chicken-like alien infiltrator disguised as a human.",
		DefaultVariant = "GalloidPecker",
		StoryRole = "Funny-creepy first enemy that rewards observation before combat."
	},

	Husker = {
		Enabled = false,
		DisplayName = "Husker",
		Description = "Parasite alien that weakens players over time.",
		StoryRole = "Future pressure enemy for infection and rescue mechanics."
	},

	Hollowman = {
		Enabled = false,
		DisplayName = "Hollowman",
		Description = "Almost-perfect human mimic with fewer obvious tells.",
		StoryRole = "Future deduction enemy built around weak evidence and contradictions."
	},

	Crawler = {
		Enabled = false,
		DisplayName = "Crawler",
		Description = "Stealth predator that hunts isolated players.",
		StoryRole = "Future fear enemy that makes splitting up risky."
	},

	Choir = {
		Enabled = false,
		DisplayName = "Choir",
		Description = "Psychological alien entity that distorts certainty.",
		StoryRole = "Future nightmare-tier enemy for UI, audio, and perception pressure."
	}
}

Config.AlienTypeProfiles = {
	GalloidPecker = {
		Enabled = false,
		AlienType = "Galloid",
		DisplayName = "Galloid Pecker",
		Description = "Aggressive Galloid breach variant for direct combat pressure.",
		MapAffinity = { "Barn", "ChickenCoop" },
		TellBias = { "Twitch", "Stare" },
		UserThreat = "Fast close-range attacks after reveal.",
		FutureTuning = {
			MaxHealthMultiplier = 1,
			DamageMultiplier = 1.15,
			AttackCooldownMultiplier = 0.85,
			TellChanceMultiplier = 1
		}
	},

	GalloidBrooder = {
		Enabled = false,
		AlienType = "Galloid",
		DisplayName = "Galloid Brooder",
		Description = "Cluster variant that hides inside groups of civilians.",
		MapAffinity = { "TownWell", "GeneralStore" },
		TellBias = { "Freeze", "StrangeSpeech" },
		UserThreat = "Makes suspect reads harder by staying near decoys.",
		FutureTuning = {
			MaxHealthMultiplier = 1.1,
			DamageMultiplier = 0.9,
			AttackCooldownMultiplier = 1.1,
			TellChanceMultiplier = 0.85
		}
	},

	GalloidMolt = {
		Enabled = false,
		AlienType = "Galloid",
		DisplayName = "Galloid Molt",
		Description = "Evidence-heavy Galloid that leaves feather and corn traces.",
		MapAffinity = { "ChickenCoop", "Barn", "AbandonedTruck" },
		TellBias = { "AvoidsLight", "CornResidue" },
		UserThreat = "Easier to track, but can bait overconfident accusations.",
		FutureTuning = {
			MaxHealthMultiplier = 0.9,
			DamageMultiplier = 1,
			AttackCooldownMultiplier = 1,
			TellChanceMultiplier = 1.25
		}
	},

	GalloidRooster = {
		Enabled = false,
		AlienType = "Galloid",
		DisplayName = "Galloid Rooster",
		Description = "Alarm variant that turns mistakes into louder round pressure.",
		MapAffinity = { "FeedSilo", "ObservationPole" },
		TellBias = { "StrangeSpeech", "Stare" },
		UserThreat = "Future aggression boosts, warnings, and pressure spikes.",
		FutureTuning = {
			MaxHealthMultiplier = 1,
			DamageMultiplier = 1,
			AttackCooldownMultiplier = 0.95,
			TellChanceMultiplier = 1.2
		}
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
