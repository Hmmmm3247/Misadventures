local NPCService = {}

local Players = game:GetService("Players")

local context
local npcs = {}
local npcById = {}
local promptConnections = {}
local behaviorLoopRunning = false
local lastSuspicionByNpcId = {}
local lastSuspicionSnapshotAt = 0
local random = Random.new()

local bodyColors = {
	Color3.fromRGB(62, 86, 96),
	Color3.fromRGB(105, 77, 55),
	Color3.fromRGB(72, 94, 70),
	Color3.fromRGB(91, 73, 101),
	Color3.fromRGB(102, 66, 70)
}

local skinTones = {
	Color3.fromRGB(190, 176, 153),
	Color3.fromRGB(178, 162, 138),
	Color3.fromRGB(205, 188, 164),
	Color3.fromRGB(162, 146, 122),
	Color3.fromRGB(198, 180, 158)
}

local function clearConnectionList()
	for _, connection in ipairs(promptConnections) do
		connection:Disconnect()
	end

	table.clear(promptConnections)
end

local function clearFolder(folder)
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
end

local function buildTraitMap(traits)
	local traitMap = {}

	for _, trait in ipairs(traits or {}) do
		traitMap[trait] = true
	end

	return traitMap
end

local function getDecoyTraits(index)
	local decoySets = context.Config.DecoyTraitSets or {}
	local traitSet = decoySets[index] or {}

	return table.clone(traitSet)
end

local function getSuspicionConfig()
	return context.Config.NPCSuspicion or {}
end

local function getSuspicionLabel(score)
	local suspicionConfig = getSuspicionConfig()

	if score >= (suspicionConfig.HighThreshold or 45) then
		return "Highly Suspicious"
	end

	if score >= math.floor((suspicionConfig.HighThreshold or 45) * 0.55) then
		return "Suspicious"
	end

	return "Low Signal"
end

local function broadcastSuspicionSnapshot()
	local suspicionConfig = getSuspicionConfig()
	local now = os.clock()

	if now - lastSuspicionSnapshotAt < (suspicionConfig.SnapshotCooldown or 3) then
		return
	end

	lastSuspicionSnapshotAt = now

	if context.Services.RemoteService then
		context.Services.RemoteService.BroadcastSuspectSnapshot()
	end
end

local function addSuspicion(npc, amount, reason, broadcast)
	local suspicionConfig = getSuspicionConfig()

	if not suspicionConfig.Enabled or not npc or npc.Revealed then
		return npc and npc.SuspicionScore or 0
	end

	local maxScore = suspicionConfig.MaxScore or 100
	local previousScore = npc.SuspicionScore or 0
	npc.SuspicionScore = math.clamp(previousScore + amount, 0, maxScore)
	npc.LastSuspicionReason = reason

	if npc.SuspicionScore ~= previousScore and broadcast then
		broadcastSuspicionSnapshot()
	end

	return npc.SuspicionScore
end

local function getRootCFrame(npc)
	return npc.Model and npc.Model.PrimaryPart and npc.Model.PrimaryPart.CFrame
end

local function pivotRootTo(npc, rootCFrame)
	if not npc.Model or not npc.Model.PrimaryPart then
		return
	end

	local pivot = npc.Model:GetPivot()
	local root = npc.Model.PrimaryPart.CFrame
	local pivotToRoot = pivot:ToObjectSpace(root)

	npc.Model:PivotTo(rootCFrame * pivotToRoot:Inverse())
end

local function getNearbyPlayers(position, range)
	local nearby = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if root and humanoid and humanoid.Health > 0 and (root.Position - position).Magnitude <= range then
			table.insert(nearby, player)
		end
	end

	return nearby
end

local function getNearestPlayer(position, range)
	local nearestPlayer
	local nearestDistance = range

	for _, player in ipairs(getNearbyPlayers(position, range)) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local distance = root and (root.Position - position).Magnitude

		if distance and distance <= nearestDistance then
			nearestPlayer = player
			nearestDistance = distance
		end
	end

	return nearestPlayer
end

local function facePosition(npc, position)
	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return
	end

	local origin = rootCFrame.Position
	local lookAt = Vector3.new(position.X, origin.Y, position.Z)

	if (lookAt - origin).Magnitude < 0.1 then
		return
	end

	pivotRootTo(npc, CFrame.lookAt(origin, lookAt))
end

local function faceRandomDirection(npc)
	local rootCFrame = getRootCFrame(npc)

	if rootCFrame then
		pivotRootTo(npc, CFrame.new(rootCFrame.Position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0))
	end
end

