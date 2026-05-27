local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("ChickenAlienHuntRemotes")

local RoundState = Remotes:WaitForChild("RoundState")
local NPCSnapshot = Remotes:WaitForChild("NPCSnapshot")
local ClueSnapshot = Remotes:WaitForChild("ClueSnapshot")
local ClueDiscovered = Remotes:WaitForChild("ClueDiscovered")
local SuspectSnapshot = Remotes:WaitForChild("SuspectSnapshot")
local NPCRevealed = Remotes:WaitForChild("NPCRevealed")
local AccusationResult = Remotes:WaitForChild("AccusationResult")
local CombatResult = Remotes:WaitForChild("CombatResult")
local PlayerSnapshot = Remotes:WaitForChild("PlayerSnapshot")
local MissionWarning = Remotes:WaitForChild("MissionWarning")
local RoundResults = Remotes:WaitForChild("RoundResults")
local SelectClass = Remotes:WaitForChild("SelectClass")
local UseClassAbility = Remotes:WaitForChild("UseClassAbility")
local MimicAction = Remotes:WaitForChild("MimicAction")
local PlacePing = Remotes:WaitForChild("PlacePing")
local DebugCommand = Remotes:WaitForChild("DebugCommand")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local audioConfig = Config.Audio or {}
local debugConfig = Config.DebugTesting or {}
local debugControlsEnabled = debugConfig.Enabled == true and debugConfig.ControlsEnabled == true
local audioFolder = Instance.new("Folder")
audioFolder.Name = "ChickenAlienHuntAudio"
audioFolder.Parent = SoundService

local gui = Instance.new("ScreenGui")
gui.Name = "ChickenAlienHuntHUD"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local topShade = Instance.new("Frame")
topShade.Name = "TopVignette"
topShade.Size = UDim2.new(1, 0, 0, 90)
topShade.BackgroundColor3 = Color3.fromRGB(4, 6, 6)
topShade.BackgroundTransparency = 0.25
topShade.BorderSizePixel = 0
topShade.Parent = gui

local bottomShade = topShade:Clone()
bottomShade.Name = "BottomVignette"
bottomShade.AnchorPoint = Vector2.new(0, 1)
bottomShade.Position = UDim2.new(0, 0, 1, 0)
bottomShade.Parent = gui

