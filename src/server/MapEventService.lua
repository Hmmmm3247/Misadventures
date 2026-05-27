local MapEventService = {}

local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local context
local eventLoopRunning = false
local random

local function getEventConfig()
	return context.Config.MapEvents or {}
end

local function getActiveRoundLength()
	local debugConfig = context.Config.DebugTesting or {}

	if debugConfig.Enabled == true and type(debugConfig.RoundLength) == "number" then
		return debugConfig.RoundLength
	end

	return context.Config.RoundLength or 300
end

local function getRoundTensionMultiplier()
	local eventConfig = getEventConfig()
	local tensionConfig = eventConfig.TensionScaling or {}

	if tensionConfig.Enabled == false or context.Round.State ~= "Active" then
		return 1
	end

	local roundLength = getActiveRoundLength()
	local remaining = context.Round.TimeRemaining or roundLength
	local multiplier = 1

	if remaining <= roundLength * (tensionConfig.LateRoundRemainingRatio or 0.3) then
		multiplier *= tensionConfig.LateRoundIntervalMultiplier or 1.8
	elseif remaining <= roundLength * (tensionConfig.MidRoundRemainingRatio or 0.6) then
		multiplier *= tensionConfig.MidRoundIntervalMultiplier or 1.25
	end

	if context.Services.AlienService and context.Services.AlienService.GetRevealedCount() > 0 then
		multiplier *= tensionConfig.AfterRevealIntervalMultiplier or 1.45
	end

	return multiplier
end

local function getScaledChance(baseChance)
	local eventConfig = getEventConfig()
	local tensionConfig = eventConfig.TensionScaling or {}
	local chance = baseChance or 0
	local roundLength = getActiveRoundLength()
	local remaining = context.Round.TimeRemaining or roundLength

	if context.Services.AlienService and context.Services.AlienService.GetRevealedCount() > 0 then
		chance += tensionConfig.AfterRevealChanceBonus or 0
	end

	if remaining <= roundLength * (tensionConfig.LateRoundRemainingRatio or 0.3) then
		chance += tensionConfig.LateRoundChanceBonus or 0
	end

	return math.clamp(chance, 0, 1)
end

local function getLateRoundChance(baseChance)
	local eventConfig = getEventConfig()
	local tensionConfig = eventConfig.TensionScaling or {}
	local roundLength = getActiveRoundLength()
	local remaining = context.Round.TimeRemaining or roundLength

	if remaining > roundLength * (tensionConfig.LateRoundRemainingRatio or 0.3) then
		return baseChance or 0
	end

	return math.clamp((baseChance or 0) + (tensionConfig.LateRoundChanceBonus or 0), 0, 1)
end

local function waitForNextEvent()
	local eventConfig = getEventConfig()
	local minInterval = eventConfig.MinInterval or 28
	local maxInterval = eventConfig.MaxInterval or 46
	local multiplier = getRoundTensionMultiplier()

	task.wait(random:NextNumber(minInterval, maxInterval) / math.max(multiplier, eventConfig.MinimumIntervalDivisor or 0.1))
end

