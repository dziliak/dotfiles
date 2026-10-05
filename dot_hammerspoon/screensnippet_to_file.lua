local M = {}

local screenshotFolder = os.getenv("HOME") .. "/Documents/Obsidian/obsidian_vault/attachments"

function M.snippet()
	hs.fs.mkdir(screenshotFolder)

	local defaultName = "Screenshot_" .. os.date("%Y-%m-%d_%H-%M-%S")

	local button, filename = hs.dialog.textPrompt("Save Screenshot", "Enter a filename:", defaultName, "Save", "Cancel")

	if button ~= "Save" or filename == "" then
		return
	end

	-- Prevent .png.png
	filename = filename:gsub("%.png$", "")

	-- Don't allow slashes in filenames
	filename = filename:gsub("/", "-")

	local filepath = screenshotFolder .. "/" .. filename .. ".png"

	local task = hs.task.new("/usr/sbin/screencapture", function(exitCode, stdOut, stdErr)
		if exitCode == 0 and hs.fs.attributes(filepath) then
			hs.notify
				.new({
					title = "Screenshot Saved",
					informativeText = filename .. ".png",
				})
				:send()
		end
	end, {
		"-i",
		"-x",
		"-t",
		"png",
		filepath,
	})

	task:start()
end

return M