local screenPulseEndsAt = 0

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.new(0, 430, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(9, 13, 13)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(68, 92, 82)
panelStroke.Thickness = 1
panelStroke.Transparency = 0.25
panelStroke.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function createLabel(name, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 24)
	label.Font = Enum.Font.Gotham
	label.TextColor3 = color or Color3.fromRGB(242, 245, 248)
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Text = ""
	label.Parent = panel

	return label
end

local titleLabel = createLabel("Title", 18, Color3.fromRGB(204, 225, 185))
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "MISSION TERMINAL"
titleLabel.LayoutOrder = 1

local directiveLabel = createLabel("Directive", 13, Color3.fromRGB(148, 194, 178))
directiveLabel.Text = "DIRECTIVE: IDENTIFY AND ELIMINATE CONFIRMED ENTITIES"
directiveLabel.LayoutOrder = 2

local roundLabel = createLabel("RoundState", 16)
roundLabel.LayoutOrder = 3
local timerLabel = createLabel("Timer", 16)
timerLabel.LayoutOrder = 4
local alienCountLabel = createLabel("AlienCount", 16, Color3.fromRGB(177, 226, 160))
alienCountLabel.LayoutOrder = 5
local revealedAlienLabel = createLabel("RevealedAlienHealth", 14, Color3.fromRGB(165, 235, 175))
revealedAlienLabel.LayoutOrder = 6
revealedAlienLabel.Text = "ENTITY VITALS: NONE CONFIRMED"
local playerLabel = createLabel("PlayerState", 15, Color3.fromRGB(188, 220, 235))
playerLabel.LayoutOrder = 7
local combatStatusLabel = createLabel("CombatStatus", 14, Color3.fromRGB(185, 210, 205))
combatStatusLabel.LayoutOrder = 8
combatStatusLabel.Text = "WEAPON: READY"
local clueLabel = createLabel("ClueList", 14, Color3.fromRGB(170, 205, 188))
clueLabel.Size = UDim2.new(1, 0, 0, 104)
clueLabel.LayoutOrder = 10

local suspectLabel = createLabel("Suspects", 14, Color3.fromRGB(225, 203, 170))
suspectLabel.Size = UDim2.new(1, 0, 0, 82)
suspectLabel.LayoutOrder = 11

local feedbackLabel = createLabel("Feedback", 14, Color3.fromRGB(210, 214, 205))
feedbackLabel.Size = UDim2.new(1, 0, 0, 0)
feedbackLabel.AutomaticSize = Enum.AutomaticSize.Y
feedbackLabel.LayoutOrder = 15

local resultLabel = createLabel("Result", 20, Color3.fromRGB(215, 232, 190))
resultLabel.Font = Enum.Font.GothamBold
resultLabel.Size = UDim2.new(1, 0, 0, 28)
resultLabel.LayoutOrder = 16

local classPanel = Instance.new("Frame")
classPanel.Name = "ClassSelect"
classPanel.BackgroundTransparency = 1
classPanel.Size = UDim2.new(1, 0, 0, 40)
classPanel.LayoutOrder = 9
classPanel.Parent = panel

local classLayout = Instance.new("UIListLayout")
classLayout.FillDirection = Enum.FillDirection.Horizontal
classLayout.Padding = UDim.new(0, 6)
classLayout.SortOrder = Enum.SortOrder.LayoutOrder
classLayout.Parent = classPanel

local classButtons = {}
local currentClassName = nil

local function updateClassButtons()
	for className, button in pairs(classButtons) do
		if className == currentClassName then
			button.BackgroundColor3 = Color3.fromRGB(91, 135, 104)
			button.TextColor3 = Color3.fromRGB(245, 255, 238)
		else
			button.BackgroundColor3 = Color3.fromRGB(30, 42, 40)
			button.TextColor3 = Color3.fromRGB(210, 222, 214)
		end
	end
end

local function createClassButton(className)
	local definition = Config.ClassDefinitions[className] or {}
	local button = Instance.new("TextButton")
	button.Name = className .. "Button"
	button.Size = UDim2.new(0, 76, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(30, 42, 40)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Gotham
	button.Text = definition.DisplayName or className
	button.TextColor3 = Color3.fromRGB(210, 222, 214)
	button.TextSize = 12
	button.TextWrapped = true
	button.Parent = classPanel
	classButtons[className] = button

	button.Activated:Connect(function()
		feedbackLabel.Text = "Selecting class: " .. tostring(definition.DisplayName or className)

		task.spawn(function()
			local success, result = pcall(function()
				return SelectClass:InvokeServer(className)
			end)

			if not success then
				feedbackLabel.Text = "Class select failed"
				return
			end

			if result and result.Accepted then
				currentClassName = result.ClassName
				updateClassButtons()
				feedbackLabel.Text = "Class selected: " .. tostring(result.ClassDisplayName or result.ClassName)
			else
				feedbackLabel.Text = "Class rejected: " .. tostring(result and result.Reason or "Unknown")
			end
		end)
	end)
end

for _, className in ipairs(Config.ClassAssignmentOrder or { "Hunter", "Investigator", "Medic", "Scout", "Engineer" }) do
	createClassButton(className)
end

local abilityButton = Instance.new("TextButton")
abilityButton.Name = "UseAbilityButton"
abilityButton.Size = UDim2.new(1, 0, 0, 34)
abilityButton.BackgroundColor3 = Color3.fromRGB(64, 83, 72)
abilityButton.BorderSizePixel = 0
abilityButton.Font = Enum.Font.GothamBold
abilityButton.Text = "Use Class Ability"
abilityButton.TextColor3 = Color3.fromRGB(238, 246, 232)
abilityButton.TextSize = 14
abilityButton.LayoutOrder = 12
abilityButton.Parent = panel

local mimicButton = Instance.new("TextButton")
mimicButton.Name = "MimicAttackButton"
mimicButton.Size = UDim2.new(1, 0, 0, 34)
mimicButton.BackgroundColor3 = Color3.fromRGB(92, 38, 46)
mimicButton.BorderSizePixel = 0
mimicButton.Font = Enum.Font.GothamBold
mimicButton.Text = "Mimic Strike"
mimicButton.TextColor3 = Color3.fromRGB(255, 226, 226)
mimicButton.TextSize = 14
mimicButton.LayoutOrder = 13
mimicButton.Visible = false
mimicButton.Parent = panel

local abilityCooldownEndsAt = 0
local combatCooldownEndsAt = 0
local pingCooldownEndsAt = 0
local mimicCooldownEndsAt = 0
local abilityButtonBaseText = "Use Class Ability"
local isMimic = false

local function setAbilityCooldown(seconds)
	abilityCooldownEndsAt = math.max(abilityCooldownEndsAt, os.clock() + seconds)
end

local function setCombatCooldown(seconds)
	combatCooldownEndsAt = math.max(combatCooldownEndsAt, os.clock() + seconds)
end

local function setMimicCooldown(seconds)
	mimicCooldownEndsAt = math.max(mimicCooldownEndsAt, os.clock() + seconds)
end

local function startScreenPulse(duration)
	screenPulseEndsAt = math.max(screenPulseEndsAt, os.clock() + (duration or 0.75))
end

local pingPanel = Instance.new("Frame")
pingPanel.Name = "PingPanel"
pingPanel.BackgroundTransparency = 1
pingPanel.Size = UDim2.new(1, 0, 0, 34)
pingPanel.LayoutOrder = 14
pingPanel.Parent = panel

local pingLayout = Instance.new("UIListLayout")
pingLayout.FillDirection = Enum.FillDirection.Horizontal
pingLayout.Padding = UDim.new(0, 6)
pingLayout.SortOrder = Enum.SortOrder.LayoutOrder
pingLayout.Parent = pingPanel

local pingButtons = {}

local function createPingButton(pingType, labelText)
	local button = Instance.new("TextButton")
	button.Name = pingType .. "PingButton"
	button.Size = UDim2.new(0, 128, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(35, 48, 48)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = labelText
	button.TextColor3 = Color3.fromRGB(224, 238, 232)
	button.TextSize = 12
	button.TextWrapped = true
	button.Parent = pingPanel
	pingButtons[pingType] = button

	button.Activated:Connect(function()
		if os.clock() < pingCooldownEndsAt then
			return
		end

		feedbackLabel.Text = "Sending ping: " .. labelText

		task.spawn(function()
			local success, result = pcall(function()
				return PlacePing:InvokeServer(pingType)
			end)

			if not success then
				feedbackLabel.Text = "Ping failed"
				return
			end

			if result and result.Accepted then
				if result.Cooldown then
					pingCooldownEndsAt = math.max(pingCooldownEndsAt, os.clock() + result.Cooldown)
				end

				feedbackLabel.Text = "PING SENT: " .. tostring(result.Label or pingType)
			else
				if result and result.CooldownRemaining then
					pingCooldownEndsAt = math.max(pingCooldownEndsAt, os.clock() + result.CooldownRemaining)
				end

				feedbackLabel.Text = "PING BLOCKED: " .. tostring(result and result.Reason or "Unknown")
			end
		end)
	end)
end

createPingButton("Suspicious", "Suspicious")
createPingButton("Clue", "Clue")
createPingButton("Help", "Help")

local function runDebugCommand(command, labelText)
	feedbackLabel.Text = "Debug: " .. labelText

	task.spawn(function()
		local success, result = pcall(function()
			return DebugCommand:InvokeServer(command)
		end)

		if not success then
			feedbackLabel.Text = "DEBUG FAILED: " .. labelText
			return
		end

		if result and result.Accepted then
			feedbackLabel.Text = tostring(result.Message or ("DEBUG OK: " .. labelText))
		else
			feedbackLabel.Text = "DEBUG BLOCKED: " .. tostring(result and result.Reason or "Unknown")
		end
	end)
end

local function createDebugButton(parent, command, labelText)
	local button = Instance.new("TextButton")
	button.Name = command .. "DebugButton"
	button.Size = UDim2.new(0, 128, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(62, 46, 36)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = labelText
	button.TextColor3 = Color3.fromRGB(248, 226, 205)
	button.TextSize = 11
	button.TextWrapped = true
	button.Parent = parent

	button.Activated:Connect(function()
		runDebugCommand(command, labelText)
	end)

	return button
end

if debugControlsEnabled then
	local debugPanel = Instance.new("Frame")
	debugPanel.Name = "DebugPanel"
	debugPanel.BackgroundTransparency = 1
	debugPanel.Size = UDim2.new(1, 0, 0, 76)
	debugPanel.LayoutOrder = 17
	debugPanel.Parent = panel

	local debugLayout = Instance.new("UIListLayout")
	debugLayout.Padding = UDim.new(0, 6)
	debugLayout.SortOrder = Enum.SortOrder.LayoutOrder
	debugLayout.Parent = debugPanel

	local debugRowOne = Instance.new("Frame")
	debugRowOne.Name = "DebugRowOne"
	debugRowOne.BackgroundTransparency = 1
	debugRowOne.Size = UDim2.new(1, 0, 0, 34)
	debugRowOne.LayoutOrder = 1
	debugRowOne.Parent = debugPanel

	local debugRowTwo = debugRowOne:Clone()
	debugRowTwo.Name = "DebugRowTwo"
	debugRowTwo.LayoutOrder = 2
	debugRowTwo.Parent = debugPanel

	local rowOneLayout = Instance.new("UIListLayout")
	rowOneLayout.FillDirection = Enum.FillDirection.Horizontal
	rowOneLayout.Padding = UDim.new(0, 6)
	rowOneLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowOneLayout.Parent = debugRowOne

	local rowTwoLayout = rowOneLayout:Clone()
	rowTwoLayout.Parent = debugRowTwo

	createDebugButton(debugRowOne, "RevealFirstAlien", "Reveal 1")
	createDebugButton(debugRowOne, "RevealAllAliens", "Reveal All")
	createDebugButton(debugRowOne, "SkipToActive", "Skip Active")
	createDebugButton(debugRowTwo, "ForceWrongPenalty", "Wrong Penalty")
	createDebugButton(debugRowTwo, "SpawnChaseTestAlien", "Chase Test")
	createDebugButton(debugRowTwo, "PrintAggression", "Aggression")
end

abilityButton.Activated:Connect(function()
	if os.clock() < abilityCooldownEndsAt then
		return
	end

	feedbackLabel.Text = "Using class ability..."

	task.spawn(function()
		local success, result = pcall(function()
			return UseClassAbility:InvokeServer()
		end)

		if not success then
			feedbackLabel.Text = "Ability failed"
			return
		end

		if result and result.Accepted then
			if result.Cooldown then
				setAbilityCooldown(result.Cooldown)
			end

			feedbackLabel.Text = tostring(result.Message or result.Ability or "Ability used")
		else
			if result and result.CooldownRemaining then
				setAbilityCooldown(result.CooldownRemaining)
			end

			feedbackLabel.Text = "Ability blocked: " .. tostring(result and result.Reason or "Unknown")
		end
	end)
end)

mimicButton.Activated:Connect(function()
	if not isMimic or os.clock() < mimicCooldownEndsAt then
		return
	end

	feedbackLabel.Text = "Mimic strike..."

	task.spawn(function()
		local success, result = pcall(function()
			return MimicAction:InvokeServer("Attack")
		end)

		if not success then
			feedbackLabel.Text = "Mimic action failed"
			return
		end

		if result and result.Accepted then
			if result.Cooldown then
				setMimicCooldown(result.Cooldown)
			end

			feedbackLabel.Text = "MIMIC STRIKE: " .. tostring(result.Target or "target")
		else
			if result and result.CooldownRemaining then
				setMimicCooldown(result.CooldownRemaining)
			end

			feedbackLabel.Text = "MIMIC BLOCKED: " .. tostring(result and result.Reason or "Unknown")
		end
	end)
end)

task.spawn(function()
	while gui.Parent do
		local remaining = math.max(0, abilityCooldownEndsAt - os.clock())
		local combatRemaining = math.max(0, combatCooldownEndsAt - os.clock())
		local pingRemaining = math.max(0, pingCooldownEndsAt - os.clock())
		local mimicRemaining = math.max(0, mimicCooldownEndsAt - os.clock())
		local pulseRemaining = math.max(0, screenPulseEndsAt - os.clock())

		if pulseRemaining > 0 then
			local alpha = math.clamp(pulseRemaining / 0.75, 0, 1)
			topShade.BackgroundColor3 = Color3.fromRGB(92, 10, 10)
			bottomShade.BackgroundColor3 = Color3.fromRGB(92, 10, 10)
			topShade.BackgroundTransparency = 0.12 + (1 - alpha) * 0.45
			bottomShade.BackgroundTransparency = topShade.BackgroundTransparency
		else
			topShade.BackgroundColor3 = Color3.fromRGB(4, 6, 6)
			bottomShade.BackgroundColor3 = Color3.fromRGB(4, 6, 6)
			topShade.BackgroundTransparency = 0.25
			bottomShade.BackgroundTransparency = 0.25
		end

		if remaining > 0 then
			abilityButton.Text = "Ability: " .. tostring(math.ceil(remaining)) .. "s"
			abilityButton.AutoButtonColor = false
			abilityButton.BackgroundColor3 = Color3.fromRGB(38, 48, 45)
			abilityButton.TextColor3 = Color3.fromRGB(155, 168, 158)
		else
			abilityButton.Text = abilityButtonBaseText
			abilityButton.AutoButtonColor = true
			abilityButton.BackgroundColor3 = Color3.fromRGB(64, 83, 72)
			abilityButton.TextColor3 = Color3.fromRGB(238, 246, 232)
		end

		mimicButton.Visible = isMimic

		if mimicRemaining > 0 then
			mimicButton.Text = "Mimic Strike: " .. tostring(math.ceil(mimicRemaining)) .. "s"
			mimicButton.AutoButtonColor = false
			mimicButton.BackgroundColor3 = Color3.fromRGB(48, 30, 36)
			mimicButton.TextColor3 = Color3.fromRGB(180, 145, 150)
		else
			mimicButton.Text = "Mimic Strike"
			mimicButton.AutoButtonColor = true
			mimicButton.BackgroundColor3 = Color3.fromRGB(92, 38, 46)
			mimicButton.TextColor3 = Color3.fromRGB(255, 226, 226)
		end

		if combatRemaining > 0 then
			combatStatusLabel.Text = "WEAPON: RECALIBRATING " .. tostring(math.ceil(combatRemaining * 10) / 10) .. "s"
		else
			combatStatusLabel.Text = "WEAPON: READY"
		end

		for pingType, button in pairs(pingButtons) do
			if pingRemaining > 0 then
				button.Text = tostring(math.ceil(pingRemaining)) .. "s"
				button.AutoButtonColor = false
				button.BackgroundColor3 = Color3.fromRGB(34, 39, 39)
				button.TextColor3 = Color3.fromRGB(145, 158, 152)
			else
				button.Text = pingType
				button.AutoButtonColor = true
				button.BackgroundColor3 = Color3.fromRGB(35, 48, 48)
				button.TextColor3 = Color3.fromRGB(224, 238, 232)
			end
		end

		task.wait(0.2)
	end
end)

local function formatTime(seconds)
	seconds = math.max(0, seconds or 0)

	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60

	return string.format("%d:%02d", minutes, remainingSeconds)
end

local function createSound(name, soundConfig)
	if not audioConfig.Enabled or not soundConfig then
		return nil
	end

	local resolvedId = (soundConfig.MarketplaceId and soundConfig.MarketplaceId ~= "")
		and ("rbxassetid://" .. soundConfig.MarketplaceId)
		or soundConfig.SoundId

	if not resolvedId or resolvedId == "" then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = resolvedId
	sound.Volume = (soundConfig.Volume or 0.5) * (audioConfig.MasterVolume or 1)
	sound.PlaybackSpeed = soundConfig.PlaybackSpeed or 1
	sound.Looped = soundConfig.Looped == true
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Parent = audioFolder

	return sound
end

local ambientDrone = createSound("AmbientDrone", audioConfig.AmbientDrone)
local clueStinger = createSound("ClueStinger", audioConfig.ClueStinger)
local wrongAccusation = createSound("WrongAccusation", audioConfig.WrongAccusation)
local alienReveal = createSound("AlienReveal", audioConfig.AlienReveal)
local playersWin = createSound("PlayersWin", audioConfig.PlayersWin)
local aliensWin = createSound("AliensWin", audioConfig.AliensWin)

local environmentalPulseSounds = {}

for index, soundConfig in ipairs((audioConfig.EnvironmentalPulses and audioConfig.EnvironmentalPulses.Sounds) or {}) do
	local sound = createSound("EnvironmentalPulse_" .. index, soundConfig)

	if sound then
		table.insert(environmentalPulseSounds, sound)
	end
end

local function playSound(sound)
	if not sound then
		return
	end

	sound.TimePosition = 0
	sound:Play()
end

local function startAudio()
	if ambientDrone and not ambientDrone.IsPlaying then
		ambientDrone:Play()
	end

	task.spawn(function()
		local pulseConfig = audioConfig.EnvironmentalPulses or {}
		local minDelay = pulseConfig.MinDelay or 18
		local maxDelay = pulseConfig.MaxDelay or 36

		while gui.Parent do
			task.wait(math.random(minDelay, maxDelay))

			if #environmentalPulseSounds > 0 then
				playSound(environmentalPulseSounds[math.random(1, #environmentalPulseSounds)])
			end
		end
	end)
end

print("Chicken Alien Hunt client loaded")
startAudio()

RoundState.OnClientEvent:Connect(function(roundState)
	roundLabel.Text = "PHASE: " .. tostring(roundState.State or "Unknown")
	timerLabel.Text = "TIME LIMIT: " .. formatTime(roundState.TimeRemaining)
	alienCountLabel.Text = "ENTITIES CONFIRMED: " .. tostring(roundState.AliensFound or 0) .. "/" .. tostring(roundState.AlienCount or 0)
end)

NPCSnapshot.OnClientEvent:Connect(function(npcs)
	print("[Client] NPC snapshot received:", #npcs)

	local revealed = {}

	for _, npc in ipairs(npcs) do
		if npc.Revealed then
			local healthText = tostring(npc.Health or 0) .. "/" .. tostring(npc.MaxHealth or 0)
			local status = npc.Escaped and "escaped" or (npc.Eliminated and "down" or healthText)

			table.insert(revealed, tostring(npc.DisplayName or npc.Id) .. " " .. status)
		end
	end

	if #revealed > 0 then
		revealedAlienLabel.Text = "ENTITY VITALS: " .. table.concat(revealed, ", ")
	else
		revealedAlienLabel.Text = "ENTITY VITALS: NONE CONFIRMED"
	end
end)

ClueSnapshot.OnClientEvent:Connect(function(clues)
	local discovered = {}

	for _, clue in ipairs(clues) do
		if clue.Discovered then
			table.insert(discovered, "- " .. (clue.TraitHint or clue.Text or "Unknown trait"))
		end
	end

	if #discovered > 0 then
		clueLabel.Text = "EVIDENCE LOG:\n" .. table.concat(discovered, "\n")
	else
		clueLabel.Text = "EVIDENCE LOG:\nNO SIGNAL"
	end
end)

ClueDiscovered.OnClientEvent:Connect(function(clue)
	feedbackLabel.Text = "EVIDENCE ACQUIRED: " .. (clue.TraitHint or clue.Text)
	playSound(clueStinger)
end)

SuspectSnapshot.OnClientEvent:Connect(function(snapshot)
	local names = {}
	local suspiciousNames = {}

	for _, suspect in ipairs(snapshot.Suspects or {}) do
		local scoreText = suspect.SuspicionScore and (" [" .. tostring(suspect.SuspicionScore) .. "]") or ""
		table.insert(names, tostring(suspect.DisplayName) .. scoreText)
	end

	for _, suspect in ipairs(snapshot.HighlySuspicious or {}) do
		table.insert(suspiciousNames, tostring(suspect.DisplayName) .. " [" .. tostring(suspect.SuspicionScore or 0) .. "]")
	end

	if #names > 0 then
		local suspiciousText = #suspiciousNames > 0 and ("\nHIGHLY SUSPICIOUS: " .. table.concat(suspiciousNames, ", ")) or ""
		suspectLabel.Text = "MATCHING HOSTS: " .. tostring(snapshot.SuspectCount) .. "\n" .. table.concat(names, ", ") .. suspiciousText
	elseif #suspiciousNames > 0 then
		suspectLabel.Text = "MATCHING HOSTS: " .. tostring(snapshot.SuspectCount or 0) .. "\nHIGHLY SUSPICIOUS: " .. table.concat(suspiciousNames, ", ")
	else
		suspectLabel.Text = "MATCHING HOSTS: " .. tostring(snapshot.SuspectCount or 0) .. "\nNO UNREVEALED MATCHES"
	end
end)

NPCRevealed.OnClientEvent:Connect(function(reveal)
	feedbackLabel.Text = "ENTITY CONFIRMED: " .. reveal.NPCId .. " / " .. reveal.AlienType .. " / PANIC EVENT"
	startScreenPulse((Config.RevealPresentation and Config.RevealPresentation.ScreenPulseDuration) or 1)
	playSound(alienReveal)
end)

AccusationResult.OnClientEvent:Connect(function(result)
	if not result.Accepted then
		feedbackLabel.Text = "ACCUSATION REJECTED: " .. tostring(result.Reason)
		playSound(wrongAccusation)
	elseif result.Correct then
		feedbackLabel.Text = "HOST BREACH CONFIRMED: " .. result.NPCId
	else
		feedbackLabel.Text = "FALSE TARGET: " .. tostring(result.RiskReason)
		playSound(wrongAccusation)
	end
end)

CombatResult.OnClientEvent:Connect(function(result)
	if not result.Accepted then
		if result.CooldownRemaining then
			setCombatCooldown(result.CooldownRemaining)
		end

		feedbackLabel.Text = "WEAPON BLOCKED: " .. tostring(result.Reason)
	elseif result.Eliminated then
		if result.Cooldown then
			setCombatCooldown(result.Cooldown)
		end

		feedbackLabel.Text = "ENTITY TERMINATED: " .. tostring(result.NPCId)
	else
		if result.Cooldown then
			setCombatCooldown(result.Cooldown)
		end

		feedbackLabel.Text = "WEAPON HIT: "
			.. tostring(result.NPCId)
			.. " / -"
			.. tostring(result.Damage)
			.. " / "
			.. tostring(result.Health)
			.. "/"
			.. tostring(result.MaxHealth)
	end
end)

PlayerSnapshot.OnClientEvent:Connect(function(snapshot)
	currentClassName = snapshot.ClassName
	isMimic = snapshot.IsMimic == true
	updateClassButtons()
	local downedText = snapshot.Downed and " / DOWNED" or ""
	local eliminatedText = snapshot.IsEliminated and " / ELIMINATED" or ""
	local mimicText = isMimic and " / MIMIC HOST" or ""
	playerLabel.Text = "OPERATIVE: "
		.. tostring(snapshot.ClassDisplayName or snapshot.ClassName or "Unknown")
		.. " / VITALS: "
		.. tostring(snapshot.Health or 0)
		.. "/"
		.. tostring(snapshot.MaxHealth or 0)
		.. downedText
		.. eliminatedText
		.. mimicText

	if isMimic then
		feedbackLabel.Text = tostring(snapshot.MimicObjective or "NEW OBJECTIVE: ELIMINATE THE PARTY")
	elseif snapshot.Downed then
		feedbackLabel.Text = "YOU ARE DOWN: wait for teammate revive"
	elseif snapshot.IsEliminated then
		feedbackLabel.Text = "SIGNAL LOST: awaiting round outcome"
	end
end)

MissionWarning.OnClientEvent:Connect(function(warning)
	if type(warning) == "table" then
		feedbackLabel.Text = tostring(warning.Text or warning.Message or "MISSION WARNING")

		if warning.ScreenPulse then
			startScreenPulse(warning.ScreenPulseDuration or 0.75)
		end
	else
		feedbackLabel.Text = tostring(warning)
	end
end)

RoundResults.OnClientEvent:Connect(function(results)
	resultLabel.Text = "RESULT: " .. tostring(results.Winner)

	local lines = {}

	local reasonText = results.Reason == "AlienEscaped" and "CONTAINMENT FAILED: alien escaped"
		or results.Reason == "AllAliensEliminated" and "MISSION COMPLETE: all entities neutralized"
		or results.Reason == "AllPlayersDown" and "SIGNAL LOST: all operatives down"
		or ("MISSION CLOSED: " .. tostring(results.Reason))
	table.insert(lines, reasonText)

	if results.AccusationCount and results.AccusationCount > 0 then
		local wrongText = results.WrongAccusations and results.WrongAccusations > 0
			and (" / " .. tostring(results.WrongAccusations) .. " FALSE")
			or ""
		table.insert(lines, "ACCUSATIONS: " .. tostring(results.AccusationCount) .. wrongText)
	end

	if results.RevealedAliens and #results.RevealedAliens > 0 then
		local alienLines = {}
		for _, alien in ipairs(results.RevealedAliens) do
			local name = tostring(alien.DisplayName or alien.NPCId)
			local status = alien.Eliminated and "NEUTRALIZED"
				or alien.Escaped and "ESCAPED"
				or "ACTIVE"
			local tag = alien.IsJuvenile and " [JUVENILE]" or ""
			table.insert(alienLines, name .. ": " .. status .. tag)
		end
		table.insert(lines, "ENTITIES:\n" .. table.concat(alienLines, "\n"))
	end

	feedbackLabel.Text = table.concat(lines, "\n")

	if results.Winner == "Players" then
		playSound(playersWin)
	else
		playSound(aliensWin)
	end
end)
