local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

local context
local remotes = {}

local REMOTE_FOLDER_NAME = "ChickenAlienHuntRemotes"

local function getPublicRoundState()
	local foundCount = 0
	local totalCount = 0

	if context.Services.AlienService then
		foundCount = context.Services.AlienService.GetRevealedCount()
		totalCount = context.Services.AlienService.GetAlienCount()
	end

	return {
		State = context.Round.State,
		TimeRemaining = context.Round.TimeRemaining,
		Number = context.Round.Number,
		AliensFound = foundCount,
		AlienCount = totalCount
	}
end

local function getOrCreateRemote(className, name)
	local existing = remotes.Folder:FindFirstChild(name)

	if existing then
		return existing
	end

	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotes.Folder

	return remote
end

function RemoteService.Init(sharedContext)
	context = sharedContext

	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	remotes.Folder = folder
	remotes.RoundState = getOrCreateRemote("RemoteEvent", "RoundState")
	remotes.NPCSnapshot = getOrCreateRemote("RemoteEvent", "NPCSnapshot")
	remotes.ClueSnapshot = getOrCreateRemote("RemoteEvent", "ClueSnapshot")
	remotes.ClueDiscovered = getOrCreateRemote("RemoteEvent", "ClueDiscovered")
	remotes.SuspectSnapshot = getOrCreateRemote("RemoteEvent", "SuspectSnapshot")
	remotes.NPCRevealed = getOrCreateRemote("RemoteEvent", "NPCRevealed")
	remotes.AccusationResult = getOrCreateRemote("RemoteEvent", "AccusationResult")
	remotes.CombatResult = getOrCreateRemote("RemoteEvent", "CombatResult")
	remotes.PlayerSnapshot = getOrCreateRemote("RemoteEvent", "PlayerSnapshot")
	remotes.MissionWarning = getOrCreateRemote("RemoteEvent", "MissionWarning")
	remotes.RoundResults = getOrCreateRemote("RemoteEvent", "RoundResults")
	remotes.AccuseNPC = getOrCreateRemote("RemoteFunction", "AccuseNPC")
	remotes.SelectClass = getOrCreateRemote("RemoteFunction", "SelectClass")
	remotes.UseClassAbility = getOrCreateRemote("RemoteFunction", "UseClassAbility")
	remotes.PlacePing = getOrCreateRemote("RemoteFunction", "PlacePing")
end

function RemoteService.Start()
	print("[RemoteService] Ready")
end

function RemoteService.BindAccusationHandler(callback)
	remotes.AccuseNPC.OnServerInvoke = callback
end

function RemoteService.BindClassSelectionHandler(callback)
	remotes.SelectClass.OnServerInvoke = callback
end

function RemoteService.BindClassAbilityHandler(callback)
	remotes.UseClassAbility.OnServerInvoke = callback
end

function RemoteService.BindPlayerPingHandler(callback)
	remotes.PlacePing.OnServerInvoke = callback
end

function RemoteService.SendPublicSnapshot(player)
	remotes.RoundState:FireClient(player, getPublicRoundState())
	remotes.NPCSnapshot:FireClient(player, context.Services.NPCService.GetPublicNPCs())
	remotes.ClueSnapshot:FireClient(player, context.Services.ClueService.GetPublicClues())
	remotes.SuspectSnapshot:FireClient(player, context.Services.ClueService.GetPublicSuspectSnapshot())
	remotes.PlayerSnapshot:FireClient(player, context.Services.PlayerService.GetPublicSnapshot(player))
end

function RemoteService.BroadcastRoundState()
	remotes.RoundState:FireAllClients(getPublicRoundState())
end

function RemoteService.BroadcastNPCSnapshot()
	remotes.NPCSnapshot:FireAllClients(context.Services.NPCService.GetPublicNPCs())
end

function RemoteService.BroadcastClueSnapshot()
	remotes.ClueSnapshot:FireAllClients(context.Services.ClueService.GetPublicClues())
end

function RemoteService.BroadcastClueDiscovered(clue)
	remotes.ClueDiscovered:FireAllClients(clue)
end

function RemoteService.BroadcastSuspectSnapshot()
	remotes.SuspectSnapshot:FireAllClients(context.Services.ClueService.GetPublicSuspectSnapshot())
end

function RemoteService.BroadcastNPCRevealed(reveal)
	if not reveal then
		return
	end

	remotes.NPCRevealed:FireAllClients(reveal)
end

function RemoteService.SendAccusationResult(player, result)
	remotes.AccusationResult:FireClient(player, result)
end

function RemoteService.SendCombatResult(player, result)
	remotes.CombatResult:FireClient(player, result)
end

function RemoteService.SendPlayerSnapshot(player, snapshot)
	remotes.PlayerSnapshot:FireClient(player, snapshot)
end

function RemoteService.SendMissionWarning(player, warning)
	remotes.MissionWarning:FireClient(player, warning)
end

function RemoteService.BroadcastMissionWarning(warning)
	remotes.MissionWarning:FireAllClients(warning)
end

function RemoteService.BroadcastRoundResults(results)
	remotes.RoundResults:FireAllClients(results)
end

return RemoteService
