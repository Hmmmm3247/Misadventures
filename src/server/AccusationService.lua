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

local function applyWrongAccusationConsequences(reason)
	local penaltyConfig = context.Config.WrongAccusation or {}
	local timePenalty = penaltyConfig.TimePenalty or 0

	if timePenalty > 0 then
		context.Services.RoundService.ApplyTimePenalty(timePenalty, reason or "WrongAccusation")
	end

	context.Services.AlienService.BoostAggression(
		penaltyConfig.AggressionDuration or 0,
		penaltyConfig.AggressionMultiplier or 1,
		penaltyConfig.ChaseAggressionMultiplier or penaltyConfig.AggressionMultiplier or 1
	)

	if context.Services.MapEventService then
		context.Services.MapEventService.TriggerAlarmPulse(reason or "WrongAccusation")
	end

	task.defer(function()
		context.Services.RemoteService.BroadcastMissionWarning({
			Text = penaltyConfig.Warning or "FALSE TARGET. ENTITY AGGRESSION RISING.",
			Severity = "Emergency",
			ScreenPulse = true,
			ScreenPulseDuration = penaltyConfig.ScreenPulseDuration or 0.75
		})
	end)

	return {
		TimePenalty = timePenalty,
		AggressionDuration = penaltyConfig.AggressionDuration or 0,
		AggressionMultiplier = penaltyConfig.AggressionMultiplier or 1,
		ChaseAggressionMultiplier = penaltyConfig.ChaseAggressionMultiplier or penaltyConfig.AggressionMultiplier or 1
	}
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
		local suspicionConfig = context.Config.NPCSuspicion or {}
		context.Services.NPCService.AddSuspicion(npcId, suspicionConfig.WrongAccusationAmount or 10, "WrongAccusation")
		applyWrongAccusationConsequences("WrongAccusation")
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

function AccusationService.DebugForceWrongAccusationPenalty(player)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return nil
	end

	print("[AccusationService] Debug force wrong accusation penalty:", player and player.Name or "Unknown")

	return applyWrongAccusationConsequences("DebugWrongAccusation")
end

return AccusationService
