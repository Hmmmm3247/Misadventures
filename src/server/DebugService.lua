local DebugService = {}

local context
local lastCommandByPlayer = {}

local function getDebugConfig()
	return context.Config.DebugTesting or {}
end

local function isEnabled()
	local debugConfig = getDebugConfig()

	return debugConfig.Enabled == true and debugConfig.ControlsEnabled == true
end

local function reject(reason, extra)
	local result = extra or {}
	result.Accepted = false
	result.Reason = reason

	return result
end

local function checkCooldown(player)
	local debugConfig = getDebugConfig()
	local cooldown = debugConfig.CommandCooldown or 0.5
	local now = os.clock()
	local lastCommand = lastCommandByPlayer[player] or 0

	if now - lastCommand < cooldown then
		return false, math.max(0, cooldown - (now - lastCommand))
	end

	lastCommandByPlayer[player] = now

	return true, 0
end

function DebugService.Init(sharedContext)
	context = sharedContext
end

function DebugService.Start()
	print("[DebugService] Ready")

	context.Services.RemoteService.BindDebugCommandHandler(function(player, command)
		return DebugService.RunCommand(player, command)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastCommandByPlayer[player] = nil
	end)
end

function DebugService.RunCommand(player, command)
	if not isEnabled() then
		return reject("DebugDisabled")
	end

	if typeof(command) ~= "string" then
		return reject("InvalidCommand")
	end

	local allowed, remaining = checkCooldown(player)

	if not allowed then
		return reject("DebugCooldown", {
			CooldownRemaining = remaining
		})
	end

	if command == "RevealFirstAlien" then
		local record = context.Services.AlienService.DebugRevealFirstAlien("DebugCommand")

		return {
			Accepted = record ~= nil,
			Command = command,
			Message = record and ("Debug revealed " .. record.NPCId) or "No hidden alien available"
		}
	elseif command == "RevealAllAliens" then
		local count = context.Services.AlienService.DebugRevealAllAliens("DebugCommand")

		return {
			Accepted = true,
			Command = command,
			Message = "Debug revealed aliens: " .. tostring(count)
		}
	elseif command == "SkipToActive" then
		local started = context.Services.RoundService.DebugSkipToActiveRound("DebugCommand")

		return {
			Accepted = started,
			Command = command,
			Message = started and "Debug skipped to active round" or "Round already active"
		}
	elseif command == "ForceWrongPenalty" then
		local result = context.Services.AccusationService.DebugForceWrongAccusationPenalty(player)

		return {
			Accepted = true,
			Command = command,
			Message = "Debug wrong accusation penalty applied",
			Result = result
		}
	elseif command == "SpawnChaseTestAlien" then
		local record = context.Services.AlienService.DebugSpawnChaseTestAlien(player)

		return {
			Accepted = record ~= nil,
			Command = command,
			Message = record and ("Debug chase test ready: " .. record.NPCId) or "No alien available for chase test"
		}
	elseif command == "PrintAggression" then
		local snapshot = context.Services.AlienService.GetAggressionSnapshot()

		print(
			"[DebugService] Aggression:",
			"attack=" .. tostring(snapshot.AttackMultiplier),
			"chase=" .. tostring(snapshot.ChaseMultiplier),
			"remaining=" .. tostring(snapshot.Remaining)
		)

		context.Services.RemoteService.SendMissionWarning(player, {
			Text = "DEBUG AGGRESSION: attack "
				.. tostring(snapshot.AttackMultiplier)
				.. " / chase "
				.. tostring(snapshot.ChaseMultiplier)
				.. " / remaining "
				.. tostring(math.floor(snapshot.Remaining + 0.5))
				.. "s",
			Severity = "Debug"
		})

		return {
			Accepted = true,
			Command = command,
			Message = "Debug aggression printed",
			Snapshot = snapshot
		}
	end

	return reject("UnknownCommand")
end

return DebugService
