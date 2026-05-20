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