local function moveNPCStepToward(npc, targetPosition, stepDistance)
	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return false
	end

	local origin = rootCFrame.Position
	local target = Vector3.new(targetPosition.X, origin.Y, targetPosition.Z)
	local direction = target - origin

	if direction.Magnitude < 0.1 then
		return false
	end

	local nextPosition = origin + direction.Unit * math.min(stepDistance, direction.Magnitude)
	pivotRootTo(npc, CFrame.lookAt(nextPosition, Vector3.new(target.X, nextPosition.Y, target.Z)))

	return true
end

local function getSortedSpawnsByDistance(position)
	local spawnPoints = context.Services.MapService.GetNPCSpawns()

	table.sort(spawnPoints, function(left, right)
		return (left.Position - position).Magnitude < (right.Position - position).Magnitude
	end)

	return spawnPoints
end

local function getLightDistanceScore(position)
	local nearest = math.huge

	for _, lightPosition in ipairs(context.Services.MapService.GetLightPositions()) do
		nearest = math.min(nearest, (lightPosition - position).Magnitude)
	end

	return nearest
end

local function chooseNearbySpawn(npc, avoidLights)
	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return nil
	end

	local behaviorConfig = context.Config.NPCBehavior or {}
	local sampleCount = behaviorConfig.NearbySpawnSampleCount or 4
	local spawnPoints = getSortedSpawnsByDistance(rootCFrame.Position)
	local bestSpawn
	local bestScore = -math.huge

	if #spawnPoints == 0 then
		return nil
	end

	for index = 1, math.min(sampleCount, #spawnPoints) do
		local spawn = spawnPoints[index]

		if spawn.Name ~= npc.LastSpawnName then
			local score = avoidLights and getLightDistanceScore(spawn.Position) or random:NextNumber()

			if score > bestScore then
				bestScore = score
				bestSpawn = spawn
			end
		end
	end

	return bestSpawn or spawnPoints[random:NextInteger(1, #spawnPoints)]
end

local function chooseLandmarkSpawn()
	local landmarks = context.Services.MapService.GetLandmarkPositions and context.Services.MapService.GetLandmarkPositions() or {}
	local spawnPoints = context.Services.MapService.GetNPCSpawns()
	local behaviorConfig = context.Config.NPCBehavior or {}
	local sampleCount = behaviorConfig.ClusterSpawnSampleCount or 4

	if #landmarks == 0 or #spawnPoints == 0 then
		return nil
	end

	local landmark = landmarks[random:NextInteger(1, #landmarks)]

	table.sort(spawnPoints, function(left, right)
		return (left.Position - landmark).Magnitude < (right.Position - landmark).Magnitude
	end)

	return spawnPoints[random:NextInteger(1, math.min(sampleCount, #spawnPoints))]
end

local function getNearestCivilianPosition(npc, range)
	local rootCFrame = getRootCFrame(npc)
	local nearestPosition
	local nearestDistance = range

	if not rootCFrame then
		return nil
	end

	for _, otherNpc in ipairs(npcs) do
		if otherNpc ~= npc and not otherNpc.Revealed and not otherNpc.Eliminated then
			local otherCFrame = getRootCFrame(otherNpc)
			local distance = otherCFrame and (otherCFrame.Position - rootCFrame.Position).Magnitude

			if distance and distance <= nearestDistance then
				nearestPosition = otherCFrame.Position
				nearestDistance = distance
			end
		end
	end

	return nearestPosition
end

local function chooseClusterSpawnNearNPC(npc)
	local rootCFrame = getRootCFrame(npc)
	local socialConfig = context.Config.NPCSocialBehavior or {}
	local spawnPoints = context.Services.MapService.GetNPCSpawns()
	local targetPosition = getNearestCivilianPosition(npc, socialConfig.GroupSearchRange or 38)
	local maxDistance = socialConfig.GroupClusterRadius or 14
	local candidates = {}

	if not rootCFrame or not targetPosition then
		return nil
	end

	for _, spawn in ipairs(spawnPoints) do
		if (spawn.Position - targetPosition).Magnitude <= maxDistance and spawn.Name ~= npc.LastSpawnName then
			table.insert(candidates, spawn)
		end
	end

	if #candidates == 0 then
		return nil
	end

	return candidates[random:NextInteger(1, #candidates)]
end

local function moveNPCToSpawn(npc, spawnPart)
	if not spawnPart or not npc.Model or not npc.Model.PrimaryPart then
		return
	end

	local behaviorConfig = context.Config.NPCBehavior or {}
	local moveSpeed = npc.MoveSpeedOverride or behaviorConfig.MoveSpeed or 7
	local startCFrame = npc.Model.PrimaryPart.CFrame
	local targetPosition = spawnPart.Position + Vector3.new(0, npc.Model.PrimaryPart.Size.Y / 2, 0)
	local distance = (targetPosition - startCFrame.Position).Magnitude
	local duration = math.max(distance / moveSpeed, 0.2)
	local steps = math.max(1, math.floor(duration / 0.12))

	for step = 1, steps do
		if context.Round.State ~= "Active" or npc.Revealed or npc.Eliminated then
			return
		end

		local alpha = step / steps
		local position = startCFrame.Position:Lerp(targetPosition, alpha)
		local lookAt = Vector3.new(targetPosition.X, position.Y, targetPosition.Z)
		local rootCFrame = (lookAt - position).Magnitude > 0.1 and CFrame.lookAt(position, lookAt) or CFrame.new(position)

		pivotRootTo(npc, rootCFrame)
		task.wait(0.12)
	end

	npc.LastSpawnName = spawnPart.Name
end

local function sendSuspicionIfSeen(npc, fallbackMessage)
	local eventConfig = context.Config.SuspicionEvents or {}
	local suspicionConfig = getSuspicionConfig()

	if not eventConfig.Enabled then
		return
	end

	local now = os.clock()

	if now - (lastSuspicionByNpcId[npc.Id] or 0) < (eventConfig.Cooldown or 8) then
		return
	end

	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return
	end

	local nearbyPlayers = getNearbyPlayers(rootCFrame.Position, context.Config.AlienBehavior.PlayerNoticeRange or 28)

	if #nearbyPlayers == 0 or random:NextNumber() > (eventConfig.NoticeChance or 0.4) then
		return
	end

	local messages = eventConfig.Messages or {}
	local text = fallbackMessage or messages[random:NextInteger(1, math.max(#messages, 1))] or "BEHAVIOR FLAG: host movement anomaly detected."
	lastSuspicionByNpcId[npc.Id] = now
	addSuspicion(npc, suspicionConfig.BehaviorAmount or 12, text, true)

	for _, player in ipairs(nearbyPlayers) do
		context.Services.RemoteService.SendMissionWarning(player, {
			Text = text,
			Severity = "Suspicion"
		})
	end
end

local function runPlayerLookBehavior(npc)
	local behaviorConfig = context.Config.NPCBehavior or {}

	if random:NextNumber() > (behaviorConfig.LookAtPlayerChance or 0.15) then
		return false
	end

	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return false
	end

	local player = getNearestPlayer(rootCFrame.Position, context.Config.AlienBehavior.PlayerNoticeRange or 28)

	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		facePosition(npc, player.Character.HumanoidRootPart.Position)
		return true
	end

	return false
end

local function runSocialBehavior(npc)
	local socialConfig = context.Config.NPCSocialBehavior or {}

	if socialConfig.Enabled == false then
		return false
	end

	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return false
	end

	if random:NextNumber() <= (socialConfig.FaceNearbyNPCChance or 0.08) then
		local targetPosition = getNearestCivilianPosition(npc, socialConfig.GroupSearchRange or 38)

		if targetPosition then
			facePosition(npc, targetPosition)
			return true
		end
	end

	if random:NextNumber() <= (socialConfig.GroupClusterChance or 0.12) then
		local spawn = chooseClusterSpawnNearNPC(npc)

		if spawn then
			moveNPCToSpawn(npc, spawn)
			return true
		end
	end

	if random:NextNumber() <= (socialConfig.LandmarkStandChance or 0.16) then
		local spawn = chooseLandmarkSpawn()

		if spawn then
			moveNPCToSpawn(npc, spawn)
			task.wait(random:NextNumber(socialConfig.LandmarkStandMin or 1.2, socialConfig.LandmarkStandMax or 2.6))
			return true
		end
	end

	return false
end

local function runFalsePositiveBehavior(npc)
	local falseConfig = context.Config.FalsePositiveEvents or {}

	if falseConfig.Enabled == false or context.Services.AlienService.IsAlien(npc.Id) then
		return false
	end

	if random:NextNumber() > (falseConfig.NPCBehaviorChance or 0.08) then
		return false
	end

	local anomalyType = random:NextInteger(1, 4)

	if anomalyType == 1 then
		sendSuspicionIfSeen(npc, falseConfig.HarmlessSuspiciousText or "BEHAVIOR FLAG: harmless hesitation matched an entity tell.")
		task.wait(random:NextNumber(falseConfig.HesitationMin or 0.8, falseConfig.HesitationMax or 1.6))
		faceRandomDirection(npc)
	elseif anomalyType == 2 then
		for _ = 1, random:NextInteger(falseConfig.TwitchCountMin or 1, falseConfig.TwitchCountMax or 2) do
			local current = getRootCFrame(npc)

			if current then
				pivotRootTo(npc, current * CFrame.Angles(0, math.rad(random:NextNumber(falseConfig.TwitchAngleMin or -10, falseConfig.TwitchAngleMax or 10)), 0))
			end

			task.wait(falseConfig.TwitchStepWait or 0.1)
		end

		sendSuspicionIfSeen(npc, falseConfig.MovementAnomalyText or "BEHAVIOR FLAG: non-host movement anomaly logged.")
	elseif anomalyType == 3 then
		if random:NextNumber() <= (falseConfig.PanicMoveChance or 0.5) then
			sendSuspicionIfSeen(npc, falseConfig.PanicText or "BEHAVIOR FLAG: innocent resident panicked at the wrong moment.")
			moveNPCToSpawn(npc, chooseNearbySpawn(npc, false))
		end
	else
		if context.Services.RemoteService and random:NextNumber() <= (falseConfig.FakeClueWarningChance or 0.35) then
			context.Services.RemoteService.BroadcastMissionWarning({
				Text = falseConfig.FakeClueText or "FALSE SIGNAL: residue trace collapsed into ordinary farm dust.",
				Severity = "Suspicion",
				ScreenPulse = false
			})
		end
	end

	addSuspicion(npc, falseConfig.SuspicionAmount or 6, "FalsePositive", true)

	return true
end

local function runJuvenileBehavior(npc)
	local nestingConfig = context.Config.NestingEvent or {}

	if not context.Services.AlienService.IsJuvenile(npc.Id) then
		return false
	end

	if random:NextNumber() > (nestingConfig.TimidMoveChance or 0.35) then
		return true
	end

	if random:NextNumber() <= (nestingConfig.DistressSoundChance or 0.15) and context.Services.MapEventService then
		context.Services.MapEventService.TriggerNestingHint("JuvenileDistress")
	end

	if random:NextNumber() <= (nestingConfig.HideNearGroupChance or 0.3) then
		local spawn = chooseClusterSpawnNearNPC(npc)

		if spawn then
			moveNPCToSpawn(npc, spawn)
			return true
		end
	end

	if random:NextNumber() <= (nestingConfig.HideNearLandmarkChance or 0.25) then
		local spawn = chooseLandmarkSpawn()

		if spawn then
			moveNPCToSpawn(npc, spawn)
			return true
		end
	end

	faceRandomDirection(npc)

	return true
end

local function runAlienTell(npc)
	local behaviorConfig = context.Config.AlienBehavior or {}

	if not behaviorConfig.Enabled or not context.Services.AlienService.IsAlien(npc.Id) or npc.Revealed then
		return false
	end

	if random:NextNumber() > (behaviorConfig.TellChance or 0.2) then
		return false
	end

	local tellType = random:NextInteger(1, 6)
	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return false
	end

	if tellType == 1 then
		local player = getNearestPlayer(rootCFrame.Position, behaviorConfig.PlayerNoticeRange or 28)

		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			facePosition(npc, player.Character.HumanoidRootPart.Position)
			sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: one host stared without blinking.")
			task.wait(random:NextNumber(behaviorConfig.StareDurationMin or 1.4, behaviorConfig.StareDurationMax or 2.8))
			return true
		end
	elseif tellType == 2 then
		sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: one host stopped moving for too long.")
		task.wait(random:NextNumber(behaviorConfig.FreezeDurationMin or 1.1, behaviorConfig.FreezeDurationMax or 2.4))
		return true
	elseif tellType == 3 then
		sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: short involuntary movement detected.")

		for _ = 1, random:NextInteger(behaviorConfig.TwitchCountMin or 2, behaviorConfig.TwitchCountMax or 4) do
			local current = getRootCFrame(npc)

			if current then
				pivotRootTo(npc, current * CFrame.Angles(0, math.rad(random:NextNumber(-16, 16)), 0))
			end

			task.wait(0.12)
		end

		return true
	elseif tellType == 4 then
		if random:NextNumber() <= (behaviorConfig.LightAvoidanceChance or 0.5) then
			local spawn = chooseNearbySpawn(npc, true)

			if spawn then
				sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: one host recoiled from direct light.")
				moveNPCToSpawn(npc, spawn)
				return true
			end
		end
	elseif tellType == 5 then
		if random:NextNumber() <= (behaviorConfig.FollowPlayerChance or 0.15) then
			local player = getNearestPlayer(rootCFrame.Position, behaviorConfig.PlayerNoticeRange or 28)
			local targetRoot = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")

			if targetRoot then
				sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: one host drifted after an operative.")
				moveNPCStepToward(npc, targetRoot.Position, behaviorConfig.FollowStepDistance or 10)
				return true
			end
		end
	else
		if random:NextNumber() <= (behaviorConfig.DelayedReactionChance or 0.2) then
			task.wait(random:NextNumber(behaviorConfig.SuspiciousPauseMin or 0.8, behaviorConfig.SuspiciousPauseMax or 1.8))
			faceRandomDirection(npc)
			sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: delayed response to movement nearby.")
			return true
		end
	end

	return false
end

local function panicNearbyNPCs(revealedNpc)
	local revealConfig = context.Config.RevealPresentation or {}
	local radius = revealConfig.PanicRadius or 34
	local originCFrame = getRootCFrame(revealedNpc)

	if not originCFrame then
		return
	end

	for _, npc in ipairs(npcs) do
		if npc ~= revealedNpc and not npc.Revealed and not npc.Eliminated then
			local npcCFrame = getRootCFrame(npc)

			if npcCFrame and (npcCFrame.Position - originCFrame.Position).Magnitude <= radius then
				facePosition(npc, originCFrame.Position)

				if random:NextNumber() <= (revealConfig.PanicMoveChance or 0.65) then
					task.spawn(function()
						moveNPCToSpawn(npc, chooseNearbySpawn(npc, false))
					end)
				end
			end
		end
	end
end

local function createNPCModel(npc, spawnPart)
	local model = Instance.new("Model")
	model.Name = npc.Id
	local bodyColor = bodyColors[((npc.Index - 1) % #bodyColors) + 1]
	local skinColor = skinTones[((npc.Index - 1) % #skinTones) + 1]

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = true
	root.Size = Vector3.new(1.8, 3.35, 0.85)
	root.Color = bodyColor
	root.Material = Enum.Material.Fabric
	root.CFrame = spawnPart.CFrame + Vector3.new(0, root.Size.Y / 2, 0)
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.45, 1.75, 1.25)
	head.Color = skinColor
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = root.CFrame + Vector3.new(0, 2.95, -0.04)
	head.Parent = model

	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.Size = Vector3.new(0.18, 0.18, 0.08)
	leftEye.Color = Color3.fromRGB(8, 10, 9)
	leftEye.Material = Enum.Material.Neon
	leftEye.CFrame = head.CFrame * CFrame.new(-0.28, 0.12, -0.62)
	leftEye.Parent = model

	local rightEye = leftEye:Clone()
	rightEye.Name = "RightEye"
	rightEye.CFrame = head.CFrame * CFrame.new(0.28, 0.12, -0.62)
	rightEye.Parent = model

	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.Size = Vector3.new(0.38, 3.05, 0.38)
	leftArm.Color = bodyColor
	leftArm.Material = Enum.Material.Fabric
	leftArm.CFrame = root.CFrame * CFrame.new(-1.09, 0, 0)
	leftArm.Parent = model

	local rightArm = leftArm:Clone()
	rightArm.Name = "RightArm"
	rightArm.CFrame = root.CFrame * CFrame.new(1.09, 0, 0)
	rightArm.Parent = model

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.Size = Vector3.new(0.6, 2.2, 0.6)
	leftLeg.Color = Color3.fromRGB(31, 38, 42)
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.5, -2.35, 0)
	leftLeg.Parent = model

	local rightLeg = leftLeg:Clone()
	rightLeg.Name = "RightLeg"
	rightLeg.CFrame = root.CFrame * CFrame.new(0.5, -2.35, 0)
	rightLeg.Parent = model

	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Anchored = true
	belt.CanCollide = false
	belt.Size = Vector3.new(1.86, 0.34, 0.92)
	belt.Color = Color3.fromRGB(28, 24, 22)
	belt.Material = Enum.Material.SmoothPlastic
	belt.CFrame = root.CFrame * CFrame.new(0, -0.75, 0)
	belt.Parent = model

	local collar = Instance.new("Part")
	collar.Name = "Collar"
	collar.Anchored = true
	collar.CanCollide = false
	collar.Size = Vector3.new(1.2, 0.45, 0.88)
	collar.Color = skinColor
	collar.Material = Enum.Material.SmoothPlastic
	collar.CFrame = root.CFrame * CFrame.new(0, 1.5, -0.04)
	collar.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = npc.DisplayName
	humanoid.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AccusePrompt"
	prompt.ActionText = "Accuse"
	prompt.ObjectText = npc.DisplayName
	prompt.MaxActivationDistance = context.Config.NPCPromptDistance
	prompt.HoldDuration = context.Config.NPCPromptHoldDuration
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	model.PrimaryPart = root
	model.Parent = context.Services.MapService.GetFolders().NPCs

	local connection = prompt.Triggered:Connect(function(player)
		context.Services.AccusationService.Accuse(player, npc.Id)
	end)

	table.insert(promptConnections, connection)

	npc.Model = model
	npc.Spawned = true

	return model
end

local function applyJuvenileVisualProfile(npc)
	if not npc.IsJuvenileProfile or npc.JuvenileVisualApplied or not npc.Model then
		return
	end

	local nestingConfig = context.Config.NestingEvent or {}
	npc.JuvenileVisualApplied = true
	npc.Model:ScaleTo(nestingConfig.ModelScale or 0.78)
end

local function ensureHealthBillboard(npc)
	if not npc.Model or not npc.Model.PrimaryPart then
		return nil
	end

	local existing = npc.Model:FindFirstChild("RevealedHealthBillboard")

	if existing then
		return existing
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RevealedHealthBillboard"
	billboard.Adornee = npc.Model.PrimaryPart
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 90
	billboard.Size = UDim2.fromOffset(150, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5.4, 0)
	billboard.Parent = npc.Model

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(8, 14, 10)
	background.BackgroundTransparency = 0.12
	background.BorderSizePixel = 0
	background.Size = UDim2.fromScale(1, 1)
	background.Parent = billboard

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(105, 255, 132)
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = background

	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.BackgroundColor3 = Color3.fromRGB(36, 52, 40)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.fromOffset(8, 20)
	barBack.Size = UDim2.new(1, -16, 0, 7)
	barBack.Parent = background

	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.BackgroundColor3 = Color3.fromRGB(105, 255, 132)
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.Parent = barBack

	local label = Instance.new("TextLabel")
	label.Name = "HealthText"
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(226, 255, 230)
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Size = UDim2.new(1, -8, 0, 18)
	label.Position = UDim2.fromOffset(4, 1)
	label.Text = ""
	label.Parent = background

	return billboard
end

local function updateHealthBillboard(npc)
	local billboard = ensureHealthBillboard(npc)

	if not billboard then
		return
	end

	local background = billboard:FindFirstChild("Background")
	local label = background and background:FindFirstChild("HealthText")
	local barBack = background and background:FindFirstChild("BarBack")
	local barFill = barBack and barBack:FindFirstChild("BarFill")
	local health = npc.Health or 0
	local maxHealth = math.max(npc.MaxHealth or health, 1)
	local ratio = math.clamp(health / maxHealth, 0, 1)

	if label then
		if npc.Escaped then
			label.Text = tostring(npc.AlienType or "ENTITY") .. " ESCAPED"
		elseif npc.Eliminated then
			label.Text = tostring(npc.AlienType or "ENTITY") .. " DOWN"
		else
			label.Text = tostring(npc.AlienType or "ENTITY") .. " " .. math.ceil(health) .. "/" .. math.ceil(maxHealth)
		end
	end

	if barFill then
		barFill.Size = UDim2.fromScale(ratio, 1)

		if npc.Escaped then
			barFill.BackgroundColor3 = Color3.fromRGB(255, 88, 72)
		elseif npc.Eliminated then
			barFill.BackgroundColor3 = Color3.fromRGB(80, 90, 82)
		elseif ratio <= 0.3 then
			barFill.BackgroundColor3 = Color3.fromRGB(255, 102, 96)
		elseif ratio <= 0.6 then
			barFill.BackgroundColor3 = Color3.fromRGB(255, 205, 88)
		else
			barFill.BackgroundColor3 = Color3.fromRGB(105, 255, 132)
		end
	end
end

function NPCService.Init(sharedContext)
	context = sharedContext
	context.NPCs = npcs
end

function NPCService.Start()
	print("[NPCService] Ready")
	NPCService.StartBehaviorLoop()
end

function NPCService.SpawnRoundNPCs()
	NPCService.ClearNPCs()

	context.Services.MapService.EnsureMap()
	local spawnPoints = context.Services.MapService.GetNPCSpawns()

	table.clear(npcs)
	table.clear(npcById)

	for index = 1, context.Config.NPCCount do
		local npc = {
			Id = "NPC_" .. index,
			Index = index,
			DisplayName = context.Config.NPCNames[index] or "Townsperson " .. index,
			Spawned = false,
			NextBehaviorAt = 0,
			SuspicionScore = 0,
			Traits = buildTraitMap(getDecoyTraits(index))
		}

		table.insert(npcs, npc)
		npcById[npc.Id] = npc
		createNPCModel(npc, spawnPoints[index])
	end

	print("[NPCService] Spawned NPCs:", #npcs)

	return npcs
end

function NPCService.StartBehaviorLoop()
	if behaviorLoopRunning then
		return
	end

	behaviorLoopRunning = true

	task.spawn(function()
		while behaviorLoopRunning do
			local behaviorConfig = context.Config.NPCBehavior or {}
			task.wait(behaviorConfig.TickInterval or 1.25)

			if behaviorConfig.Enabled and context.Round.State == "Active" then
				local now = os.clock()

				for _, npc in ipairs(npcs) do
					if not npc.Revealed and not npc.Eliminated and now >= (npc.NextBehaviorAt or 0) then
						if not runJuvenileBehavior(npc) and not runAlienTell(npc) and not runFalsePositiveBehavior(npc) then
							if not runPlayerLookBehavior(npc) and random:NextNumber() <= (behaviorConfig.RandomFacingChance or 0.45) then
								faceRandomDirection(npc)
							end

							if random:NextNumber() <= (behaviorConfig.ShortPauseChance or 0.15) then
								task.wait(random:NextNumber(behaviorConfig.ShortPauseMin or 0.5, behaviorConfig.ShortPauseMax or 1.2))
							end

							if runSocialBehavior(npc) then
								-- Social behavior already moved or faced the NPC.
							elseif random:NextNumber() <= (behaviorConfig.ClusterChance or 0.1) then
								moveNPCToSpawn(npc, chooseLandmarkSpawn())
							elseif random:NextNumber() <= (behaviorConfig.MoveChance or 0.35) then
								moveNPCToSpawn(npc, chooseNearbySpawn(npc, false))
							end
						end

						npc.NextBehaviorAt = os.clock()
							+ random:NextNumber(behaviorConfig.IdlePauseMin or 1.25, behaviorConfig.IdlePauseMax or 3.5)
					end
				end
			end
		end
	end)
end

function NPCService.GetNPCs()
	return npcs
end

function NPCService.GetPublicNPCs()
	local publicNPCs = {}

	for _, npc in ipairs(npcs) do
		table.insert(publicNPCs, {
			Id = npc.Id,
			DisplayName = npc.DisplayName,
			Spawned = npc.Spawned,
			Revealed = npc.Revealed == true,
			Eliminated = npc.Eliminated == true,
			Escaped = npc.Escaped == true,
			SuspicionScore = npc.Revealed and nil or math.floor((npc.SuspicionScore or 0) + 0.5),
			SuspicionLabel = npc.Revealed and nil or getSuspicionLabel(npc.SuspicionScore or 0),
			Health = npc.Revealed and npc.Health or nil,
			MaxHealth = npc.Revealed and npc.MaxHealth or nil,
			AlienType = npc.Revealed and npc.AlienType or nil
		})
	end

	return publicNPCs
end

function NPCService.GetNPCById(npcId)
	return npcById[npcId]
end

function NPCService.AssignTraits(npcId, traits)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Traits = buildTraitMap(traits)

	return npc
end

function NPCService.GetTraitMatchSummary(npcId, discoveredTraits)
	local npc = NPCService.GetNPCById(npcId)
	local matched = 0
	local total = #discoveredTraits
	local missingTraits = {}

	if not npc then
		return {
			Matched = 0,
			Total = total,
			MissingTraits = discoveredTraits
		}
	end

	for _, trait in ipairs(discoveredTraits) do
		if npc.Traits and npc.Traits[trait] then
			matched += 1
		else
			table.insert(missingTraits, trait)
		end
	end

	return {
		Matched = matched,
		Total = total,
		MissingTraits = missingTraits
	}
end

function NPCService.GetPublicSuspects(discoveredTraits)
	local suspects = {}

	for _, npc in ipairs(npcs) do
		if not npc.Revealed then
			local summary = NPCService.GetTraitMatchSummary(npc.Id, discoveredTraits)

			if summary.Matched == summary.Total then
				table.insert(suspects, {
					Id = npc.Id,
					DisplayName = npc.DisplayName,
					MatchedTraits = summary.Matched,
					TotalTraits = summary.Total,
					SuspicionScore = math.floor((npc.SuspicionScore or 0) + 0.5),
					SuspicionLabel = getSuspicionLabel(npc.SuspicionScore or 0)
				})
			end
		end
	end

	return suspects
end

function NPCService.GetHighlySuspiciousNPCs()
	local suspicionConfig = getSuspicionConfig()
	local threshold = suspicionConfig.HighThreshold or 45
	local limit = suspicionConfig.HighlySuspiciousLimit or 4
	local suspicious = {}

	for _, npc in ipairs(npcs) do
		if not npc.Revealed and (npc.SuspicionScore or 0) >= threshold then
			table.insert(suspicious, {
				Id = npc.Id,
				DisplayName = npc.DisplayName,
				SuspicionScore = math.floor((npc.SuspicionScore or 0) + 0.5),
				SuspicionLabel = getSuspicionLabel(npc.SuspicionScore or 0),
				LastSuspicionReason = npc.LastSuspicionReason
			})
		end
	end

	table.sort(suspicious, function(left, right)
		return left.SuspicionScore > right.SuspicionScore
	end)

	while #suspicious > limit do
		table.remove(suspicious)
	end

	return suspicious
end

function NPCService.ApplyClueSuspicion(trait)
	if not trait then
		return
	end

	local suspicionConfig = getSuspicionConfig()
	local amount = suspicionConfig.ClueMatchAmount or 16

	for _, npc in ipairs(npcs) do
		if npc.Traits and npc.Traits[trait] then
			addSuspicion(npc, amount, "ClueMatch:" .. trait, false)
		end
	end
end

function NPCService.AddSuspicion(npcId, amount, reason)
	return addSuspicion(NPCService.GetNPCById(npcId), amount, reason, true)
end

function NPCService.ApplyJuvenileProfile(npcId, nestingConfig)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.IsJuvenileProfile = true
	npc.MoveSpeedOverride = (nestingConfig or {}).JuvenileSpeed

	return npc
end

function NPCService.MarkRevealed(npcId, alienType)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	local wasRevealed = npc.Revealed == true
	npc.Revealed = true
	npc.AlienType = alienType
	npc.Health = npc.Health or (context.Config.RevealedAlienAttack and context.Config.RevealedAlienAttack.MaxHealth) or 120
	npc.MaxHealth = npc.MaxHealth or npc.Health

	if npc.Model then
		applyJuvenileVisualProfile(npc)
		npc.Model.Name = npc.Id .. "_Revealed_" .. alienType

		for _, descendant in ipairs(npc.Model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(104, 255, 132)
				descendant.Material = Enum.Material.Neon
			elseif descendant:IsA("ProximityPrompt") then
				descendant.Enabled = false
			end
		end

		local light = Instance.new("PointLight")
		light.Name = "AlienRevealGlow"
		light.Color = Color3.fromRGB(104, 255, 132)
		light.Brightness = 1.5
		light.Range = 14
		light.Shadows = true
		light.Parent = npc.Model.PrimaryPart

		if not wasRevealed then
			local revealConfig = context.Config.RevealPresentation or {}
			local highlight = Instance.new("Highlight")
			highlight.Name = "RevealFlash"
			highlight.FillColor = Color3.fromRGB(255, 255, 180)
			highlight.OutlineColor = Color3.fromRGB(255, 80, 60)
			highlight.FillTransparency = 0.25
			highlight.OutlineTransparency = 0
			highlight.Parent = npc.Model

			task.delay(revealConfig.PanicHighlightDuration or 1.25, function()
				if highlight.Parent then
					highlight:Destroy()
				end
			end)
		end
	end

	updateHealthBillboard(npc)

	if not wasRevealed and context.Round.State == "Active" then
		panicNearbyNPCs(npc)
	end

	return npc
end

function NPCService.UpdateRevealedHealth(npcId, health, maxHealth)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Health = health
	npc.MaxHealth = maxHealth
	updateHealthBillboard(npc)

	return npc
end

function NPCService.MarkEliminated(npcId)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Eliminated = true
	npc.Health = 0
	updateHealthBillboard(npc)

	if npc.Model then
		for _, descendant in ipairs(npc.Model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(36, 48, 40)
				descendant.Material = Enum.Material.Slate
				descendant.Transparency = 0.25
				descendant.CanCollide = false
			elseif descendant:IsA("PointLight") then
				descendant.Enabled = false
			end
		end
	end

	return npc
end

function NPCService.MarkEscaped(npcId)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Escaped = true
	updateHealthBillboard(npc)

	if npc.Model then
		for _, descendant in ipairs(npc.Model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Color = Color3.fromRGB(255, 88, 72)
				descendant.Material = Enum.Material.Neon
				descendant.Transparency = 0.45
				descendant.CanCollide = false
			elseif descendant:IsA("PointLight") then
				descendant.Color = Color3.fromRGB(255, 88, 72)
			end
		end
	end

	return npc
end

function NPCService.MarkForSeconds(npcId, markerName, color, duration)
	local npc = NPCService.GetNPCById(npcId)

	if not npc or not npc.Model then
		return nil
	end

	local marker = npc.Model:FindFirstChild(markerName)

	if marker then
		marker:Destroy()
	end

	marker = Instance.new("Highlight")
	marker.Name = markerName
	marker.FillColor = color
	marker.OutlineColor = color
	marker.FillTransparency = 0.65
	marker.OutlineTransparency = 0.1
	marker.Parent = npc.Model

	task.delay(duration, function()
		if marker and marker.Parent then
			marker:Destroy()
		end
	end)

	return npc
end

function NPCService.DebugPivotNPCTo(npcId, rootCFrame)
	if not (context.Config.DebugTesting and context.Config.DebugTesting.Enabled) then
		return nil
	end

	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	pivotRootTo(npc, rootCFrame)

	return npc
end

function NPCService.IsRevealed(npcId)
	local npc = NPCService.GetNPCById(npcId)

	return npc and npc.Revealed == true
end

function NPCService.ClearNPCs()
	clearConnectionList()

	clearFolder(context.Services.MapService.GetFolders().NPCs)
	table.clear(npcs)
	table.clear(npcById)
	table.clear(lastSuspicionByNpcId)
	lastSuspicionSnapshotAt = 0
end

return NPCService
