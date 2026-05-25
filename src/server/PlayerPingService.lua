local PlayerPingService = {}

local context
local lastPingByPlayer = {}

local function getPingConfig()
	return context.Config.PlayerPings or {}
end

local function getPingDefinition(pingType)
	return (getPingConfig().Types or {})[pingType]
end

local function reject(reason, extra)
	local result = extra or {}
	result.Accepted = false
	result.Reason = reason

	return result
end

local function getCharacterRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getMarkerColor(definition)
	local color = definition and definition.Color

	if typeof(color) == "Color3" then
		return color
	end

	if type(color) == "table" then
		return Color3.fromRGB(color[1] or 110, color[2] or 210, color[3] or 255)
	end

	return Color3.fromRGB(110, 210, 255)
end

local function createWorldMarker(player, pingType, definition, position)
	local pingConfig = getPingConfig()

	if not pingConfig.WorldMarkersEnabled then
		return
	end

	local folders = context.Services.MapService.GetFolders()
	local markerColor = getMarkerColor(definition)
	local duration = pingConfig.MarkerDuration or 8

	local marker = Instance.new("Part")
	marker.Name = "PlayerPing_" .. pingType
	marker.Anchored = true
	marker.CanCollide = false
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(4, 0.2, 4)
	marker.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0))
	marker.Color = markerColor
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.35
	marker.Parent = folders.Props

	local light = Instance.new("PointLight")
	light.Name = "PlayerPingGlow"
	light.Color = markerColor
	light.Brightness = 0.6
	light.Range = 12
	light.Parent = marker

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerPingLabel"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 100
	billboard.Size = UDim2.fromOffset(160, 28)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	billboard.Adornee = marker
	billboard.Parent = marker

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(235, 250, 242)
	label.TextSize = 12
	label.TextStrokeTransparency = 0.35
	label.Size = UDim2.fromScale(1, 1)
	label.Text = (definition.Label or pingType) .. " / " .. player.Name
	label.Parent = billboard

	task.delay(duration, function()
		if marker.Parent then
			marker:Destroy()
		end
	end)
end

function PlayerPingService.Init(sharedContext)
	context = sharedContext
end

function PlayerPingService.Start()
	print("[PlayerPingService] Ready")

	context.Services.RemoteService.BindPlayerPingHandler(function(player, pingType)
		return PlayerPingService.PlacePing(player, pingType)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastPingByPlayer[player] = nil
	end)
end

function PlayerPingService.PlacePing(player, pingType)
	local pingConfig = getPingConfig()

	if not pingConfig.Enabled then
		return reject("PingsDisabled")
	end

	if context.Round.State ~= "Active" then
		return reject("RoundNotActive")
	end

	if typeof(pingType) ~= "string" then
		return reject("InvalidPingType")
	end

	local definition = getPingDefinition(pingType)

	if not definition then
		return reject("UnknownPingType")
	end

	local now = os.clock()
	local cooldown = pingConfig.Cooldown or 4
	local lastPing = lastPingByPlayer[player] or 0

	if now - lastPing < cooldown then
		return reject("PingCooldown", {
			CooldownRemaining = math.max(0, cooldown - (now - lastPing))
		})
	end

	local root = getCharacterRoot(player)

	if not root then
		return reject("NoCharacter")
	end

	lastPingByPlayer[player] = now

	local text = "TEAM PING: " .. player.Name .. " marked " .. string.lower(definition.Label or pingType) .. "."
	context.Services.RemoteService.BroadcastMissionWarning({
		Text = text,
		Severity = "PlayerPing",
		PingType = pingType,
		PlayerName = player.Name
	})
	createWorldMarker(player, pingType, definition, root.Position)

	print("[PlayerPingService] Ping:", player.Name, pingType)

	return {
		Accepted = true,
		PingType = pingType,
		Label = definition.Label,
		Cooldown = cooldown
	}
end

return PlayerPingService
