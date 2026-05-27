local CombatService = {}

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

local context
local lastAttackByPlayer = {}

local function getCharacterRoot(player)
	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getOrCreateTool(parent, toolName)
	local existing = parent:FindFirstChild(toolName)

	if existing then
		return existing
	end

	local tool = Instance.new("Tool")
	tool.Name = toolName
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = "Stuns revealed aliens at close range"
	tool.Parent = parent

	return tool
end

local function buildResult(accepted, reason, extra)
	local result = extra or {}
	result.Accepted = accepted
	result.Reason = reason

	return result
end

local function findClosestRevealedAlien(player)
	local root = getCharacterRoot(player)

	if not root then
		return nil, nil
	end

	local combatConfig = context.Config.PlayerCombat or {}
	local range = combatConfig.Range or 16
	local closestRecord
	local closestDistance = range

	for _, record in ipairs(context.Services.AlienService.GetAlienRecords()) do
		if record.Revealed and not record.Eliminated then
			local npc = context.Services.NPCService.GetNPCById(record.NPCId)
			local npcRoot = npc and npc.Model and npc.Model.PrimaryPart

			if npcRoot then
				local distance = (npcRoot.Position - root.Position).Magnitude

				if distance <= closestDistance then
					closestRecord = record
					closestDistance = distance
				end
			end
		end
	end

	return closestRecord, closestDistance
end

local function bindTool(tool)
	if tool:GetAttribute("CombatBound") then
		return
	end

	tool:SetAttribute("CombatBound", true)

	tool.Activated:Connect(function()
		local character = tool.Parent
		local player = character and Players:GetPlayerFromCharacter(character)

		if player then
			CombatService.Attack(player)
		end
	end)
end

local function giveTool(player)
	local combatConfig = context.Config.PlayerCombat or {}
	local toolName = combatConfig.ToolName or "Alien Zapper"

	local starterTool = getOrCreateTool(StarterPack, toolName)

	local backpack = player:FindFirstChildOfClass("Backpack")

	if backpack then
		local tool = backpack:FindFirstChild(toolName)

		if not tool then
			tool = starterTool:Clone()
			tool:SetAttribute("CombatBound", nil)
			tool.Parent = backpack
		end

		bindTool(tool)
	end
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		giveTool(player)
	end)

	task.defer(function()
		giveTool(player)
	end)
end

function CombatService.Init(sharedContext)
	context = sharedContext
end

function CombatService.Start()
	print("[CombatService] Ready")

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerAdded:Connect(setupPlayer)

	Players.PlayerRemoving:Connect(function(player)
		lastAttackByPlayer[player] = nil
	end)
end

function CombatService.Attack(player)
	if context.Round.State ~= "Active" then
		local result = buildResult(false, "RoundNotActive")
		context.Services.RemoteService.SendCombatResult(player, result)
		return result
	end

	if context.Services.PlayerService.IsPlayerDowned(player) then
		local result = buildResult(false, "PlayerDowned")
		context.Services.RemoteService.SendCombatResult(player, result)
		return result
	end

	if context.Services.PlayerService.IsMimicPlayer(player) then
		local result = buildResult(false, "MimicCannotUseWeapon")
		context.Services.RemoteService.SendCombatResult(player, result)
		return result
	end

	local combatConfig = context.Config.PlayerCombat or {}
	local cooldown = combatConfig.Cooldown or 0.85
	local now = os.clock()
	local lastAttack = lastAttackByPlayer[player] or 0

	if now - lastAttack < cooldown then
		local result = buildResult(false, "CombatCooldown", {
			CooldownRemaining = math.max(0, cooldown - (now - lastAttack))
		})
		context.Services.RemoteService.SendCombatResult(player, result)
		return result
	end

	lastAttackByPlayer[player] = now

	local alienRecord, distance = findClosestRevealedAlien(player)

	if not alienRecord then
		local result = buildResult(false, "NoRevealedAlienInRange")
		context.Services.RemoteService.SendCombatResult(player, result)
		return result
	end

	local baseDamage = combatConfig.Damage or 30
	local damageMultiplier = context.Services.PlayerService.GetCombatDamageMultiplier(player)
	local damage = math.floor((baseDamage * damageMultiplier) + 0.5)
	local damageResult = context.Services.AlienService.DamageAlien(alienRecord.NPCId, damage, player)
	context.Services.NPCService.MarkForSeconds(alienRecord.NPCId, "WeaponHitMark", Color3.fromRGB(255, 72, 72), 0.35)

	local result = buildResult(true, nil, {
		NPCId = alienRecord.NPCId,
		Damage = damage,
		Health = damageResult and damageResult.Health or 0,
		MaxHealth = damageResult and damageResult.MaxHealth or 0,
		Eliminated = damageResult and damageResult.Eliminated == true,
		Distance = distance,
		Cooldown = cooldown
	})

	context.Services.RemoteService.SendCombatResult(player, result)
	context.Services.RemoteService.BroadcastNPCSnapshot()

	if result.Eliminated then
		context.Services.ResultService.CheckForPlayersWin()
	end

	return result
end

return CombatService
