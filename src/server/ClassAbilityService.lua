local ClassAbilityService = {}

local Players = game:GetService("Players")

local context
local lastUseByPlayer = {}

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

local function getAbilityConfig(className)
	return (context.Config.ClassAbilities or {})[className]
end

local function reject(reason, extra)
	local result = extra or {}
	result.Accepted = false
	result.Reason = reason

	return result
end

local function addCooldown(result, cooldown)
	result.Cooldown = cooldown
	result.CooldownEndsAt = os.clock() + cooldown

	return result
end

local function rejectCooldown(remaining)
	return {
		Accepted = false,
		Reason = "AbilityCooldown",
		CooldownRemaining = remaining
	}
end

local function getDistanceFromPlayer(player, part)
	local root = getCharacterRoot(player)

	if not root or not part then
		return nil
	end

	return (part.Position - root.Position).Magnitude
end

local function getNPCPrimaryPart(npc)
	return npc and npc.Model and npc.Model.PrimaryPart
end

local function markCharacterForSeconds(player, markerName, color, duration)
	local character = player.Character

	if not character then
		return
	end

	local marker = character:FindFirstChild(markerName)

	if marker then
		marker:Destroy()
	end

	marker = Instance.new("Highlight")
	marker.Name = markerName
	marker.FillColor = color
	marker.OutlineColor = color
	marker.FillTransparency = 0.65
	marker.OutlineTransparency = 0.1
	marker.Parent = character

	task.delay(duration, function()
		if marker and marker.Parent then
			marker:Destroy()
		end
	end)
end

local function findNearestRevealedAlien(player, range)
	local closestRecord
	local closestDistance = range

	for _, record in ipairs(context.Services.AlienService.GetAlienRecords()) do
		if record.Revealed and not record.Eliminated then
			local npc = context.Services.NPCService.GetNPCById(record.NPCId)
			local distance = getDistanceFromPlayer(player, getNPCPrimaryPart(npc))

			if distance and distance <= closestDistance then
				closestRecord = record
				closestDistance = distance
			end
		end
	end

	return closestRecord, closestDistance
end

local function findNearestNPC(player, range, includeRevealed)
	local closestNPC
	local closestDistance = range

	for _, npc in ipairs(context.Services.NPCService.GetNPCs()) do
		if includeRevealed or not npc.Revealed then
			local distance = getDistanceFromPlayer(player, getNPCPrimaryPart(npc))

			if distance and distance <= closestDistance then
				closestNPC = npc
				closestDistance = distance
			end
		end
	end

	return closestNPC, closestDistance
end

local function useHunterAbility(player, abilityConfig)
	local record = findNearestRevealedAlien(player, abilityConfig.Range or 18)

	if not record then
		return reject("NoRevealedAlienInRange")
	end

	context.Services.AlienService.StunAlien(record.NPCId, abilityConfig.StunDuration or 3)
	context.Services.RemoteService.BroadcastNPCSnapshot()

	return {
		Accepted = true,
		Ability = abilityConfig.Name,
		Message = "ENTITY STUNNED: " .. record.NPCId,
		NPCId = record.NPCId
	}
end

local function useInvestigatorAbility(player, abilityConfig)
	local npc = findNearestNPC(player, abilityConfig.Range or 28, false)

	if not npc then
		return reject("NoSuspectInRange")
	end

	local discoveredTraits = context.Services.ClueService.GetDiscoveredTraits()
	local summary = context.Services.NPCService.GetTraitMatchSummary(npc.Id, discoveredTraits)

	context.Services.NPCService.MarkForSeconds(npc.Id, "ScannerMark", Color3.fromRGB(255, 230, 105), 5)

	return {
		Accepted = true,
		Ability = abilityConfig.Name,
		Message = "SCAN: " .. npc.DisplayName .. " / MATCH " .. summary.Matched .. "/" .. summary.Total,
		NPCId = npc.Id,
		DisplayName = npc.DisplayName,
		MatchedTraits = summary.Matched,
		TotalTraits = summary.Total
	}
end

local function useEngineerAbility(player, abilityConfig)
	local root = getCharacterRoot(player)

	if not root then
		return reject("NoCharacter")
	end

	local duration = abilityConfig.Duration or 12
	local range = abilityConfig.Range or 18
	local sensor = Instance.new("Part")
	sensor.Name = "EngineerSensor"
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.Size = Vector3.new(3, 0.4, 3)
	sensor.CFrame = root.CFrame * CFrame.new(0, -2.6, -3)
	sensor.Color = Color3.fromRGB(100, 190, 255)
	sensor.Material = Enum.Material.Neon
	sensor.Parent = context.Services.MapService.GetFolders().Props

	local light = Instance.new("PointLight")
	light.Name = "SensorGlow"
	light.Color = Color3.fromRGB(100, 190, 255)
	light.Brightness = 0.9
	light.Range = range
	light.Parent = sensor

	local radiusDisc = Instance.new("Part")
	radiusDisc.Name = "EngineerSensorRadius"
	radiusDisc.Anchored = true
	radiusDisc.CanCollide = false
	radiusDisc.Shape = Enum.PartType.Cylinder
	radiusDisc.Size = Vector3.new(range * 2, 0.12, range * 2)
	radiusDisc.CFrame = sensor.CFrame * CFrame.new(0, -0.18, 0)
	radiusDisc.Color = Color3.fromRGB(80, 170, 255)
	radiusDisc.Material = Enum.Material.Neon
	radiusDisc.Transparency = 0.78
	radiusDisc.Parent = context.Services.MapService.GetFolders().Props

	task.spawn(function()
		local expiresAt = os.clock() + duration

		while sensor.Parent and os.clock() < expiresAt do
			for _, record in ipairs(context.Services.AlienService.GetAlienRecords()) do
				if record.Revealed and not record.Eliminated then
					local npc = context.Services.NPCService.GetNPCById(record.NPCId)
					local npcRoot = getNPCPrimaryPart(npc)

					if npcRoot and (npcRoot.Position - sensor.Position).Magnitude <= range then
						context.Services.AlienService.StunAlien(record.NPCId, abilityConfig.StunDuration or 2)
					end
				end
			end

			task.wait(0.75)
		end

		if radiusDisc.Parent then
			radiusDisc:Destroy()
		end

		if sensor.Parent then
			sensor:Destroy()
		end
	end)

	return {
		Accepted = true,
		Ability = abilityConfig.Name,
		Message = "SENSOR ARMED"
	}
