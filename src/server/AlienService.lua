local AlienService = {}

local Players = game:GetService("Players")

local context
local alienByNpcId = {}
local alienRecords = {}
local random
local attackLoopRunning = false
local aggressionUntil = 0
local aggressionMultiplier = 1
local chaseAggressionMultiplier = 1
local damageMultiplier = 1

local function getAlienMaxHealth()
	local attackConfig = context.Config.RevealedAlienAttack or {}

	return attackConfig.MaxHealth or 120
end

local function getEscapeConfig()
	return context.Config.AlienEscape or {}
end

local function getRandom()
	if not random then
		random = Random.new(context.Config.RandomSeed)
	end

	return random
end

local function getCharacterRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getLivingHumanoid(player)
	if context.Services.PlayerService and context.Services.PlayerService.IsPlayerDowned(player) then
		return nil
	end

	if context.Services.PlayerService and context.Services.PlayerService.IsMimicPlayer(player) then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return humanoid
end

local function getAlienRoot(record)
	local npc = context.Services.NPCService.GetNPCById(record.NPCId)

	if not npc or not npc.Model then
		return nil
	end

	return npc.Model.PrimaryPart
end

local function getAllowedEscapeNameMap()
	local allowed = {}
	local escapeConfig = getEscapeConfig()

	for _, name in ipairs(escapeConfig.EscapePointNames or {}) do
		allowed[name] = true
	end

	return allowed
end