local function chooseFromList(list)
	if not list or #list == 0 then
		return nil
	end

	return list[random:NextInteger(1, #list)]
end

local function chooseAlienPulseEvent()
	local eventConfig = getEventConfig()
	local pulseEvents = eventConfig.AlienPulseEvents or {}
	local positions = context.Services.AlienService and context.Services.AlienService.GetActiveAlienPositions() or {}
	local template = chooseFromList(pulseEvents)

	if not template or #positions == 0 then
		return nil
	end

	local event = table.clone(template)
	event.Position = positions[random:NextInteger(1, #positions)]

	return event
end

local function chooseEvent()
	local eventConfig = getEventConfig()
	local events = eventConfig.Events or {}

	if random:NextNumber() <= getScaledChance(eventConfig.AlienPulseEventChance or 0) then
		local alienPulseEvent = chooseAlienPulseEvent()

		if alienPulseEvent then
			return alienPulseEvent
		end
	end

	if random:NextNumber() <= getScaledChance(eventConfig.FalsePositiveEventChance or 0) then
		events = eventConfig.FalsePositiveEvents or events
	elseif random:NextNumber() <= getScaledChance(eventConfig.PanicEventChance or 0) then
		events = eventConfig.PanicEvents or events
	end

	if random:NextNumber() <= getLateRoundChance(eventConfig.CorruptionEventChance or 0) then
		local corruptionEvent = chooseFromList(eventConfig.CorruptionEvents)

		if corruptionEvent then
			return corruptionEvent
		end
	end

	return chooseFromList(events)
end

local function getEventPosition(event)
	if event.Position then
		return event.Position
	end

	if context.Services.MapService and context.Services.MapService.GetZonePosition then
		return context.Services.MapService.GetZonePosition(event.Zone)
	end

	return nil
end

local function playPositionalSound(event)
	local audioConfig = context.Config.Audio or {}
	local cues = audioConfig.PositionalCues or {}
	local cueName = event.AudioCue or event.EventType
	local soundConfig = cues[cueName]
	local position = getEventPosition(event)

	if audioConfig.Enabled == false or not soundConfig or not soundConfig.SoundId or soundConfig.SoundId == "" or not position then
		return
	end

	local soundPart = Instance.new("Part")
	soundPart.Name = "AtmosphereSound_" .. tostring(cueName)
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.CanQuery = false
	soundPart.CanTouch = false
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(1, 1, 1)
	soundPart.CFrame = CFrame.new(position)
	soundPart.Parent = context.Services.MapService.GetFolders().Root

	local sound = Instance.new("Sound")
	sound.Name = tostring(cueName)
	sound.SoundId = soundConfig.SoundId
	sound.Volume = (soundConfig.Volume or 0.35) * (audioConfig.MasterVolume or 1)
	sound.PlaybackSpeed = soundConfig.PlaybackSpeed or 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = soundConfig.RollOffMinDistance or 10
	sound.RollOffMaxDistance = soundConfig.RollOffMaxDistance or 80
	sound.Parent = soundPart
	sound:Play()

	Debris:AddItem(soundPart, soundConfig.Lifetime or 7)
end

local function flickerLights(duration, zone)
	local eventConfig = getEventConfig()
	local lightParts = context.Services.MapService.GetLightParts and context.Services.MapService.GetLightParts() or {}
	local originals = {}

	for _, lightPart in ipairs(lightParts) do
		if not zone or lightPart:GetAttribute("Zone") == zone or lightPart.Name == zone then
			local light = lightPart:FindFirstChildOfClass("PointLight")

			if light then
				originals[light] = light.Brightness
			end
		end
	end

	if next(originals) == nil then
		return
	end

	task.spawn(function()
		local endsAt = os.clock() + duration

		while os.clock() < endsAt do
			for light in pairs(originals) do
				light.Brightness = random:NextNumber(eventConfig.LightFlickerBrightnessMin or 0.05, eventConfig.LightFlickerBrightnessMax or 0.22)
			end

			task.wait(random:NextNumber(eventConfig.LightFlickerOffMin or 0.07, eventConfig.LightFlickerOffMax or 0.18))

			for light, brightness in pairs(originals) do
				light.Brightness = brightness
			end

			task.wait(random:NextNumber(eventConfig.LightFlickerOnMin or 0.08, eventConfig.LightFlickerOnMax or 0.2))
		end

		for light, brightness in pairs(originals) do
			light.Brightness = brightness
		end
	end)
end

local function triggerMapEffect(event)
	if not event then
		return
	end

	local eventConfig = getEventConfig()
	local originalBrightness = Lighting.Brightness
	local duration = eventConfig.BlackoutFlickerDuration or 1.2

	if event.EventType == "Blackout" then
		task.spawn(function()
			local endsAt = os.clock() + duration

			while os.clock() < endsAt do
				Lighting.Brightness = eventConfig.BlackoutBrightness or 0.12
				task.wait(eventConfig.BlackoutOffWait or 0.12)
				Lighting.Brightness = originalBrightness
				task.wait(eventConfig.BlackoutOnWait or 0.1)
			end

			Lighting.Brightness = originalBrightness
		end)
	elseif event.EventType == "LightFlicker" or event.EventType == "AlienPulse" then
		flickerLights(event.Duration or duration, event.Zone)
	elseif event.EventType == "CorruptionPulse" or event.EventType == "NestingRage" then
		flickerLights(event.Duration or duration, event.Zone)
		task.spawn(function()
			Lighting.Brightness = math.max(eventConfig.MinimumCorruptionBrightness or 0.08, originalBrightness - (event.BrightnessDrop or 0.25))
			task.wait(event.Duration or duration)
			Lighting.Brightness = originalBrightness
		end)
	end
end

local function broadcastEvent(event)
	if not event then
		return
	end

	local eventConfig = getEventConfig()

	context.Services.RemoteService.BroadcastMissionWarning({
		Text = event.Text,
		Severity = event.Severity or "MapPing",
		Zone = event.Zone,
		EventType = event.EventType or "Radio",
		AudioCue = event.AudioCue,
		ScreenPulse = event.Severity == "Panic" or event.Severity == "Emergency",
		ScreenPulseDuration = event.Severity == "Emergency"
			and (eventConfig.EmergencyScreenPulseDuration or 0.9)
			or (eventConfig.PanicScreenPulseDuration or 0.55)
	})
	playPositionalSound(event)
	triggerMapEffect(event)

	print("[MapEventService] Map event:", event.Zone or "Unknown", event.Text)
end

function MapEventService.TriggerAlarmPulse(reason)
	local wrongConfig = context.Config.WrongAccusation or {}
	local pulse = wrongConfig.AlarmPulse or {}

	if pulse.Enabled == false then
		return nil
	end

	local event = {
		Text = pulse.Text or "ALARM PULSE: containment field destabilized.",
		Severity = pulse.Severity or "Emergency",
		Zone = pulse.Zone or "FarmTown",
		EventType = pulse.EventType or "Alarm"
	}

	broadcastEvent(event)

	return {
		Reason = reason,
		Event = event
	}
end

function MapEventService.TriggerPanicPulse(reason)
	local eventConfig = getEventConfig()
	local panicEvents = eventConfig.PanicEvents or {}

	if #panicEvents == 0 then
		return nil
	end

	local event = panicEvents[random:NextInteger(1, #panicEvents)]
	broadcastEvent(event)

	return {
		Reason = reason,
		Event = event
	}
end

function MapEventService.TriggerNestingHint(reason)
	local eventConfig = getEventConfig()
	local hintEvents = eventConfig.NestingHintEvents or {}

	if #hintEvents == 0 then
		return nil
	end

	local event = hintEvents[random:NextInteger(1, #hintEvents)]
	broadcastEvent(event)

	return {
		Reason = reason,
		Event = event
	}
end

function MapEventService.TriggerNestingRagePulse(reason)
	local eventConfig = getEventConfig()
	local rageEvents = eventConfig.NestingRageEvents or {}

	if #rageEvents == 0 then
		return nil
	end

	local event = rageEvents[random:NextInteger(1, #rageEvents)]
	broadcastEvent(event)

	return {
		Reason = reason,
		Event = event
	}
end

function MapEventService.Init(sharedContext)
	context = sharedContext
	random = Random.new(context.Config.RandomSeed)
end

function MapEventService.Start()
	print("[MapEventService] Ready")

	if eventLoopRunning then
		return
	end

	eventLoopRunning = true

	task.spawn(function()
		while eventLoopRunning do
			waitForNextEvent()

			local eventConfig = getEventConfig()

			if eventConfig.Enabled and context.Round.State == "Active" then
				broadcastEvent(chooseEvent())
			end
		end
	end)
end

return MapEventService