end

local function useMedicAbility(player, abilityConfig)
	local root = getCharacterRoot(player)

	if not root then
		return reject("NoCharacter")
	end

	local range = abilityConfig.Range or 20
	local healAmount = abilityConfig.Amount or 35
	local bestPlayer = player
	local bestHumanoid = getLivingHumanoid(player)
	local lowestHealthRatio = bestHumanoid and (bestHumanoid.Health / bestHumanoid.MaxHealth) or 1

	for _, candidate in ipairs(Players:GetPlayers()) do
		local humanoid = getLivingHumanoid(candidate)
		local candidateRoot = getCharacterRoot(candidate)

		if humanoid and candidateRoot and humanoid.Health < humanoid.MaxHealth then
			local distance = (candidateRoot.Position - root.Position).Magnitude
			local healthRatio = humanoid.Health / humanoid.MaxHealth

			if distance <= range and healthRatio <= lowestHealthRatio then
				bestPlayer = candidate
				bestHumanoid = humanoid
				lowestHealthRatio = healthRatio
			end
		end
	end

	if not bestHumanoid or bestHumanoid.Health >= bestHumanoid.MaxHealth then
		return reject("NoInjuredPlayerInRange")
	end

	bestHumanoid.Health = math.min(bestHumanoid.MaxHealth, bestHumanoid.Health + healAmount)
	markCharacterForSeconds(bestPlayer, "MedicHealMark", Color3.fromRGB(90, 255, 135), 1.25)
	context.Services.PlayerService.SendSnapshot(bestPlayer)

	if bestPlayer ~= player then
		context.Services.PlayerService.SendSnapshot(player)
	end

	return {
		Accepted = true,
		Ability = abilityConfig.Name,
		Message = "VITALS RESTORED: " .. bestPlayer.Name,
		Target = bestPlayer.Name,
		Amount = healAmount
	}
end

local function useScoutAbility(player, abilityConfig)
	local npc = findNearestNPC(player, abilityConfig.Range or 34, true)

	if not npc then
		return reject("NoNPCInRange")
	end

	context.Services.NPCService.MarkForSeconds(npc.Id, "ScoutMark", Color3.fromRGB(95, 255, 155), abilityConfig.Duration or 10)

	return {
		Accepted = true,
		Ability = abilityConfig.Name,
		Message = "TARGET MARKED: " .. npc.DisplayName,
		NPCId = npc.Id,
		DisplayName = npc.DisplayName
	}
end

function ClassAbilityService.Init(sharedContext)
	context = sharedContext
end

function ClassAbilityService.Start()
	print("[ClassAbilityService] Ready")

	context.Services.RemoteService.BindClassAbilityHandler(function(player)
		return ClassAbilityService.UseAbility(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastUseByPlayer[player] = nil
	end)
end

function ClassAbilityService.UseAbility(player)
	if context.Round.State ~= "Active" then
		return reject("RoundNotActive")
	end

	local className = context.Services.PlayerService.GetPlayerClass(player)
	local abilityConfig = getAbilityConfig(className)

	if not abilityConfig then
		return reject("NoClassAbility")
	end

	local now = os.clock()
	local lastUse = lastUseByPlayer[player] or 0
	local cooldown = abilityConfig.Cooldown or 8

	if now - lastUse < cooldown then
		return rejectCooldown(math.max(0, cooldown - (now - lastUse)))
	end

	local result

	if className == "Hunter" then
		result = useHunterAbility(player, abilityConfig)
	elseif className == "Investigator" then
		result = useInvestigatorAbility(player, abilityConfig)
	elseif className == "Engineer" then
		result = useEngineerAbility(player, abilityConfig)
	elseif className == "Medic" then
		result = useMedicAbility(player, abilityConfig)
	elseif className == "Scout" then
		result = useScoutAbility(player, abilityConfig)
	else
		result = reject("NoClassAbility")
	end

	if result.Accepted then
		lastUseByPlayer[player] = now
		addCooldown(result, cooldown)
	end

	return result
end

return ClassAbilityService