local function chooseEscapePoint()
	local points = context.Services.MapService.GetEscapePoints and context.Services.MapService.GetEscapePoints() or {}
	local allowed = getAllowedEscapeNameMap()
	local candidates = {}

	for _, point in ipairs(points) do
		if next(allowed) == nil or allowed[point.Name] then
			table.insert(candidates, point)
		end
	end

	if #candidates == 0 then
		candidates = points
	end

	if #candidates == 0 then
		return nil
	end

	return candidates[getRandom():NextInteger(1, #candidates)]
end

local function getNearestLivingPlayer(position, range)
	local nearestPlayer
	local nearestRoot
	local nearestDistance = range

	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = getLivingHumanoid(player)
		local playerRoot = getCharacterRoot(player)

		if humanoid and playerRoot then
			local distance = (playerRoot.Position - position).Magnitude

			if distance <= nearestDistance then
				nearestPlayer = player
				nearestRoot = playerRoot
				nearestDistance = distance
			end
		end
	end

	return nearestPlayer, nearestRoot, nearestDistance
end

local function pivotAlienRootTo(record, rootCFrame)
	local npc = context.Services.NPCService.GetNPCById(record.NPCId)

	if not npc or not npc.Model or not npc.Model.PrimaryPart then
		return
	end

	local pivot = npc.Model:GetPivot()
	local root = npc.Model.PrimaryPart.CFrame
	local pivotToRoot = pivot:ToObjectSpace(root)

	npc.Model:PivotTo(rootCFrame * pivotToRoot:Inverse())
end

local function sendChaseStartWarning(record, player)
	local chaseConfig = context.Config.RevealedAlienChase or {}
	local now = os.clock()

	if not player or record.ChaseTargetPlayer == player then
		return
	end

	record.ChaseTargetPlayer = player

	if now - (record.LastChaseWarningAt or 0) < (chaseConfig.WarningCooldown or 7) then
		return
	end

	record.LastChaseWarningAt = now
	context.Services.RemoteService.SendMissionWarning(player, {
		Text = chaseConfig.StartWarning or "CHASE WARNING: confirmed entity has locked onto you.",
		Severity = "Chase",
		ScreenPulse = true,
		ScreenPulseDuration = chaseConfig.ScreenPulseDuration or 0.75,
		NPCId = record.NPCId
	})
end

local function sendChaseStopWarning(record)
	local chaseConfig = context.Config.RevealedAlienChase or {}
	local player = record.ChaseTargetPlayer

	if not player then
		return
	end

	record.ChaseTargetPlayer = nil
	context.Services.RemoteService.SendMissionWarning(player, {
		Text = chaseConfig.StopWarning or "CHASE UPDATE: entity pursuit signal dropped.",
		Severity = "ChaseClear",
		NPCId = record.NPCId
	})
end

local function chaseNearestPlayer(record, deltaTime)
	local chaseConfig = context.Config.RevealedAlienChase or {}

	if not chaseConfig.Enabled or (record.StunnedUntil or 0) > os.clock() then
		sendChaseStopWarning(record)
		return
	end

	local root = getAlienRoot(record)

	if not root then
		sendChaseStopWarning(record)
		return
	end

	local currentChaseAggression = AlienService.GetChaseAggressionMultiplier()
	local range = (chaseConfig.Range or 55) * currentChaseAggression
	local stopDistance = chaseConfig.StopDistance or 8
	local speed = (chaseConfig.Speed or 10) * currentChaseAggression
	local leashDistance = (chaseConfig.LeashDistance or 72) * currentChaseAggression
	local player, playerRoot, distance = getNearestLivingPlayer(root.Position, range)

	if not playerRoot or not distance or distance > leashDistance then
		sendChaseStopWarning(record)
		return
	end

	sendChaseStartWarning(record, player)

	if distance <= stopDistance then
		return
	end

	local origin = root.Position
	local target = Vector3.new(playerRoot.Position.X, origin.Y, playerRoot.Position.Z)
	local direction = target - origin

	if direction.Magnitude < 0.1 then
		return
	end

	local stepDistance = math.min(speed * deltaTime, math.max(0, direction.Magnitude - stopDistance))
	local nextPosition = origin + direction.Unit * stepDistance
	local nextCFrame = CFrame.lookAt(nextPosition, Vector3.new(target.X, nextPosition.Y, target.Z))

	pivotAlienRootTo(record, nextCFrame)
end

local function sendEscapeWarning(record)
	local escapeConfig = getEscapeConfig()

	if record.EscapeWarningSent then
		return
	end

	record.EscapeWarningSent = true
	context.Services.RemoteService.BroadcastMissionWarning({
		Text = escapeConfig.Warning or "CONTAINMENT BREACH: revealed alien is escaping.",
		Severity = "AlienEscape",
		ScreenPulse = true,
		ScreenPulseDuration = 0.9,
		NPCId = record.NPCId,
		EscapePointName = record.EscapePointName
	})
end

local function markEscaped(record)
	if record.Escaped or record.Eliminated then
		return
	end

	local escapeConfig = getEscapeConfig()
	record.Escaped = true
	record.Escaping = false
	sendChaseStopWarning(record)
	context.Services.NPCService.MarkEscaped(record.NPCId)
	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.BroadcastMissionWarning({
		Text = escapeConfig.EscapedWarning or "CONTAINMENT FAILED: alien escaped the perimeter.",
		Severity = "AlienEscaped",
		ScreenPulse = true,
		ScreenPulseDuration = 1,
		NPCId = record.NPCId,
		EscapePointName = record.EscapePointName
	})

	print("[AlienService] Alien escaped:", record.NPCId, record.EscapePointName or "Unknown")
	context.Services.ResultService.CheckForAliensWin()
end

local function moveEscapingAlien(record, deltaTime)
	local escapeConfig = getEscapeConfig()

	if not escapeConfig.Enabled or not record.EscapeThreat or record.Eliminated or record.Escaped then
		return false
	end

	local now = os.clock()

	if not record.EscapeTargetPosition then
		return false
	end

	if not record.EscapeWarningSent and now >= (record.EscapeWarningAt or record.EscapeStartsAt or now) then
		sendEscapeWarning(record)
	end

	if now < (record.EscapeStartsAt or now) then
		return false
	end

	record.Escaping = true
	sendChaseStopWarning(record)

	if (record.StunnedUntil or 0) > now then
		return true
	end

	local root = getAlienRoot(record)

	if not root then
		return true
	end

	local origin = root.Position
	local target = Vector3.new(record.EscapeTargetPosition.X, origin.Y, record.EscapeTargetPosition.Z)
	local direction = target - origin
	local distance = direction.Magnitude
	local escapeRadius = escapeConfig.EscapeRadius or 6

	if distance <= escapeRadius then
		markEscaped(record)
		return true
	end

	if distance < 0.1 then
		return true
	end

	local speed = escapeConfig.EscapeSpeed or 12
	local stepDistance = math.min(speed * deltaTime, math.max(0, distance - escapeRadius))
	local nextPosition = origin + direction.Unit * stepDistance
	local nextCFrame = CFrame.lookAt(nextPosition, Vector3.new(target.X, nextPosition.Y, target.Z))

	pivotAlienRootTo(record, nextCFrame)

	return true
end

local function attackNearbyPlayers(record)
	local attackConfig = context.Config.RevealedAlienAttack or {}
	local range = attackConfig.Range or 10
	local damage = (attackConfig.Damage or 15) * AlienService.GetDamageMultiplier()
	local currentAggression = AlienService.GetAggressionMultiplier()
	local cooldown = (attackConfig.Cooldown or 1.5) / currentAggression
	local now = os.clock()

	if (record.StunnedUntil or 0) > now then
		return
	end

	if now - (record.LastAttackAt or 0) < cooldown then
		return
	end

	local root = getAlienRoot(record)

	if not root then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = getLivingHumanoid(player)
		local playerRoot = getCharacterRoot(player)

		if humanoid and playerRoot then
			local distance = (playerRoot.Position - root.Position).Magnitude

			if distance <= range then
				record.LastAttackAt = now

				if context.Services.PlayerService
					and context.Round.State == "Active"
					and humanoid.Health - damage <= 0
					and context.Services.PlayerService.DownPlayer(player)
				then
					print("[AlienService] Revealed alien downed:", record.NPCId, player.Name)
				else
					humanoid:TakeDamage(damage)
					print("[AlienService] Revealed alien attacked:", record.NPCId, player.Name)
				end

				return
			end
		end
	end
end

function AlienService.GetAggressionMultiplier()
	if os.clock() > aggressionUntil then
		return 1
	end

	return aggressionMultiplier
end

function AlienService.GetChaseAggressionMultiplier()
	if os.clock() > aggressionUntil then
		return 1
	end

	return chaseAggressionMultiplier
end

function AlienService.GetDamageMultiplier()
	if os.clock() > aggressionUntil then
		return 1
	end

	return damageMultiplier
end

function AlienService.GetAggressionSnapshot()
	local remaining = math.max(0, aggressionUntil - os.clock())

	return {
		AttackMultiplier = AlienService.GetAggressionMultiplier(),
		ChaseMultiplier = AlienService.GetChaseAggressionMultiplier(),
		DamageMultiplier = AlienService.GetDamageMultiplier(),
		Remaining = remaining
	}
end

function AlienService.BoostAggression(duration, multiplier, chaseMultiplier, damageBoostMultiplier)
	if os.clock() > aggressionUntil then
		aggressionMultiplier = 1
		chaseAggressionMultiplier = 1
		damageMultiplier = 1
	end

	aggressionUntil = math.max(aggressionUntil, os.clock() + duration)
	aggressionMultiplier = math.max(aggressionMultiplier, multiplier or 1)
	chaseAggressionMultiplier = math.max(chaseAggressionMultiplier, chaseMultiplier or multiplier or 1)
	damageMultiplier = math.max(damageMultiplier, damageBoostMultiplier or 1)

	print("[AlienService] Aggression boosted:", aggressionMultiplier, chaseAggressionMultiplier, damageMultiplier, duration)

	return {
		Multiplier = aggressionMultiplier,
		ChaseMultiplier = chaseAggressionMultiplier,
		DamageMultiplier = damageMultiplier,
		EndsAt = aggressionUntil
	}
end

local function triggerNestingRage(record)
	local nestingConfig = context.Config.NestingEvent or {}
	local modifier = context.Services.RoundService.GetModifier("NestingEvent")

	if not modifier or modifier.RageTriggered or nestingConfig.TriggerOnJuvenileDeath == false then
		return nil
	end

	context.Services.RoundService.SetModifierState("NestingEvent", {
		RageTriggered = true,
		JuvenileEliminated = true
	})

	local boost = AlienService.BoostAggression(
		nestingConfig.RageDuration or 20,
		nestingConfig.AggressionMultiplier or 1.5,
		nestingConfig.ChaseSpeedMultiplier or 1.35,
		nestingConfig.DamageMultiplier or 1.25
	)

	if context.Services.MapEventService then
		context.Services.MapEventService.TriggerNestingRagePulse("JuvenileEliminated")
	end

	context.Services.RemoteService.BroadcastMissionWarning({
		Text = nestingConfig.RageWarning or "NESTING EVENT: protector rage state active.",
		Severity = "Emergency",
		ScreenPulse = true,
		ScreenPulseDuration = 1.1,
		NPCId = record.NPCId
	})

	print("[AlienService] Nesting rage triggered:", record.NPCId)

	return boost
end

function AlienService.Init(sharedContext)
	context = sharedContext
	context.Aliens = alienRecords
	random = Random.new(context.Config.RandomSeed)
end

function AlienService.Start()
	print("[AlienService] Ready")
	AlienService.StartAttackLoop()
end

function AlienService.SelectAliens(npcs)
	table.clear(alienByNpcId)
	table.clear(alienRecords)

	local targetCount = math.min(context.Config.AlienCount, #npcs)
	local candidates = table.clone(npcs)

	for index = 1, targetCount do
		local candidateIndex = getRandom():NextInteger(1, #candidates)
		local npc = table.remove(candidates, candidateIndex)
		local traits = table.clone(context.Config.AlienTraitProfile)

		context.Services.NPCService.AssignTraits(npc.Id, traits)

		local record = {
			NPCId = npc.Id,
			AlienType = "Galloid",
			Revealed = false,
			Eliminated = false,
			Escaped = false,
			Health = getAlienMaxHealth(),
			MaxHealth = getAlienMaxHealth(),
			Traits = traits,
			LastAttackAt = 0
		}

		alienByNpcId[npc.Id] = record
		table.insert(alienRecords, record)
	end

	if context.Services.RoundService.HasModifier("NestingEvent") and #alienRecords > 0 then
		local nestingConfig = context.Config.NestingEvent or {}
		local juvenileRecord = alienRecords[getRandom():NextInteger(1, #alienRecords)]

		juvenileRecord.IsJuvenile = true
		juvenileRecord.AlienType = "Juvenile Galloid"
		juvenileRecord.Health = nestingConfig.JuvenileHealth or juvenileRecord.Health
		juvenileRecord.MaxHealth = juvenileRecord.Health
		context.Services.NPCService.ApplyJuvenileProfile(juvenileRecord.NPCId, nestingConfig)
		context.Services.RoundService.SetModifierState("NestingEvent", {
			JuvenileNPCId = juvenileRecord.NPCId
		})
	end

	for index = 1, math.min(context.Config.FullProfileDecoyCount or 0, #candidates) do
		context.Services.NPCService.AssignTraits(candidates[index].Id, table.clone(context.Config.AlienTraitProfile))
	end

	print("[AlienService] Aliens selected:", #alienRecords)

	if context.Config.DebugPrintSecretAliens then
		local secretIds = {}

		for _, record in ipairs(alienRecords) do
			table.insert(secretIds, record.NPCId)
		end

		print("[AlienService] Debug secret aliens:", table.concat(secretIds, ", "))
	end

	return alienRecords
end

function AlienService.IsAlien(npcId)
	return alienByNpcId[npcId] ~= nil
end

function AlienService.IsJuvenile(npcId)
	local record = alienByNpcId[npcId]

	return record and record.IsJuvenile == true
end

function AlienService.RevealAlien(npcId)
	local record = alienByNpcId[npcId]

	if record then
		local wasRevealed = record.Revealed
		record.Revealed = true
		record.LastAttackAt = 0

		if not wasRevealed and not record.RevealPresentationSent then
			local revealConfig = context.Config.RevealPresentation or {}
			record.RevealPresentationSent = true

			context.Services.RemoteService.BroadcastMissionWarning({
				Text = record.IsJuvenile
					and ((context.Config.NestingEvent or {}).JuvenileRevealWarning or "NESTING EVENT: juvenile Galloid confirmed.")
					or (revealConfig.Warning or "ENTITY REVEALED: hostile disguise collapsed."),
				Severity = "Reveal",
				ScreenPulse = true,
				ScreenPulseDuration = revealConfig.ScreenPulseDuration or 1,
				NPCId = npcId
			})

			if context.Services.MapEventService then
				context.Services.MapEventService.TriggerPanicPulse("AlienReveal")
			end
		end

		local escapeConfig = getEscapeConfig()

		if escapeConfig.Enabled and not record.EscapeRolled and not record.Eliminated and not record.Escaped then
			record.EscapeRolled = true

			if getRandom():NextNumber() <= (escapeConfig.EscapeChanceOnReveal or 0) then
				local escapePoint = chooseEscapePoint()
				local delaySeconds = escapeConfig.EscapeDelaySeconds or 8
				local warningLeadTime = escapeConfig.EscapeWarningLeadTime or 3

				if escapePoint then
					record.EscapeThreat = true
					record.EscapePointName = escapePoint.Name
					record.EscapeTargetPosition = escapePoint.Position
					record.EscapeStartsAt = os.clock() + delaySeconds
					record.EscapeWarningAt = os.clock() + math.max(0, delaySeconds - warningLeadTime)

					print("[AlienService] Alien escape threat:", npcId, escapePoint.Name)
				end
			end
		end
	end

	return record
end

function AlienService.DebugRevealFirstAlien(reason)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return nil
	end

	for _, record in ipairs(alienRecords) do
		if not record.Revealed and not record.Eliminated then
			AlienService.RevealAlien(record.NPCId)
			context.Services.NPCService.MarkRevealed(record.NPCId, record.AlienType)
			context.Services.RemoteService.BroadcastNPCRevealed(AlienService.GetPublicReveal(record.NPCId))
			context.Services.RemoteService.BroadcastNPCSnapshot()
			context.Services.RemoteService.BroadcastSuspectSnapshot()
			context.Services.RemoteService.BroadcastMissionWarning({
				Text = "DEBUG REVEAL: containment target exposed for testing.",
				Severity = "Debug",
				Reason = reason or "DebugTesting"
			})

			print("[AlienService] Debug revealed alien:", record.NPCId, reason or "DebugTesting")

			return record
		end
	end

	return nil
end

function AlienService.DebugRevealAllAliens(reason)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return 0
	end

	local count = 0

	for _, record in ipairs(alienRecords) do
		if not record.Eliminated then
			AlienService.RevealAlien(record.NPCId)
			context.Services.NPCService.MarkRevealed(record.NPCId, record.AlienType)
			context.Services.RemoteService.BroadcastNPCRevealed(AlienService.GetPublicReveal(record.NPCId))
			count += 1
		end
	end

	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.BroadcastSuspectSnapshot()
	context.Services.RemoteService.BroadcastMissionWarning({
		Text = "DEBUG REVEAL: all containment targets exposed.",
		Severity = "Debug",
		Reason = reason or "DebugTesting"
	})

	print("[AlienService] Debug revealed all aliens:", count, reason or "DebugTesting")

	return count
end

function AlienService.DebugSpawnChaseTestAlien(player)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return nil
	end

	if context.Round.State ~= "Active" then
		return nil
	end

	local playerRoot = getCharacterRoot(player)

	if not playerRoot then
		return nil
	end

	local record

	for _, candidate in ipairs(alienRecords) do
		if not candidate.Eliminated then
			record = candidate
			break
		end
	end

	if not record then
		return nil
	end

	if not record.Revealed then
		AlienService.RevealAlien(record.NPCId)
		context.Services.NPCService.MarkRevealed(record.NPCId, record.AlienType)
		context.Services.RemoteService.BroadcastNPCRevealed(AlienService.GetPublicReveal(record.NPCId))
	end

	local debugConfig = context.Config.DebugTesting or {}
	local distance = debugConfig.ChaseTestSpawnDistance or 24
	local targetPosition = playerRoot.Position + (playerRoot.CFrame.LookVector * distance)
	local rootCFrame = CFrame.lookAt(
		Vector3.new(targetPosition.X, playerRoot.Position.Y, targetPosition.Z),
		Vector3.new(playerRoot.Position.X, playerRoot.Position.Y, playerRoot.Position.Z)
	)

	context.Services.NPCService.DebugPivotNPCTo(record.NPCId, rootCFrame)
	context.Services.RemoteService.BroadcastNPCSnapshot()
	context.Services.RemoteService.SendMissionWarning(player, {
		Text = "DEBUG CHASE: revealed entity placed for pursuit test.",
		Severity = "Debug",
		ScreenPulse = true,
		ScreenPulseDuration = 0.5
	})

	print("[AlienService] Debug chase test alien:", record.NPCId, player.Name)

	return record
end

function AlienService.DamageAlien(npcId, damage, player)
	local record = alienByNpcId[npcId]

	if not record or not record.Revealed or record.Eliminated or record.Escaped then
		return nil
	end

	record.Health = math.max(0, record.Health - damage)
	context.Services.NPCService.UpdateRevealedHealth(npcId, record.Health, record.MaxHealth)

	if record.Health <= 0 then
		record.Eliminated = true
		record.Escaping = false
		context.Services.NPCService.MarkEliminated(npcId)
		print("[AlienService] Alien eliminated:", npcId, player and player.Name or "Unknown")

		if record.IsJuvenile then
			triggerNestingRage(record)
		end
	else
		print("[AlienService] Alien damaged:", npcId, record.Health)
	end

	return {
		NPCId = record.NPCId,
		Health = record.Health,
		MaxHealth = record.MaxHealth,
		Eliminated = record.Eliminated
	}
end

function AlienService.StunAlien(npcId, duration)
	local record = alienByNpcId[npcId]

	if not record or not record.Revealed or record.Eliminated or record.Escaped then
		return nil
	end

	record.StunnedUntil = math.max(record.StunnedUntil or 0, os.clock() + duration)
	context.Services.NPCService.MarkForSeconds(npcId, "StunnedMark", Color3.fromRGB(120, 190, 255), duration)

	print("[AlienService] Alien stunned:", npcId, duration)

	return {
		NPCId = record.NPCId,
		StunnedUntil = record.StunnedUntil
	}
end

function AlienService.GetRecordByNPCId(npcId)
	return alienByNpcId[npcId]
end

function AlienService.StartAttackLoop()
	if attackLoopRunning then
		return
	end

	attackLoopRunning = true

	task.spawn(function()
		while attackLoopRunning do
			local attackConfig = context.Config.RevealedAlienAttack or {}
			local tickInterval = attackConfig.TickInterval or 0.35

			task.wait(tickInterval)

			if context.Round.State == "Active" then
				for _, record in ipairs(alienRecords) do
					if record.Revealed and not record.Eliminated and not record.Escaped then
						local escapeHandled = moveEscapingAlien(record, tickInterval)

						if not escapeHandled and not record.IsJuvenile then
							chaseNearestPlayer(record, tickInterval)
						end

						if attackConfig.Enabled and not record.IsJuvenile then
							attackNearbyPlayers(record)
						end
					else
						sendChaseStopWarning(record)
					end
				end

				context.Services.ResultService.CheckForAliensWin()
			end
		end
	end)
end

function AlienService.GetPublicReveal(npcId)
	local record = alienByNpcId[npcId]

	if not record or not record.Revealed then
		return nil
	end

	return {
		NPCId = record.NPCId,
		AlienType = record.AlienType,
		IsJuvenile = record.IsJuvenile == true
	}
end

function AlienService.RevealAll()
	for _, record in ipairs(alienRecords) do
		record.Revealed = true
	end

	return alienRecords
end

function AlienService.GetPublicRevealedAliens()
	local revealed = {}

	for _, record in ipairs(alienRecords) do
		if record.Revealed then
			table.insert(revealed, {
				NPCId = record.NPCId,
				AlienType = record.AlienType,
				Health = record.Health,
				MaxHealth = record.MaxHealth,
				Eliminated = record.Eliminated,
				Escaped = record.Escaped == true,
				IsJuvenile = record.IsJuvenile == true
			})
		end
	end

	return revealed
end

function AlienService.GetRevealedCount()
	local count = 0

	for _, record in ipairs(alienRecords) do
		if record.Revealed then
			count += 1
		end
	end

	return count
end

function AlienService.GetAlienCount()
	return #alienRecords
end

function AlienService.AreAllAliensRevealed()
	return #alienRecords > 0 and AlienService.GetRevealedCount() >= #alienRecords
end

function AlienService.AreAllAliensEliminated()
	if #alienRecords == 0 then
		return false
	end

	for _, record in ipairs(alienRecords) do
		if not record.Eliminated then
			return false
		end
	end

	return true
end

function AlienService.HasEscapedAlien()
	for _, record in ipairs(alienRecords) do
		if record.Escaped then
			return true
		end
	end

	return false
end

function AlienService.GetAlienRecords()
	return alienRecords
end

function AlienService.GetActiveAlienPositions()
	local positions = {}

	for _, record in ipairs(alienRecords) do
		if not record.Eliminated and not record.Escaped then
			local root = getAlienRoot(record)

			if root then
				table.insert(positions, root.Position)
			end
		end
	end

	return positions
end

return AlienService
