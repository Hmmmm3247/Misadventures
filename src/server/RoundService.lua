local RoundService = {}

local Players = game:GetService("Players")

local context
local running = false
local activeRoundEnded = false
local random

local function getDebugTestingConfig()
	return context.Config.DebugTesting or {}
end

local function isDebugTestingEnabled()
	return getDebugTestingConfig().Enabled == true
end

local function getConfiguredDuration(key, fallback)
	local debugConfig = getDebugTestingConfig()

	if isDebugTestingEnabled() and type(debugConfig[key]) == "number" then
		return debugConfig[key]
	end

	return fallback
end

local function getMinimumPlayers()
	local debugConfig = getDebugTestingConfig()

	if isDebugTestingEnabled() and type(debugConfig.MinPlayersOverride) == "number" then
		return debugConfig.MinPlayersOverride
	end

	return context.Config.MinPlayers
end

local function rollRoundModifiers()
	local modifiers = {}
	local nestingConfig = context.Config.NestingEvent or {}

	if nestingConfig.Enabled and random:NextNumber() <= (nestingConfig.Chance or 0) then
		modifiers.NestingEvent = {
			Name = "NestingEvent",
			Active = true,
			RageTriggered = false
		}
	end

	context.Round.Modifiers = modifiers

	return modifiers
end

local function scheduleNestingWarningSigns()
	local nestingConfig = context.Config.NestingEvent or {}

	if not RoundService.HasModifier("NestingEvent") then
		return
	end

	if random:NextNumber() > (nestingConfig.WarningSignChanceOnRoundStart or 0) then
		return
	end

	task.delay(random:NextNumber(nestingConfig.WarningSignDelayMin or 4, nestingConfig.WarningSignDelayMax or 9), function()
		if context.Round.State ~= "Active" or not RoundService.HasModifier("NestingEvent") then
			return
		end

		if context.Services.MapEventService then
			context.Services.MapEventService.TriggerNestingHint("NestingEvent")
		end

		context.Services.RemoteService.BroadcastMissionWarning({
			Text = nestingConfig.PreEscalationWarning or "RADIO HINT: small distress calls under the farm channel.",
			Severity = "MapPing",
			ScreenPulse = false
		})
	end)
end

local function scheduleDebugAlienReveal()
	local debugConfig = getDebugTestingConfig()

	if not isDebugTestingEnabled() or type(debugConfig.RevealFirstAlienAfter) ~= "number" then
		return
	end

	local roundNumber = context.Round.Number
	local delaySeconds = math.max(0, debugConfig.RevealFirstAlienAfter)

	task.delay(delaySeconds, function()
		if context.Round.State ~= "Active" or context.Round.Number ~= roundNumber then
			return
		end

		context.Services.AlienService.DebugRevealFirstAlien("DebugTesting")
	end)
end

function RoundService.Init(sharedContext)
	context = sharedContext
	random = Random.new(context.Config.RandomSeed)
end

function RoundService.Start()
	print("[RoundService] Ready")
	running = true

	Players.PlayerAdded:Connect(function(player)
		context.Services.RemoteService.SendPublicSnapshot(player)
	end)

	task.spawn(function()
		RoundService.RunLoop()
	end)
end

function RoundService.SetState(state, timeRemaining)
	context.Round.State = state
	context.Round.TimeRemaining = timeRemaining or 0
	print("[RoundService] State:", state)
	context.Services.RemoteService.BroadcastRoundState()
end

function RoundService.WaitForMinimumPlayers()
	while running and #Players:GetPlayers() < getMinimumPlayers() do
		RoundService.SetState("WaitingForPlayers", 0)
		task.wait(context.Config.RoundTickInterval)
	end
end

