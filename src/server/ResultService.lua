local ResultService = {}

local Players = game:GetService("Players")

local context
local results = {
	Accusations = {},
	RoundOutcome = nil
}

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

local function buildRevealedAliensSummary()
	local enriched = {}

	for _, entry in ipairs(context.Services.AlienService.GetPublicRevealedAliens()) do
		local npc = context.Services.NPCService.GetNPCById(entry.NPCId)
		table.insert(enriched, {
			NPCId = entry.NPCId,
			DisplayName = npc and npc.DisplayName or entry.NPCId,
			AlienType = entry.AlienType,
			Eliminated = entry.Eliminated,
			Escaped = entry.Escaped,
			IsJuvenile = entry.IsJuvenile
		})
	end

	return enriched
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

	local wrongCount = 0
	local correctCount = 0

	for _, acc in ipairs(results.Accusations) do
		if acc.Correct then
			correctCount += 1
		else
			wrongCount += 1
		end
	end

	results.RoundOutcome = {
		Reason = reason,
		Winner = reason == "AllAliensEliminated" and "Players" or "Aliens",
		RevealedAliens = buildRevealedAliensSummary(),
		RoundModifiers = context.Services.RoundService.GetRoundModifiers(),
		AccusationCount = #results.Accusations,
		CorrectAccusations = correctCount,
		WrongAccusations = wrongCount
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

	if context.Services.AlienService.HasEscapedAlien() then
		return context.Services.RoundService.EndRound("AlienEscaped")
	end

	if getCharacterCount() > 0 and context.Services.PlayerService.AreAllPlayersDownedOrEliminated() then
		return context.Services.RoundService.EndRound("AllPlayersDown")
	end

	return nil
end

function ResultService.CheckForPlayersWin()
	if context.Round.State == "Active"
		and context.Services.AlienService.AreAllAliensEliminated()
		and not context.Services.PlayerService.HasActiveMimicPlayers()
	then
		return context.Services.RoundService.EndRound("AllAliensEliminated")
	end

	return nil
end

function ResultService.GetResults()
	return results
end

return ResultService
