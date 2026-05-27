local ClueService = {}

local context
local activeClues = {}
local discoveredTraits = {}
local promptConnections = {}

local function createBaseCluePart(clue, spawnPart)
	local cluePart = Instance.new("Part")
	cluePart.Name = clue.Id
	cluePart.Anchored = true
	cluePart.CanCollide = true
	cluePart.Size = Vector3.new(2, 0.35, 2)
	cluePart.CFrame = spawnPart.CFrame + Vector3.new(0, cluePart.Size.Y / 2, 0)
	cluePart.Color = Color3.fromRGB(255, 245, 180)
	cluePart.Parent = context.Services.MapService.GetFolders().Clues

	return cluePart
end

local function decorateCluePart(cluePart, clue)
	if clue.Prop == "Mirror" then
		cluePart.Size = Vector3.new(2.4, 3.2, 0.25)
		cluePart.Color = Color3.fromRGB(115, 155, 165)
		cluePart.Material = Enum.Material.Glass
		cluePart.CFrame += Vector3.new(0, 1.6, 0)
	elseif clue.Prop == "CornCrate" then
		cluePart.Size = Vector3.new(3, 1.5, 2)
		cluePart.Color = Color3.fromRGB(111, 80, 42)
		cluePart.Material = Enum.Material.WoodPlanks
		cluePart.CFrame += Vector3.new(0, 0.65, 0)
	elseif clue.Prop == "WatchPost" then
		cluePart.Size = Vector3.new(1.5, 4, 1.5)
		cluePart.Color = Color3.fromRGB(48, 62, 70)
		cluePart.Material = Enum.Material.CorrodedMetal
		cluePart.CFrame += Vector3.new(0, 2, 0)
	elseif clue.Prop == "Radio" then
		cluePart.Size = Vector3.new(2.4, 1.4, 1.2)
		cluePart.Color = Color3.fromRGB(34, 39, 40)
		cluePart.Material = Enum.Material.Metal
		cluePart.CFrame += Vector3.new(0, 0.7, 0)
	elseif clue.Prop == "Ledger" then
		cluePart.Size = Vector3.new(2.2, 0.35, 1.5)
		cluePart.Color = Color3.fromRGB(86, 52, 38)
		cluePart.Material = Enum.Material.Fabric
		cluePart.CFrame += Vector3.new(0, 0.18, 0)
	end

	local light = Instance.new("PointLight")
	light.Name = "ClueUneaseGlow"
	light.Color = Color3.fromRGB(135, 210, 170)
	light.Brightness = 0.18
	light.Range = 7
	light.Shadows = true
	light.Parent = cluePart
end

local function clearConnectionList()
	for _, connection in ipairs(promptConnections) do
		connection:Disconnect()
	end

	table.clear(promptConnections)
end

local function clearClueObjects()
	clearConnectionList()

	local folders = context.Services.MapService.GetFolders()

	for _, child in ipairs(folders.Clues:GetChildren()) do
		child:Destroy()
	end
end

local function setClueObjectDiscovered(clue)
	if not clue.Object then
		return
	end

	clue.Object.Color = Color3.fromRGB(255, 230, 105)
	clue.Object.Material = Enum.Material.Neon

	local prompt = clue.Object:FindFirstChildOfClass("ProximityPrompt")

	if prompt then
		prompt.Enabled = false
	end
end

local function createClueObject(clue, spawnPart)
	local cluePart = createBaseCluePart(clue, spawnPart)
	decorateCluePart(cluePart, clue)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InspectCluePrompt"
	prompt.ActionText = "Inspect Clue"
	prompt.ObjectText = "Clue"
	prompt.MaxActivationDistance = context.Config.CluePromptDistance
	prompt.HoldDuration = context.Config.CluePromptHoldDuration
	prompt.RequiresLineOfSight = false
	prompt.Parent = cluePart

	local connection = prompt.Triggered:Connect(function(player)
		ClueService.MarkDiscovered(clue.Id, player)
	end)

	table.insert(promptConnections, connection)
	clue.Object = cluePart
end

function ClueService.Init(sharedContext)
	context = sharedContext
	context.Clues = activeClues
end

function ClueService.Start()
	print("[ClueService] Ready")
end

function ClueService.GenerateCluesForRound()
	clearClueObjects()
	table.clear(activeClues)
	table.clear(discoveredTraits)
	context.Services.MapService.EnsureMap()

	local clueSpawns = context.Services.MapService.GetClueSpawns()

	for index, text in ipairs(context.Config.Clues) do
		local clue = {
			Id = "CLUE_" .. index,
			Text = type(text) == "table" and text.Text or text,
			Prop = type(text) == "table" and text.Prop or clueSpawns[index]:GetAttribute("Prop"),
			Trait = type(text) == "table" and text.Trait or nil,
			TraitHint = type(text) == "table" and context.Config.Traits[text.Trait] and context.Config.Traits[text.Trait].Hint or nil,
			Discovered = false
		}

		table.insert(activeClues, clue)
		createClueObject(clue, clueSpawns[index])
	end

	print("[ClueService] Clues prepared:", #activeClues)

	return activeClues
end

function ClueService.GetActiveClues()
	return activeClues
end

function ClueService.GetPublicClues()
	local publicClues = {}

	for _, clue in ipairs(activeClues) do
		if clue.Discovered then
			table.insert(publicClues, {
				Id = clue.Id,
				Text = clue.Text,
				TraitHint = clue.TraitHint,
				Discovered = true
			})
		else
			table.insert(publicClues, {
				Id = clue.Id,
				Discovered = false
			})
		end
	end

	return publicClues
end

function ClueService.GetDiscoveredTraits()
	return table.clone(discoveredTraits)
end

function ClueService.GetPublicSuspectSnapshot()
	local suspects = context.Services.NPCService.GetPublicSuspects(discoveredTraits)
	local highlySuspicious = context.Services.NPCService.GetHighlySuspiciousNPCs()

	return {
		DiscoveredTraitCount = #discoveredTraits,
		SuspectCount = #suspects,
		Suspects = suspects,
		HighlySuspicious = highlySuspicious
	}
end

function ClueService.MarkDiscovered(clueId, player)
	for _, clue in ipairs(activeClues) do
		if clue.Id == clueId then
			if clue.Discovered then
				return clue
			end

			clue.Discovered = true

			if clue.Trait then
				table.insert(discoveredTraits, clue.Trait)
				context.Services.NPCService.ApplyClueSuspicion(clue.Trait)
			end

			setClueObjectDiscovered(clue)
			context.Services.RemoteService.BroadcastClueSnapshot()
			context.Services.RemoteService.BroadcastSuspectSnapshot()
			context.Services.RemoteService.BroadcastClueDiscovered({
				Id = clue.Id,
				Text = clue.Text,
				TraitHint = clue.TraitHint,
				DiscoveredBy = player and player.Name or nil
			})

			return clue
		end
	end

	return nil
end

function ClueService.ClearClues()
	clearClueObjects()
	table.clear(activeClues)
	table.clear(discoveredTraits)
end

return ClueService
