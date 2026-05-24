local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

local MapService = {}

local context
local folders = {}
local mapBuilt = false

local WORLD_FOLDER_NAME = "ChickenAlienHunt"

local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)

	if folder then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	return folder
end

local function createPart(parent, name, cframe, size, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Transparency = transparency or 0
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function clearFolder(folder)
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
end

local function createGeneratedSpawns(folder, prefix, count, radius, y)
	if #folder:GetChildren() >= count then
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end

	for index = 1, count do
		local angle = ((index - 1) / count) * math.pi * 2
		local cframe = CFrame.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		local spawn = createPart(folder, prefix .. "_" .. index, cframe, Vector3.new(4, 1, 4), Color3.fromRGB(80, 160, 255), 1)
		spawn.CanCollide = false
	end
end

local function createGeneratedPlayerSpawns(folder)
	if #folder:GetChildren() > 0 then
		return
	end

	for index = 1, math.max(context.Config.MinPlayers, 1) do
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlayerSpawn_" .. index
		spawn.Anchored = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.CFrame = CFrame.new((index - 1) * 10, 1, -58)
		spawn.Color = Color3.fromRGB(120, 200, 255)
		spawn.Neutral = true
		spawn.Transparency = 0.35
		spawn.Parent = folder
	end
end

local function createSpawnLocation(parent, name, position)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(position)
	spawn.Color = Color3.fromRGB(120, 200, 255)
	spawn.Neutral = true
	spawn.Transparency = 0.35
	spawn.Parent = parent

	return spawn
end

local function getSortedChildren(folder)
	local children = folder:GetChildren()

	table.sort(children, function(left, right)
		return left.Name < right.Name
	end)

	return children
end

local function createGround(root)
	local groundConfig = MapLayout.Ground
	local size = groundConfig and groundConfig.Size or Vector3.new(130, 1, 130)
	local position = groundConfig and groundConfig.Position or Vector3.new(0, -0.5, 0)
	local color = groundConfig and groundConfig.Color or Color3.fromRGB(72, 130, 74)

	local existingGround = root:FindFirstChild("Ground")

	if existingGround then
		existingGround.Size = size
		existingGround.CFrame = CFrame.new(position)
		existingGround.Color = color
		existingGround.Material = groundConfig and groundConfig.Material or Enum.Material.Ground
		return
	end

	local ground = createPart(root, "Ground", CFrame.new(position), size, color, 0)
	ground.Material = groundConfig and groundConfig.Material or Enum.Material.Ground
end

local function clearGeneratedEffects()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:GetAttribute("ChickenAlienHuntEffect") then
			child:Destroy()
		end
	end
end

local function applyLighting()
	local lightingConfig = MapLayout.Lighting

	if not lightingConfig then
		return
	end

	Lighting.ClockTime = lightingConfig.ClockTime
	Lighting.Brightness = lightingConfig.Brightness
	Lighting.Ambient = lightingConfig.Ambient
	Lighting.OutdoorAmbient = lightingConfig.OutdoorAmbient
	Lighting.FogColor = lightingConfig.FogColor
	Lighting.FogStart = lightingConfig.FogStart
	Lighting.FogEnd = lightingConfig.FogEnd

	clearGeneratedEffects()

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "ChickenAlienHuntAtmosphere"
	atmosphere.Color = lightingConfig.AtmosphereColor
	atmosphere.Decay = lightingConfig.AtmosphereDecay
	atmosphere.Density = lightingConfig.AtmosphereDensity
	atmosphere.Glare = lightingConfig.AtmosphereGlare
	atmosphere.Haze = lightingConfig.AtmosphereHaze
	atmosphere:SetAttribute("ChickenAlienHuntEffect", true)
	atmosphere.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ChickenAlienHuntColor"
	colorCorrection.TintColor = lightingConfig.ColorCorrectionTint
	colorCorrection.Brightness = lightingConfig.ColorCorrectionBrightness
	colorCorrection.Contrast = lightingConfig.ColorCorrectionContrast
	colorCorrection.Saturation = lightingConfig.ColorCorrectionSaturation
	colorCorrection:SetAttribute("ChickenAlienHuntEffect", true)
	colorCorrection.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "ChickenAlienHuntBloom"
	bloom.Intensity = 0.18
	bloom.Size = 18
	bloom.Threshold = 1.1
	bloom:SetAttribute("ChickenAlienHuntEffect", true)
	bloom.Parent = Lighting

	local depthOfField = Instance.new("DepthOfFieldEffect")
	depthOfField.Name = "ChickenAlienHuntDepth"
	depthOfField.FarIntensity = 0.28
	depthOfField.FocusDistance = 72
	depthOfField.InFocusRadius = 34
	depthOfField.NearIntensity = 0.04
	depthOfField:SetAttribute("ChickenAlienHuntEffect", true)
	depthOfField.Parent = Lighting
end

local function createAuthoredSpawns()
	if MapLayout.PlayerSpawns and #MapLayout.PlayerSpawns > 0 then
		clearFolder(folders.PlayerSpawns)

		for index, position in ipairs(MapLayout.PlayerSpawns) do
			createSpawnLocation(folders.PlayerSpawns, "PlayerSpawn_" .. index, position)
		end
	else
		createGeneratedPlayerSpawns(folders.PlayerSpawns)
	end

	if MapLayout.NPCSpawns and #MapLayout.NPCSpawns >= context.Config.NPCCount then
		clearFolder(folders.NPCSpawns)

		for index, position in ipairs(MapLayout.NPCSpawns) do
			local spawn = createPart(
				folders.NPCSpawns,
				"NPCSpawn_" .. index,
				CFrame.new(position),
				Vector3.new(4, 1, 4),
				Color3.fromRGB(80, 160, 255),
				1
			)
			spawn.CanCollide = false
		end
	else
		createGeneratedSpawns(folders.NPCSpawns, "NPCSpawn", context.Config.NPCCount, context.Config.NPCSpawnRadius, 0)
	end

	if MapLayout.ClueSpawns and #MapLayout.ClueSpawns >= #context.Config.Clues then
		clearFolder(folders.ClueSpawns)

		for index, clueSpawn in ipairs(MapLayout.ClueSpawns) do
			local spawn = createPart(
				folders.ClueSpawns,
				clueSpawn.Name or "ClueSpawn_" .. index,
				CFrame.new(clueSpawn.Position),
				Vector3.new(4, 1, 4),
				Color3.fromRGB(255, 230, 105),
				1
			)
			spawn.CanCollide = false
			spawn:SetAttribute("Prop", clueSpawn.Prop)
		end
	else
		createGeneratedSpawns(folders.ClueSpawns, "ClueSpawn", #context.Config.Clues, context.Config.ClueSpawnRadius, 0)
	end
end

local function createArenaProps()
	clearFolder(folders.Props)

	for _, propConfig in ipairs(MapLayout.Props or {}) do
		local prop = createPart(
			folders.Props,
			propConfig.Name,
			CFrame.new(propConfig.Position),
			propConfig.Size,
			propConfig.Color,
			0
		)

		if propConfig.Shape then
			prop.Shape = propConfig.Shape
		end

		if propConfig.Material then
			prop.Material = propConfig.Material
		end
	end
end

local function createFenceSegments()
	clearFolder(folders.SetDressing)

	for index, position in ipairs(MapLayout.Fences or {}) do
		local fence = createPart(
			folders.SetDressing,
			"RottenFence_" .. index,
			CFrame.new(position) * CFrame.Angles(0, index % 2 == 0 and math.rad(4) or math.rad(-7), 0),
			Vector3.new(14, 4, 0.45),
			Color3.fromRGB(48, 42, 36),
			0
		)
		fence.Material = Enum.Material.Wood
	end

	for index, position in ipairs(MapLayout.WarningPosts or {}) do
		local post = createPart(
			folders.SetDressing,
			"WarningPost_" .. index,
			CFrame.new(position) * CFrame.Angles(0, math.rad(index * 17), math.rad(index % 2 == 0 and 3 or -4)),
			Vector3.new(0.8, 6, 0.8),
			Color3.fromRGB(43, 38, 35),
			0
		)
		post.Material = Enum.Material.Wood

		local sign = createPart(
			folders.SetDressing,
			"WarningSign_" .. index,
			CFrame.new(position + Vector3.new(0, 1.4, -0.45)),
			Vector3.new(4, 1.6, 0.25),
			Color3.fromRGB(90, 56, 42),
			0
		)
		sign.Material = Enum.Material.WoodPlanks
	end
end

local function createLightSources()
	clearFolder(folders.Lights)

	for _, lightConfig in ipairs(MapLayout.LightSources or {}) do
		local holder = createPart(
			folders.Lights,
			lightConfig.Name,
			CFrame.new(lightConfig.Position),
			Vector3.new(0.9, 0.9, 0.9),
			lightConfig.Color,
			0
		)
		holder.Material = Enum.Material.Neon

		local light = Instance.new("PointLight")
		light.Color = lightConfig.Color
		light.Brightness = lightConfig.Brightness
		light.Range = lightConfig.Range
		light.Shadows = true
		light.Parent = holder
	end
end

function MapService.Init(sharedContext)
	context = sharedContext

	local root = getOrCreateFolder(Workspace, WORLD_FOLDER_NAME)

	folders = {
		Root = root,
		PlayerSpawns = getOrCreateFolder(root, "PlayerSpawns"),
		NPCSpawns = getOrCreateFolder(root, "NPCSpawns"),
		ClueSpawns = getOrCreateFolder(root, "ClueSpawns"),
		NPCs = getOrCreateFolder(root, "NPCs"),
		Clues = getOrCreateFolder(root, "Clues"),
		Props = getOrCreateFolder(root, "Props"),
		SetDressing = getOrCreateFolder(root, "SetDressing"),
		Lights = getOrCreateFolder(root, "Lights")
	}

	context.Map = folders
end

function MapService.Start()
	MapService.EnsureMap()
	print("[MapService] Ready")
end

function MapService.EnsureMap()
	if mapBuilt then
		return
	end

	createGround(folders.Root)
	applyLighting()
	createAuthoredSpawns()
	createArenaProps()
	createFenceSegments()
	createLightSources()
	mapBuilt = true
end

function MapService.GetFolders()
	return folders
end

function MapService.GetNPCSpawns()
	return getSortedChildren(folders.NPCSpawns)
end

function MapService.GetClueSpawns()
	return getSortedChildren(folders.ClueSpawns)
end

function MapService.GetLightPositions()
	local positions = {}

	for _, lightPart in ipairs(folders.Lights:GetChildren()) do
		if lightPart:IsA("BasePart") then
			table.insert(positions, lightPart.Position)
		end
	end

	return positions
end

return MapService
