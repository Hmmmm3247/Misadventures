local MapEventService = {}

local context
local eventLoopRunning = false
local random

local function getEventConfig()
	return context.Config.MapEvents or {}
end

local function waitForNextEvent()
	local eventConfig = getEventConfig()
	local minInterval = eventConfig.MinInterval or 28
	local maxInterval = eventConfig.MaxInterval or 46

	task.wait(random:NextNumber(minInterval, maxInterval))
end

local function chooseEvent()
	local eventConfig = getEventConfig()
	local events = eventConfig.Events or {}

	if #events == 0 then
		return nil
	end

	return events[random:NextInteger(1, #events)]
end

local function broadcastEvent(event)
	if not event then
		return
	end

	context.Services.RemoteService.BroadcastMissionWarning({
		Text = event.Text,
		Severity = event.Severity or "MapPing",
		Zone = event.Zone,
		EventType = event.EventType or "Radio"
	})

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
