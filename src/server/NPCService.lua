local NPCService = {}

local Players = game:GetService("Players")

local context
local npcs = {}
local npcById = {}
local promptConnections = {}
local behaviorLoopRunning = false
local lastSuspicionByNpcId = {}
local random = Random.new()

local bodyColors = {
	Color3.fromRGB(62, 86, 96),
	Color3.fromRGB(105, 77, 55),
	Color3.fromRGB(72, 94, 70),
	Color3.fromRGB(91, 73, 101),
	Color3.fromRGB(102, 66, 70)
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

local function moveNPCToSpawn(npc, spawnPart)
	if not spawnPart or not npc.Model or not npc.Model.PrimaryPart then
		return
	end

	local behaviorConfig = context.Config.NPCBehavior or {}
	local moveSpeed = behaviorConfig.MoveSpeed or 7
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
	local suspicionConfig = context.Config.SuspicionEvents or {}

	if not suspicionConfig.Enabled then
		return
	end

	local now = os.clock()

	if now - (lastSuspicionByNpcId[npc.Id] or 0) < (suspicionConfig.Cooldown or 8) then
		return
	end

	local rootCFrame = getRootCFrame(npc)

	if not rootCFrame then
		return
	end

	local nearbyPlayers = getNearbyPlayers(rootCFrame.Position, context.Config.AlienBehavior.PlayerNoticeRange or 28)

	if #nearbyPlayers == 0 or random:NextNumber() > (suspicionConfig.NoticeChance or 0.4) then
		return
	end

	local messages = suspicionConfig.Messages or {}
	local text = fallbackMessage or messages[random:NextInteger(1, math.max(#messages, 1))] or "BEHAVIOR FLAG: host movement anomaly detected."
	lastSuspicionByNpcId[npc.Id] = now

	for _, player in ipairs(nearbyPlayers) do
		context.Services.RemoteService.SendMissionWarning(player, {
			Text = text,
			Severity = "Suspicion"
		})
	end
end

local function runAlienTell(npc)
	local behaviorConfig = context.Config.AlienBehavior or {}

	if not behaviorConfig.Enabled or not context.Services.AlienService.IsAlien(npc.Id) or npc.Revealed then
		return false
	end

	if random:NextNumber() > (behaviorConfig.TellChance or 0.2) then
		return false
	end

	local tellType = random:NextInteger(1, 4)
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
	else
		if random:NextNumber() <= (behaviorConfig.LightAvoidanceChance or 0.5) then
			local spawn = chooseNearbySpawn(npc, true)

			if spawn then
				sendSuspicionIfSeen(npc, "BEHAVIOR FLAG: one host recoiled from direct light.")
				moveNPCToSpawn(npc, spawn)
				return true
			end
		end
	end

	return false
end

local function createNPCModel(npc, spawnPart)
	local model = Instance.new("Model")
	model.Name = npc.Id
	local bodyColor = bodyColors[((npc.Index - 1) % #bodyColors) + 1]

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
	head.Color = Color3.fromRGB(190, 176, 153)
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
	leftArm.CFrame = root.CFrame * CFrame.new(-1.2, -0.15, 0)
	leftArm.Parent = model

	local rightArm = leftArm:Clone()
	rightArm.Name = "RightArm"
	rightArm.CFrame = root.CFrame * CFrame.new(1.45, 0.15, 0)
	rightArm.Parent = model

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.Size = Vector3.new(0.6, 2.2, 0.6)
	leftLeg.Color = Color3.fromRGB(31, 38, 42)
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.45, -2.45, 0)
	leftLeg.Parent = model

	local rightLeg = leftLeg:Clone()
	rightLeg.Name = "RightLeg"
	rightLeg.CFrame = root.CFrame * CFrame.new(0.55, -2.25, 0)
	rightLeg.Parent = model

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
						if not runAlienTell(npc) then
							if random:NextNumber() <= (behaviorConfig.RandomFacingChance or 0.45) then
								faceRandomDirection(npc)
							end

							if random:NextNumber() <= (behaviorConfig.MoveChance or 0.35) then
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
					TotalTraits = summary.Total
				})
			end
		end
	end

	return suspects
end

function NPCService.MarkRevealed(npcId, alienType)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Revealed = true
	npc.AlienType = alienType
	npc.Health = npc.Health or (context.Config.RevealedAlienAttack and context.Config.RevealedAlienAttack.MaxHealth) or 120
	npc.MaxHealth = npc.MaxHealth or npc.Health

	if npc.Model then
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

	return npc
end

function NPCService.MarkEliminated(npcId)
	local npc = NPCService.GetNPCById(npcId)

	if not npc then
		return nil
	end

	npc.Eliminated = true
	npc.Health = 0

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
end

return NPCService
