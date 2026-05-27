local PlayerService = {}

local Players = game:GetService("Players")

local context
local playerRecords = {}
local healthConnections = {}
local nextClassIndex = 1
local mimicConversionsThisRound = 0
local random = Random.new()

local function getClassDefinition(className)
	return context.Config.ClassDefinitions[className] or context.Config.ClassDefinitions[context.Config.DefaultPlayerClass]
end

local function isValidClass(className)
	return type(className) == "string" and context.Config.ClassDefinitions[className] ~= nil
end

local function getRecord(player)
	local record = playerRecords[player]

	if not record then
		local classOrder = context.Config.ClassAssignmentOrder or {}
		local className = classOrder[nextClassIndex] or context.Config.DefaultPlayerClass
		local classDefinition = getClassDefinition(className)

		record = {
			ClassName = className,
			ClassDisplayName = classDefinition.DisplayName or className,
			Downed = false,
			IsEliminated = false,
			IsMimic = false,
			OriginalClass = nil,
			ConvertedAt = nil,
			MimicKills = 0,
			LastReviveAt = 0,
			LastMimicAttackAt = 0
		}

		nextClassIndex = (nextClassIndex % math.max(#classOrder, 1)) + 1
		playerRecords[player] = record
	end

	return record
end

local function disconnectHealth(player)
	if healthConnections[player] then
		healthConnections[player]:Disconnect()
		healthConnections[player] = nil
	end
end

local function destroyRevivePrompt(record)
	if record.RevivePrompt then
		record.RevivePrompt:Destroy()
		record.RevivePrompt = nil
	end
end

local function getHumanoid(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function buildPlayerSnapshot(player)
	local record = getRecord(player)
	local humanoid = getHumanoid(player)

	return {
		ClassName = record.ClassName,
		ClassDisplayName = record.ClassDisplayName,
		Health = humanoid and math.floor(humanoid.Health + 0.5) or 0,
		MaxHealth = humanoid and math.floor(humanoid.MaxHealth + 0.5) or 0,
		Downed = record.Downed == true,
		IsEliminated = record.IsEliminated == true,
		IsMimic = record.IsMimic == true,
		MimicKills = record.MimicKills or 0,
		MimicObjective = record.IsMimic and ((context.Config.MimicConversion or {}).ObjectiveText or "NEW OBJECTIVE: ELIMINATE THE PARTY") or nil
	}
end

local function applyCharacterStats(player, preserveHealthRatio)
	local humanoid = getHumanoid(player)

	if not humanoid then
		return
	end

	local record = getRecord(player)
	local classDefinition = getClassDefinition(record.ClassName)
	local baseStats = context.Config.PlayerBaseStats or {}
	local downedConfig = context.Config.DownedPlayers or {}
	local mimicConfig = context.Config.MimicConversion or {}
	local maxHealth = (baseStats.MaxHealth or 100) + (classDefinition.MaxHealthBonus or 0)
	local walkSpeed = (baseStats.WalkSpeed or 16) + (classDefinition.WalkSpeedBonus or 0)
	local healthRatio = 1

	if record.IsMimic then
		maxHealth = mimicConfig.MimicHealth or maxHealth
		walkSpeed = mimicConfig.MimicWalkSpeed or walkSpeed
	end

	if preserveHealthRatio and humanoid.MaxHealth > 0 then
		healthRatio = humanoid.Health / humanoid.MaxHealth
	end

	humanoid.MaxHealth = maxHealth
	humanoid.Health = math.clamp(maxHealth * healthRatio, 0, maxHealth)
	humanoid.WalkSpeed = record.IsEliminated and 0 or (record.Downed and (downedConfig.WalkSpeed or 3) or walkSpeed)
end

local function applyAliveWalkSpeed(player)
	local humanoid = getHumanoid(player)

	if not humanoid then
		return
	end

	local record = getRecord(player)
	local classDefinition = getClassDefinition(record.ClassName)
	local baseStats = context.Config.PlayerBaseStats or {}
	local mimicConfig = context.Config.MimicConversion or {}

	if record.IsMimic then
		humanoid.WalkSpeed = mimicConfig.MimicWalkSpeed or 18
	else
		humanoid.WalkSpeed = (baseStats.WalkSpeed or 16) + (classDefinition.WalkSpeedBonus or 0)
	end
end

local function canUseDownedSystem()
	local downedConfig = context.Config.DownedPlayers or {}

	return downedConfig.Enabled == true and context.Round and context.Round.State == "Active"
end

local function sendDownedWarning(player)
	local downedConfig = context.Config.DownedPlayers or {}

	context.Services.RemoteService.SendMissionWarning(player, {
		Text = downedConfig.SelfDownedWarning or "YOU ARE DOWN: wait for a teammate revive.",
		Severity = "Downed",
		ScreenPulse = true,
		ScreenPulseDuration = 0.8
	})

	context.Services.RemoteService.BroadcastMissionWarning({
		Text = (downedConfig.DownedWarning or "OPERATIVE DOWN: teammate needs help.") .. " " .. player.Name,
		Severity = "Downed",
		ScreenPulse = true,
		ScreenPulseDuration = 0.45
	})
end

local function getActiveNonMimicSurvivorCount(excludePlayer)
	local survivorCount = 0

	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate ~= excludePlayer then
			local record = getRecord(candidate)
			local humanoid = getHumanoid(candidate)

			if not record.IsMimic and not record.IsEliminated and not record.Downed and humanoid and humanoid.Health > 0 then
				survivorCount += 1
			end
		end
	end

	return survivorCount
end

local function shouldAllowMimicRoll(player)
	local mimicConfig = context.Config.MimicConversion or {}

	if mimicConfig.Enabled ~= true then
		return false
	end

	if mimicConversionsThisRound >= (mimicConfig.MaxMimicPlayersPerRound or 1) then
		return false
	end

	if getActiveNonMimicSurvivorCount(player) < (mimicConfig.RequiresMinimumSurvivors or 2) then
		return false
	end

	local roundLength = context.Config.RoundLength or 300
	local timeRemaining = context.Round.TimeRemaining or roundLength
	local midRoundReached = timeRemaining <= roundLength * 0.5
	local alienRevealed = context.Services.AlienService and context.Services.AlienService.GetRevealedCount() > 0

	return alienRevealed or midRoundReached
end

local function applyMimicStats(player)
	local record = getRecord(player)
	local humanoid = getHumanoid(player)
	local mimicConfig = context.Config.MimicConversion or {}

	if not humanoid then
		return
	end

	humanoid.MaxHealth = mimicConfig.MimicHealth or 90
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = mimicConfig.MimicWalkSpeed or 18
	record.Downed = false
	record.IsEliminated = false
	destroyRevivePrompt(record)
end

local function convertToMimic(player)
	local record = getRecord(player)
	local mimicConfig = context.Config.MimicConversion or {}

	if context.Round.State ~= "Active" or record.IsMimic or not record.IsEliminated then
		return false
	end

	if not shouldAllowMimicRoll(player) then
		return false
	end

	record.IsMimic = true
	record.IsEliminated = false
	record.Downed = false
	record.ConvertedAt = os.clock()
	record.OriginalClass = record.OriginalClass or record.ClassName
	record.MimicKills = record.MimicKills or 0
	mimicConversionsThisRound += 1

	if not getHumanoid(player) then
		player:LoadCharacter()
	end

	applyMimicStats(player)
	PlayerService.SendSnapshot(player)

	context.Services.RemoteService.SendMissionWarning(player, {
		Text = mimicConfig.MimicAwakenedText or "MIMIC HOST ONLINE: stay hidden, isolate, strike.",
		Severity = "Mimic",
		ScreenPulse = true,
		ScreenPulseDuration = 1
	})

	print("[PlayerService] Mimic converted:", player.Name)
	context.Services.ResultService.CheckForAliensWin()

	return true
end

local function tryScheduleMimicConversion(player)
	local mimicConfig = context.Config.MimicConversion or {}

	if not shouldAllowMimicRoll(player) then
		return
	end

	if random:NextNumber() > (mimicConfig.Chance or 0.2) then
		return
	end

	task.delay(mimicConfig.ConversionDelay or 4, function()
		convertToMimic(player)
	end)
end

local function eliminatePlayer(player, reason)
	local record = getRecord(player)

	if record.IsEliminated or record.IsMimic then
		return false
	end

	local humanoid = getHumanoid(player)
	local mimicConfig = context.Config.MimicConversion or {}

	record.Downed = false
	record.IsEliminated = true
	record.EliminatedAt = os.clock()
	destroyRevivePrompt(record)

	if humanoid then
		humanoid.Health = math.max(1, humanoid.Health)
		humanoid.WalkSpeed = 0
	end

	PlayerService.SendSnapshot(player)
	context.Services.RemoteService.BroadcastMissionWarning({
		Text = (mimicConfig.ConversionWarning or "SIGNAL LOST: operative vitals went dark.") .. " " .. player.Name,
		Severity = "Eliminated"
	})
	tryScheduleMimicConversion(player)
	context.Services.ResultService.CheckForAliensWin()

	print("[PlayerService] Player eliminated:", player.Name, reason or "Unknown")

	return true
end

local function scheduleDownedElimination(player, roundNumber)
	local downedConfig = context.Config.DownedPlayers or {}
	local eliminationDelay = downedConfig.EliminationDelay or 18

	task.delay(eliminationDelay, function()
		local record = getRecord(player)

		if context.Round.State ~= "Active" or context.Round.Number ~= roundNumber then
			return
		end

		if record.Downed and not record.IsEliminated and not record.IsMimic then
			eliminatePlayer(player, "ReviveWindowExpired")
		end
	end)
end

local function createRevivePrompt(player, record)
	local root = getRoot(player)
	local downedConfig = context.Config.DownedPlayers or {}

	if not root then
		return
	end

	destroyRevivePrompt(record)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RevivePrompt"
	prompt.ActionText = downedConfig.PromptActionText or "Revive"
	prompt.ObjectText = downedConfig.PromptObjectText or "Downed Teammate"
	prompt.HoldDuration = downedConfig.ReviveHoldDuration or 2.75
	prompt.MaxActivationDistance = downedConfig.ReviveRange or 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	record.RevivePrompt = prompt

	prompt.Triggered:Connect(function(reviver)
		PlayerService.RevivePlayer(reviver, player)
	end)
end

local function markDowned(player)
	if not canUseDownedSystem() then
		return false
	end

	local record = getRecord(player)

	if record.IsMimic or record.IsEliminated then
		return false
	end

	if record.Downed then
		return true
	end

	local humanoid = getHumanoid(player)

	if not humanoid then
		return false
	end

	local downedConfig = context.Config.DownedPlayers or {}
	record.Downed = true
	record.DownedAt = os.clock()
	humanoid.Health = math.max(1, downedConfig.DownHealth or 1)
	humanoid.WalkSpeed = downedConfig.WalkSpeed or 3
	createRevivePrompt(player, record)
	PlayerService.SendSnapshot(player)
	sendDownedWarning(player)
	scheduleDownedElimination(player, context.Round.Number)
	context.Services.ResultService.CheckForAliensWin()

	return true
end

local function bindCharacter(player)
	disconnectHealth(player)
	local record = getRecord(player)
	record.Downed = false
	record.DownedAt = nil
	destroyRevivePrompt(record)
	applyCharacterStats(player)

	local humanoid = getHumanoid(player)

	if humanoid then
		humanoid.BreakJointsOnDeath = false

		healthConnections[player] = humanoid.HealthChanged:Connect(function(health)
			local downedConfig = context.Config.DownedPlayers or {}

			if record.Downed and health <= 0 then
				humanoid.Health = math.max(1, downedConfig.DownHealth or 1)
			elseif record.IsMimic and health <= 0 then
				humanoid.Health = 1
			elseif health <= 0 and canUseDownedSystem() then
				markDowned(player)
			end

			PlayerService.SendSnapshot(player)
		end)
	end

	PlayerService.SendSnapshot(player)
end

local function setupPlayer(player)
	getRecord(player)

	player.CharacterAdded:Connect(function()
		bindCharacter(player)
	end)

	if player.Character then
		bindCharacter(player)
	else
		PlayerService.SendSnapshot(player)
	end
end

function PlayerService.Init(sharedContext)
	context = sharedContext
	context.Players = playerRecords
end

function PlayerService.Start()
	print("[PlayerService] Ready")

	context.Services.RemoteService.BindClassSelectionHandler(function(player, className)
		return PlayerService.SetPlayerClass(player, className)
	end)

	context.Services.RemoteService.BindMimicActionHandler(function(player, actionName)
		return PlayerService.UseMimicAction(player, actionName)
	end)

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		disconnectHealth(player)
		destroyRevivePrompt(getRecord(player))
		playerRecords[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
end

function PlayerService.GetPlayerClass(player)
	return getRecord(player).ClassName
end

function PlayerService.GetClassDefinition(player)
	return getClassDefinition(PlayerService.GetPlayerClass(player))
end

function PlayerService.GetCombatDamageMultiplier(player)
	local classDefinition = PlayerService.GetClassDefinition(player)

	return classDefinition.CombatDamageMultiplier or 1
end

function PlayerService.ResetForRound()
	mimicConversionsThisRound = 0
	random = Random.new(context.Config.RandomSeed)

	for _, player in ipairs(Players:GetPlayers()) do
		local record = getRecord(player)
		record.Downed = false
		record.IsEliminated = false
		record.IsMimic = false
		record.ConvertedAt = nil
		record.OriginalClass = nil
		record.MimicKills = 0
		record.LastMimicAttackAt = 0
		destroyRevivePrompt(record)

		if player.Character then
			applyCharacterStats(player)
		end

		PlayerService.SendSnapshot(player)
	end
end

function PlayerService.SetPlayerClass(player, className)
	local record = getRecord(player)

	if record.IsMimic or record.IsEliminated then
		return {
			Accepted = false,
			Reason = "ClassLocked",
			ClassName = PlayerService.GetPlayerClass(player)
		}
	end

	if not isValidClass(className) then
		return {
			Accepted = false,
			Reason = "InvalidClass",
			ClassName = PlayerService.GetPlayerClass(player)
		}
	end

	local classDefinition = context.Config.ClassDefinitions[className]

	record.ClassName = className
	record.ClassDisplayName = classDefinition.DisplayName or className

	if player.Character then
		applyCharacterStats(player, true)
	end

	PlayerService.SendSnapshot(player)

	print("[PlayerService] Class selected:", player.Name, className)

	return {
		Accepted = true,
		ClassName = record.ClassName,
		ClassDisplayName = record.ClassDisplayName
	}
end

function PlayerService.GetPublicSnapshot(player)
	return buildPlayerSnapshot(player)
end

function PlayerService.IsPlayerDowned(player)
	return getRecord(player).Downed == true
end

function PlayerService.IsPlayerEliminated(player)
	return getRecord(player).IsEliminated == true
end

function PlayerService.IsMimicPlayer(player)
	return getRecord(player).IsMimic == true
end

function PlayerService.IsPlayerActive(player)
	local humanoid = getHumanoid(player)
	local record = getRecord(player)

	return humanoid ~= nil and humanoid.Health > 0 and not record.Downed and not record.IsEliminated
end

function PlayerService.AreAllPlayersDownedOrEliminated()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and not PlayerService.IsMimicPlayer(player) and PlayerService.IsPlayerActive(player) then
			return false
		end
	end

	return true
end

function PlayerService.HasActiveMimicPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.IsMimicPlayer(player) and PlayerService.IsPlayerActive(player) then
			return true
		end
	end

	return false
end

function PlayerService.DownPlayer(player)
	return markDowned(player)
end

function PlayerService.RevivePlayer(reviver, target)
	local downedConfig = context.Config.DownedPlayers or {}

	if downedConfig.Enabled ~= true then
		return {
			Accepted = false,
			Reason = "ReviveDisabled"
		}
	end

	if context.Round.State ~= "Active" then
		return {
			Accepted = false,
			Reason = "RoundNotActive"
		}
	end

	if not reviver or not target or reviver == target then
		return {
			Accepted = false,
			Reason = "InvalidReviveTarget"
		}
	end

	if PlayerService.IsPlayerDowned(reviver) or PlayerService.IsPlayerEliminated(reviver) or PlayerService.IsMimicPlayer(reviver) then
		return {
			Accepted = false,
			Reason = "ReviverDowned"
		}
	end

	local targetRecord = getRecord(target)

	if targetRecord.IsEliminated or targetRecord.IsMimic then
		return {
			Accepted = false,
			Reason = "TargetEliminated"
		}
	end

	if not targetRecord.Downed then
		return {
			Accepted = false,
			Reason = "TargetNotDowned"
		}
	end

	local now = os.clock()
	local reviverRecord = getRecord(reviver)
	local cooldown = downedConfig.ReviveCooldown or 1.5

	if now - (reviverRecord.LastReviveAt or 0) < cooldown then
		return {
			Accepted = false,
			Reason = "ReviveCooldown"
		}
	end

	local reviverRoot = getRoot(reviver)
	local targetRoot = getRoot(target)
	local targetHumanoid = getHumanoid(target)

	if not reviverRoot or not targetRoot or not targetHumanoid then
		return {
			Accepted = false,
			Reason = "MissingCharacter"
		}
	end

	local distance = (reviverRoot.Position - targetRoot.Position).Magnitude

	if distance > (downedConfig.ReviveRange or 12) then
		return {
			Accepted = false,
			Reason = "TooFar"
		}
	end

	reviverRecord.LastReviveAt = now
	targetRecord.Downed = false
	targetRecord.DownedAt = nil
	destroyRevivePrompt(targetRecord)
	applyAliveWalkSpeed(target)

	local reviveHealth = downedConfig.ReviveHealth or 45

	if PlayerService.GetPlayerClass(reviver) == "Medic" then
		reviveHealth = downedConfig.MedicReviveHealth or reviveHealth
	end

	targetHumanoid.Health = math.clamp(reviveHealth, 1, targetHumanoid.MaxHealth)
	PlayerService.SendSnapshot(target)
	PlayerService.SendSnapshot(reviver)

	context.Services.RemoteService.BroadcastMissionWarning({
		Text = (downedConfig.RevivedWarning or "OPERATIVE REVIVED: teammate back on feet.") .. " " .. target.Name,
		Severity = "Revived"
	})

	return {
		Accepted = true,
		Target = target.Name,
		Health = targetHumanoid.Health
	}
end

function PlayerService.UseMimicAction(player, actionName)
	local record = getRecord(player)
	local mimicConfig = context.Config.MimicConversion or {}

	if context.Round.State ~= "Active" then
		return {
			Accepted = false,
			Reason = "RoundNotActive"
		}
	end

	if actionName ~= nil and actionName ~= "Attack" then
		return {
			Accepted = false,
			Reason = "UnknownMimicAction"
		}
	end

	if not record.IsMimic or record.IsEliminated or record.Downed then
		return {
			Accepted = false,
			Reason = "NotMimic"
		}
	end

	local now = os.clock()
	local cooldown = mimicConfig.MimicAttackCooldown or 4

	if now - (record.LastMimicAttackAt or 0) < cooldown then
		return {
			Accepted = false,
			Reason = "MimicCooldown",
			CooldownRemaining = math.max(0, cooldown - (now - (record.LastMimicAttackAt or 0)))
		}
	end

	local root = getRoot(player)

	if not root then
		return {
			Accepted = false,
			Reason = "NoCharacter"
		}
	end

	local range = mimicConfig.MimicAttackRange or 9
	local damage = mimicConfig.MimicDamage or 28
	local closestPlayer
	local closestHumanoid
	local closestDistance = range

	for _, candidate in ipairs(Players:GetPlayers()) do
		local candidateRecord = getRecord(candidate)
		local candidateRoot = getRoot(candidate)
		local candidateHumanoid = getHumanoid(candidate)

		if candidate ~= player
			and not candidateRecord.IsMimic
			and not candidateRecord.IsEliminated
			and not candidateRecord.Downed
			and candidateRoot
			and candidateHumanoid
			and candidateHumanoid.Health > 0
		then
			local distance = (candidateRoot.Position - root.Position).Magnitude

			if distance <= closestDistance then
				closestPlayer = candidate
				closestHumanoid = candidateHumanoid
				closestDistance = distance
			end
		end
	end

	if not closestPlayer or not closestHumanoid then
		return {
			Accepted = false,
			Reason = "NoTargetInRange"
		}
	end

	record.LastMimicAttackAt = now

	if closestHumanoid.Health - damage <= 0 and PlayerService.DownPlayer(closestPlayer) then
		record.MimicKills = (record.MimicKills or 0) + 1
	else
		closestHumanoid:TakeDamage(damage)
	end

	PlayerService.SendSnapshot(player)
	PlayerService.SendSnapshot(closestPlayer)
	context.Services.RemoteService.SendMissionWarning(player, {
		Text = "MIMIC STRIKE LANDED: " .. closestPlayer.Name,
		Severity = "Mimic"
	})
	context.Services.ResultService.CheckForAliensWin()

	return {
		Accepted = true,
		Action = "Attack",
		Target = closestPlayer.Name,
		Damage = damage,
		Distance = closestDistance,
		Cooldown = cooldown
	}
end

function PlayerService.SendSnapshot(player)
	if not context or not context.Services.RemoteService then
		return
	end

	context.Services.RemoteService.SendPlayerSnapshot(player, buildPlayerSnapshot(player))
end

return PlayerService
