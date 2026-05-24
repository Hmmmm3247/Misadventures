local PlayerService = {}

local Players = game:GetService("Players")

local context
local playerRecords = {}
local healthConnections = {}
local nextClassIndex = 1

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
			ClassDisplayName = classDefinition.DisplayName or className
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

local function getHumanoid(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function buildPlayerSnapshot(player)
	local record = getRecord(player)
	local humanoid = getHumanoid(player)

	return {
		ClassName = record.ClassName,
		ClassDisplayName = record.ClassDisplayName,
		Health = humanoid and math.floor(humanoid.Health + 0.5) or 0,
		MaxHealth = humanoid and math.floor(humanoid.MaxHealth + 0.5) or 0
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
	local maxHealth = (baseStats.MaxHealth or 100) + (classDefinition.MaxHealthBonus or 0)
	local walkSpeed = (baseStats.WalkSpeed or 16) + (classDefinition.WalkSpeedBonus or 0)
	local healthRatio = 1

	if preserveHealthRatio and humanoid.MaxHealth > 0 then
		healthRatio = humanoid.Health / humanoid.MaxHealth
	end

	humanoid.MaxHealth = maxHealth
	humanoid.Health = math.clamp(maxHealth * healthRatio, 0, maxHealth)
	humanoid.WalkSpeed = walkSpeed
end

local function bindCharacter(player)
	disconnectHealth(player)
	applyCharacterStats(player)

	local humanoid = getHumanoid(player)

	if humanoid then
		healthConnections[player] = humanoid.HealthChanged:Connect(function()
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

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		disconnectHealth(player)
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

function PlayerService.SetPlayerClass(player, className)
	if not isValidClass(className) then
		return {
			Accepted = false,
			Reason = "InvalidClass",
			ClassName = PlayerService.GetPlayerClass(player)
		}
	end

	local classDefinition = context.Config.ClassDefinitions[className]
	local record = getRecord(player)

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

function PlayerService.SendSnapshot(player)
	if not context or not context.Services.RemoteService then
		return
	end

	context.Services.RemoteService.SendPlayerSnapshot(player, buildPlayerSnapshot(player))
end

return PlayerService