function RoundService.Countdown(state, duration)
	local timeRemaining = duration

	while timeRemaining >= 0 do
		if not running then
			return false
		end

		if state == "Active" and context.Round.State ~= state then
			return true
		end

		if state == "Active" then
			context.Services.ResultService.CheckForAliensWin()

			if context.Round.State ~= state then
				return true
			end
		end

		RoundService.SetState(state, timeRemaining)
		task.wait(context.Config.RoundTickInterval)

		if state ~= "Active" and context.Round.State ~= state then
			return true
		end

		if state == "Active" then
			timeRemaining = context.Round.TimeRemaining - context.Config.RoundTickInterval
		else
			timeRemaining -= context.Config.RoundTickInterval
		end
	end

	return true
end

function RoundService.ApplyTimePenalty(seconds, reason)
	if context.Round.State ~= "Active" then
		return context.Round.TimeRemaining or 0
	end

	context.Round.TimeRemaining = math.max(0, (context.Round.TimeRemaining or 0) - seconds)
	print("[RoundService] Time penalty:", seconds, reason or "Unknown")
	context.Services.RemoteService.BroadcastRoundState()

	return context.Round.TimeRemaining
end

function RoundService.StartRound()
	if context.Round.State == "Active" then
		return
	end

	context.Round.Number += 1
	context.Round.Modifiers = {}
	activeRoundEnded = false
	RoundService.SetState("Active", getConfiguredDuration("RoundLength", context.Config.RoundLength))
	rollRoundModifiers()

	context.Services.ResultService.Reset()
	context.Services.PlayerService.ResetForRound()

	local npcs = context.Services.NPCService.SpawnRoundNPCs()
	context.Services.AlienService.SelectAliens(npcs)
	context.Services.ClueService.GenerateCluesForRound()
	context.Services.RemoteService.BroadcastRoundState()
	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.BroadcastClueSnapshot()
	context.Services.RemoteService.BroadcastSuspectSnapshot()
	scheduleDebugAlienReveal()
	scheduleNestingWarningSigns()

	print("[RoundService] Round started:", context.Round.Number)
end

function RoundService.EndRound(reason)
	if context.Round.State == "Results" then
		return context.Results.RoundOutcome
	end

	activeRoundEnded = true
	RoundService.SetState("Results")
	return context.Services.ResultService.EndRound(reason or "Unknown")
end

function RoundService.CheckForPlayersWin()
	if context.Round.State == "Active" and context.Services.AlienService.AreAllAliensEliminated() then
		RoundService.EndRound("AllAliensEliminated")
	end
end

function RoundService.RunLoop()
	while running do
		RoundService.WaitForMinimumPlayers()

		if not running then
			return
		end

		if not RoundService.Countdown("Intermission", getConfiguredDuration("IntermissionLength", context.Config.IntermissionLength)) then
			return
		end

		if context.Round.State ~= "Active" then
			RoundService.StartRound()
		end

		if not RoundService.Countdown("Active", getConfiguredDuration("RoundLength", context.Config.RoundLength)) then
			return
		end

		if not activeRoundEnded then
			RoundService.EndRound("TimeExpired")
		end

		RoundService.Countdown("Results", getConfiguredDuration("ResultsLength", context.Config.ResultsLength))
	end
end

function RoundService.GetState()
	return context.Round.State
end

function RoundService.HasModifier(modifierName)
	local modifiers = context.Round.Modifiers or {}
	local modifier = modifiers[modifierName]

	return modifier and modifier.Active == true
end

function RoundService.GetModifier(modifierName)
	local modifiers = context.Round.Modifiers or {}

	return modifiers[modifierName]
end

function RoundService.SetModifierState(modifierName, values)
	local modifiers = context.Round.Modifiers or {}
	local modifier = modifiers[modifierName]

	if not modifier then
		return nil
	end

	for key, value in pairs(values or {}) do
		modifier[key] = value
	end

	return modifier
end

function RoundService.GetRoundModifiers()
	return context.Round.Modifiers or {}
end

function RoundService.DebugSkipToActiveRound(reason)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return false
	end

	if context.Round.State == "Active" then
		return false
	end

	print("[RoundService] Debug skip to active:", reason or "Debug")
	RoundService.StartRound()

	return true
end

return RoundService
