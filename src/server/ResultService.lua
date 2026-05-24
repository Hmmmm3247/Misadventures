local ResultService = {}

local Players = game:GetService("Players")

local context
local results = {
	Accusations = {},
	RoundOutcome = nil
}

local function isPlayerAlive(player)
	local character = player.Character

	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	return humanoid ~= nil and humanoid.Health > 0
end

local function getAlivePlayerCount()
	local aliveCount = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if isPlayerAlive(player) then
			aliveCount += 1
		end
	end

	return aliveCount
end

local function getCharacterCount()
	local characterCount = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			characterCount += 1
		end
	end

	return characterCount
end

function ResultService.Init(sharedContext)
	context = sharedContext
	context.Results = results
end

function ResultService.Start()
	print("[ResultService] Ready")
end

function ResultService.Reset()
	table.clear(results.Accusations)
	results.RoundOutcome = nil
end

function ResultService.RecordAccusation(accusation)
	table.insert(results.Accusations, accusation)
	print("[ResultService] Accusation recorded:", accusation.NPCId, accusation.Correct)
end

function ResultService.EndRound(reason)
	if results.RoundOutcome then
		return results.RoundOutcome
	end

	context.Services.AlienService.RevealAll()

	for _, reveal in ipairs(context.Services.AlienService.GetPublicRevealedAliens()) do
		context.Services.NPCService.MarkRevealed(reveal.NPCId, reveal.AlienType)

		if reveal.Eliminated then
			context.Services.NPCService.MarkEliminated(reveal.NPCId)
		end
	end

	results.RoundOutcome = {
		Reason = reason,
		Winner = reason == "AllAliensEliminated" and "Players" or "Aliens",
		RevealedAliens = context.Services.AlienService.GetPublicRevealedAliens(),
		AccusationCount = #results.Accusations
	}

	print("[ResultService] Round ended:", reason)
	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.BroadcastSuspectSnapshot()
	context.Services.RemoteService.BroadcastRoundResults(results.RoundOutcome)

	return results.RoundOutcome
end

function ResultService.CheckForAliensWin()
	if context.Round.State ~= "Active" then
		return nil
	end

	if #Players:GetPlayers() == 0 then
		return context.Services.RoundService.EndRound("NoPlayersRemaining")
	end

	if getCharacterCount() > 0 and getAlivePlayerCount() == 0 then
		return context.Services.RoundService.EndRound("AllPlayersDown")
	end

	return nil
end

function ResultService.CheckForPlayersWin()
	if context.Round.State == "Active" and context.Services.AlienService.AreAllAliensEliminated() then
		return context.Services.RoundService.EndRound("AllAliensEliminated")
	end

	return nil
end

function ResultService.GetResults()
	return results
end

return ResultService
