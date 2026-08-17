hs.ipc.cliInstall()

local hyper = { "cmd", "alt", "ctrl" }

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "E", function()
	hs.alert.show("Hello World!")
end)

hs.hotkey.bind(hyper, "W", function()
	local button, text = hs.dialog.textPrompt("Open WebReq", "Enter WebReq number:", "", "Open", "Cancel")

	if button ~= "Open" then
		return
	end

	local number = tonumber(text)

	if number == nil then
		hs.alert.show("Invalid number: " .. text)
		return
	end

	local script = "/Users/dziliak/.scripts/webreq"
	local cmd = string.format("%q %d", script, number)

	local output, status, _, rc = hs.execute(cmd, true)

	if status then
		hs.alert.show("Opened WebReq " .. number)
	else
		hs.alert.show("webreq.sh failed: " .. tostring(rc))
		print(output)
	end
end)

hs.hotkey.bind({ "cmd", "alt" }, "b", function()
	hs.task.new("/Users/dziliak/.scripts/screensnip", nil):start()
end)

hs.hotkey.bind({ "cmd", "alt" }, "g", function()
	hs.task.new("/Users/dziliak/.scripts/ocr_snippet", nil):start()
end)

local targetVolumePath = "/Volumes/Work_Backup"
local scriptToRun = os.getenv("HOME") .. "/.scripts/on-nvme-mounted.sh"

local function runScript()
	hs.task
		.new("/bin/zsh", nil, {
			"-lc",
			"source ~/.zshrc; " .. string.format("%q", scriptToRun),
		})
		:start()
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "Y", function()
	hs.task
		.new("/bin/zsh", nil, {
			"-lc",
			"source ~/.zshrc; " .. string.format("%q", scriptToRun),
		})
		:start()
end)

local volumeWatcher = hs.fs.volume.new(function(eventType, info)
	print("volume event:", eventType, hs.inspect(info))

	if eventType ~= hs.fs.volume.didMount then
		return
	end
	if info.path ~= targetVolumePath then
		return
	end

	hs.notify
		.new({
			title = "NVMe mounted",
			informativeText = info.path,
		})
		:send()

	runScript()

	hs.notify
		.new({
			title = "NVMe backup complete and unmounted NVMe drive.",
			informativeText = info.path,
		})
		:send()

	print("completed nvme script")
end)

-- volumeWatcher:start()

-- Focus follows mouse
focusFollowsMouse = {}

local ffm = focusFollowsMouse

ffm.delay = 0
ffm.pendingWindowID = nil
ffm.focusTimer = nil

local function windowUnderMouse()
	local mousePos = hs.geometry(hs.mouse.absolutePosition())

	-- orderedWindows() returns visible windows front-to-back
	for _, win in ipairs(hs.window.orderedWindows()) do
		if win:isStandard() then
			local frame = win:frame()

			if mousePos:inside(frame) then
				return win
			end
		end
	end

	return nil
end

local function updateFocus()
	local targetWindow = windowUnderMouse()
	local targetID = targetWindow and targetWindow:id() or nil

	local focusedWindow = hs.window.focusedWindow()
	local focusedID = focusedWindow and focusedWindow:id() or nil

	-- Already focused
	if targetID == focusedID then
		ffm.pendingWindowID = nil

		if ffm.focusTimer then
			ffm.focusTimer:stop()
			ffm.focusTimer = nil
		end

		return
	end

	-- We're already waiting to focus this window.
	-- Don't restart the timer for every mouseMoved event.
	if targetID == ffm.pendingWindowID then
		return
	end

	ffm.pendingWindowID = targetID

	if ffm.focusTimer then
		ffm.focusTimer:stop()
		ffm.focusTimer = nil
	end

	if not targetID then
		return
	end

	ffm.focusTimer = hs.timer.doAfter(ffm.delay, function()
		-- Make sure the pointer is still over the same window
		local currentWindow = windowUnderMouse()
		local currentID = currentWindow and currentWindow:id() or nil

		if currentID == targetID then
			currentWindow:focus()
		end

		ffm.pendingWindowID = nil
		ffm.focusTimer = nil
	end)
end

ffm.mouseWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
	updateFocus()
	return false
end)

ffm.mouseWatcher:start()
