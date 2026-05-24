local AccusationService = {}

local context
local lastAccusationByPlayer = {}

local function reject(player, reason, npcId)
	local result = {
		Accepted = false,
		Reason = reason,
		NPCId = npcId
	}

	if player then
		context.Services.RemoteService.SendAccusationResult(player, result)
	end

	return result
end

local function getRiskReason(matchSummary)
	if matchSummary.Total == 0 then
		return "No discovered clues supported this accusation"
	end

	if matchSummary.Matched == matchSummary.Total then
		return "The suspect matched every discovered clue"
	end

	return "Matched " .. matchSummary.Matched .. " of " .. matchSummary.Total .. " discovered clues"
end

function AccusationService.Init(sharedContext)
	context = sharedContext
end

function AccusationService.Start()
	print("[AccusationService] Ready")
	context.Services.RemoteService.BindAccusationHandler(function(player, npcId)
		return AccusationService.SubmitAccusation(player, npcId)
	end)
end

function AccusationService.Accuse(player, npcId)
	if context.Round.State ~= "Active" then
		return reject(player, "RoundNotActive", npcId)
	end

	if typeof(npcId) ~= "string" then
		return reject(player, "InvalidNPC", npcId)
	end

	local now = os.clock()
	local lastAccusation = lastAccusationByPlayer[player] or 0

	if now - lastAccusation < context.Config.AccusationCooldown then
		return reject(player, "AccusationCooldown", npcId)
	end

	local npc = context.Services.NPCService.GetNPCById(npcId)

	if not npc then
		return reject(player, "UnknownNPC", npcId)
	end

	if context.Services.NPCService.IsRevealed(npcId) then
		return reject(player, "AlreadyRevealed", npcId)
	end

	lastAccusationByPlayer[player] = now

	local isAlien = context.Services.AlienService.IsAlien(npcId)
	local discoveredTraits = context.Services.ClueService.GetDiscoveredTraits()
	local matchSummary = context.Services.NPCService.GetTraitMatchSummary(npcId, discoveredTraits)
	local result = {
		Accepted = true,
		Player = player,
		NPCId = npcId,
		Correct = isAlien,
		MatchedTraits = matchSummary.Matched,
		TotalTraits = matchSummary.Total
	}

	if isAlien then
		local alienRecord = context.Services.AlienService.RevealAlien(npcId)
		context.Services.NPCService.MarkRevealed(npcId, alienRecord.AlienType)
		context.Services.RemoteService.BroadcastNPCRevealed(context.Services.AlienService.GetPublicReveal(npcId))
		context.Services.RemoteService.BroadcastNPCSnapshot()
		context.Services.RemoteService.BroadcastSuspectSnapshot()
		context.Services.RemoteService.BroadcastRoundState()
	else
		local penaltyConfig = context.Config.WrongAccusation or {}
		local timePenalty = penaltyConfig.TimePenalty or 0

		if timePenalty > 0 then
			context.Services.RoundService.ApplyTimePenalty(timePenalty, "WrongAccusation")
		end

		context.Services.AlienService.BoostAggression(penaltyConfig.AggressionDuration or 0, penaltyConfig.AggressionMultiplier or 1)

		task.defer(function()
			context.Services.RemoteService.BroadcastMissionWarning({
				Text = penaltyConfig.Warning or "FALSE TARGET. ENTITY AGGRESSION RISING.",
				Severity = "Warning"
			})
		end)
	end

	context.Services.ResultService.RecordAccusation(result)
	context.Services.RemoteService.SendAccusationResult(player, {
		Accepted = result.Accepted,
		NPCId = result.NPCId,
		Correct = result.Correct,
		MatchedTraits = result.MatchedTraits,
		TotalTraits = result.TotalTraits,
		RiskReason = getRiskReason(matchSummary)
	})

	if isAlien then
		context.Services.RoundService.CheckForPlayersWin()
	end

	return result
end

function AccusationService.SubmitAccusation(player, npcId)
	local result = AccusationService.Accuse(player, npcId)

	return {
		Accepted = result.Accepted,
		Reason = result.Reason,
		NPCId = result.NPCId,
		Correct = result.Correct
	}
end

return AccusationService
