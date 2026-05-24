local RoundService = {}

local Players = game:GetService("Players")

local context
local running = false
local activeRoundEnded = false

function RoundService.Init(sharedContext)
	context = sharedContext
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
	while running and #Players:GetPlayers() < context.Config.MinPlayers do
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
	context.Round.Number += 1
	activeRoundEnded = false
	RoundService.SetState("Active", context.Config.RoundLength)

	context.Services.ResultService.Reset()

	local npcs = context.Services.NPCService.SpawnRoundNPCs()
	context.Services.AlienService.SelectAliens(npcs)
	context.Services.ClueService.GenerateCluesForRound()
	context.Services.RemoteService.BroadcastRoundState()
	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.BroadcastClueSnapshot()
	context.Services.RemoteService.BroadcastSuspectSnapshot()

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

		if not RoundService.Countdown("Intermission", context.Config.IntermissionLength) then
			return
		end

		RoundService.StartRound()

		if not RoundService.Countdown("Active", context.Config.RoundLength) then
			return
		end

		if not activeRoundEnded then
			RoundService.EndRound("TimeExpired")
		end

		RoundService.Countdown("Results", context.Config.ResultsLength)
	end
end

function RoundService.GetState()
	return context.Round.State
end

return RoundService
