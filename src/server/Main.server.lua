local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ServerFolder = script.Parent

local Services = {
	RemoteService = require(ServerFolder.RemoteService),
	MapService = require(ServerFolder.MapService),
	MapEventService = require(ServerFolder.MapEventService),
	PlayerService = require(ServerFolder.PlayerService),
	PlayerPingService = require(ServerFolder.PlayerPingService),
	NPCService = require(ServerFolder.NPCService),
	AlienService = require(ServerFolder.AlienService),
	ClueService = require(ServerFolder.ClueService),
	AccusationService = require(ServerFolder.AccusationService),
	CombatService = require(ServerFolder.CombatService),
	ClassAbilityService = require(ServerFolder.ClassAbilityService),
	ResultService = require(ServerFolder.ResultService),
	RoundService = require(ServerFolder.RoundService)
}

local context = {
	Config = Config,
	Services = Services,
	Round = {
		State = "Booting",
		Number = 0
	},
	NPCs = {},
	Aliens = {},
	Clues = {},
	Players = {},
	Results = {}
}

local initOrder = {
	"RemoteService",
	"MapService",
	"MapEventService",
	"PlayerService",
	"PlayerPingService",
	"NPCService",
	"AlienService",
	"ClueService",
	"AccusationService",
	"CombatService",
	"ClassAbilityService",
	"ResultService",
	"RoundService"
}

print("[ChickenAlienHunt] Server bootstrap started")
print("[ChickenAlienHunt] Config loaded")
print("[ChickenAlienHunt] Map:", Config.StartingMapName)
print("[ChickenAlienHunt] Difficulty:", Config.Difficulty)
print("[ChickenAlienHunt] NPC Count:", Config.NPCCount)
print("[ChickenAlienHunt] Alien Count:", Config.AlienCount)
print("[ChickenAlienHunt] Round Length:", Config.RoundLength)

for _, serviceName in ipairs(initOrder) do
	print("[ChickenAlienHunt] Initializing", serviceName)
	Services[serviceName].Init(context)
end

for _, serviceName in ipairs(initOrder) do
	print("[ChickenAlienHunt] Starting", serviceName)
	Services[serviceName].Start()
end

print("[ChickenAlienHunt] Server ready")
