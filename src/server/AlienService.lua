local AlienService = {}

local Players = game:GetService("Players")

local context
local alienByNpcId = {}
local alienRecords = {}
local random
local attackLoopRunning = false
local aggressionUntil = 0
local aggressionMultiplier = 1

local function getAlienMaxHealth()
	local attackConfig = context.Config.RevealedAlienAttack or {}

	return attackConfig.MaxHealth or 120
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

local function attackNearbyPlayers(record)
	local attackConfig = context.Config.RevealedAlienAttack or {}
	local range = attackConfig.Range or 10
	local damage = attackConfig.Damage or 15
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
				humanoid:TakeDamage(damage)
				print("[AlienService] Revealed alien attacked:", record.NPCId, player.Name)
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

function AlienService.BoostAggression(duration, multiplier)
	if os.clock() > aggressionUntil then
		aggressionMultiplier = 1
	end

	aggressionUntil = math.max(aggressionUntil, os.clock() + duration)
	aggressionMultiplier = math.max(aggressionMultiplier, multiplier or 1)

	print("[AlienService] Aggression boosted:", aggressionMultiplier, duration)

	return {
		Multiplier = aggressionMultiplier,
		EndsAt = aggressionUntil
	}
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
			Health = getAlienMaxHealth(),
			MaxHealth = getAlienMaxHealth(),
			Traits = traits,
			LastAttackAt = 0
		}

		alienByNpcId[npc.Id] = record
		table.insert(alienRecords, record)
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

function AlienService.RevealAlien(npcId)
	local record = alienByNpcId[npcId]

	if record then
		record.Revealed = true
		record.LastAttackAt = 0
	end

	return record
end

function AlienService.DamageAlien(npcId, damage, player)
	local record = alienByNpcId[npcId]

	if not record or not record.Revealed or record.Eliminated then
		return nil
	end

	record.Health = math.max(0, record.Health - damage)
	context.Services.NPCService.UpdateRevealedHealth(npcId, record.Health, record.MaxHealth)

	if record.Health <= 0 then
		record.Eliminated = true
		context.Services.NPCService.MarkEliminated(npcId)
		print("[AlienService] Alien eliminated:", npcId, player and player.Name or "Unknown")
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

	if not record or not record.Revealed or record.Eliminated then
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

			if attackConfig.Enabled and context.Round.State == "Active" then
				for _, record in ipairs(alienRecords) do
					if record.Revealed and not record.Eliminated then
						attackNearbyPlayers(record)
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
		AlienType = record.AlienType
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
				Eliminated = record.Eliminated
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

function AlienService.GetAlienRecords()
	return alienRecords
end

return AlienService
