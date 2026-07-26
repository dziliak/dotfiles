-- Hyprland Lua configuration migrated from the previous Hyprlang config.
-- Target: Hyprland 0.55+ Lua configuration API.

------------------
---- MONITORS ----
------------------

require("monitors")

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "footclient"
local file_manager = "thunar"
local browser = "firedragon"
local main_mod = "SUPER"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	-- Import the Hyprland environment into D-Bus and systemd user services.
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
	)
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
	hl.exec_cmd("systemctl --user start hyprland-session.target")

	-- Desktop services and applications.
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("wpaperd")
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("foot --server")
	hl.exec_cmd("xrdb -load ~/.Xresources")
	hl.exec_cmd("apply-gsettings")

	-- Clipboard history watchers.
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

----------------
---- CONFIG ----
----------------

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		numlock_by_default = true,
		follow_mouse = 1,
		sensitivity = 0.4,
	},

	decoration = {
		rounding = 10,
		blur = {
			enabled = true,
			size = 5,
			passes = 1,
		},
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		new_status = "master",
	},

	misc = {
		disable_hyprland_logo = true,
		-- vfr = true,
	},
})

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("myBezier", {
	type = "bezier",
	points = {
		{ 0.05, 0.9 },
		{ 0.1, 1.05 },
	},
})

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

------------------
---- GESTURES ----
------------------

hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd("garuda-rani")
	end,
})

hl.gesture({
	fingers = 3,
	direction = "down",
	action = function()
		hl.exec_cmd("nwg-drawer -mb 10 -mr 10 -ml 10 -mt 10")
	end,
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

-- General application and window bindings.
hl.bind(main_mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd("nwgbar"))
hl.bind(main_mod .. " + N", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(
	main_mod .. " + SUPER_L",
	hl.dsp.exec_cmd("pkill wofi || wofi --normal-window --show drun --allow-images"),
	{ release = true }
)
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + SHIFT + D", hl.dsp.exec_cmd("nwg-drawer -mb 10 -mr 10 -ml 10 -mt 10"))
hl.bind(main_mod .. " + B", hl.dsp.window.pseudo({ action = "toggle" }))
-- hl.bind(main_mod .. " + SHIFT + B", hl.dsp.layout("togglesplit"))

-- Main modifier + function keys.
local function_key_commands = {
	[1] = browser,
	[2] = "thunderbird",
	[3] = file_manager,
	[4] = "geany",
	[5] = "github-desktop",
	[6] = "gparted",
	[7] = "inkscape",
	[8] = "blender",
	[9] = "meld",
	[10] = "joplin-desktop",
	[11] = "snapper-tools",
	[12] = "galculator",
}

for key, command in pairs(function_key_commands) do
	hl.bind(main_mod .. " + F" .. key, hl.dsp.exec_cmd(command))
end

-- Move focus with the main modifier + arrow keys or Vim keys.
local focus_directions = {
	left = "l",
	H = "l",
	right = "r",
	L = "r",
	up = "u",
	K = "u",
	down = "d",
	J = "d",
}

for key, direction in pairs(focus_directions) do
	hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

-- Workspace switching and window movement.
for workspace = 1, 10 do
	local key = workspace % 10

	-- Switch to a workspace.
	hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))

	-- Move the active window and follow it.
	hl.bind(
		"ALT + SHIFT + " .. key,
		hl.dsp.window.move({
			workspace = workspace,
			follow = true,
		})
	)

	-- Move the active window silently.
	hl.bind(
		main_mod .. " + SHIFT + " .. key,
		hl.dsp.window.move({
			workspace = workspace,
			follow = false,
		})
	)
end

-- Scroll through existing workspaces.
hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move and resize windows with the mouse.
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Audio controls. These use keysyms instead of the old numeric XKB keycodes.
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd([[pamixer --decrease 5; notify-send "Volume: $(pamixer --get-volume)" -t 500]]),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd([[pamixer --increase 5; notify-send "Volume: $(pamixer --get-volume)" -t 500]]),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd([[pamixer --toggle-mute; notify-send "Volume: Toggle mute" -t 500]]),
	{ locked = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd([[pactl set-source-mute @DEFAULT_SOURCE@ toggle; notify-send "System Mic: Toggle mute" -t 500]]),
	{ locked = true }
)

-- Other bindings.
hl.bind(main_mod .. " + O", hl.dsp.exec_cmd(browser))
hl.bind(main_mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(
	main_mod .. " + SHIFT + F",
	hl.dsp.window.fullscreen_state({
		internal = 0,
		client = 2,
		action = "set",
	})
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl -c backlight set 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl -c backlight set +5%"),
	{ locked = true, repeating = true }
)
hl.bind(main_mod .. " + SHIFT + C", hl.dsp.exec_cmd("killall -9 wpaperd && wpaperd"))

-- Screenshots.
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_window.sh"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot_display.sh"))

-- Clipboard manager.
hl.bind(main_mod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Media playback.
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-------------------
---- RESIZE MAP ----
-------------------

hl.bind(main_mod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
	local repeating = { repeating = true }

	hl.bind("right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), repeating)
	hl.bind("L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), repeating)
	hl.bind("left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), repeating)
	hl.bind("H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), repeating)
	hl.bind("up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), repeating)
	hl.bind("K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), repeating)
	hl.bind("down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), repeating)
	hl.bind("J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), repeating)

	hl.bind("escape", hl.dsp.submap("reset"))
end)

----------------------
---- WINDOW MOVING ----
----------------------

local move_directions = {
	up = "u",
	K = "u",
	down = "d",
	J = "d",
	left = "l",
	H = "l",
	right = "r",
	L = "r",
}

for key, direction in pairs(move_directions) do
	hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
end

---------------------------
---- SPECIAL WORKSPACE ----
---------------------------

-- This preserves the five-dispatch sequence from the old config.
hl.bind(main_mod .. " + SHIFT + S", function()
	hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
	hl.dispatch(hl.dsp.window.move({ workspace = "+0", follow = true }))
	hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
	hl.dispatch(hl.dsp.window.move({ workspace = "special:magic", follow = true }))
	hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
end)

---------------------
---- LAYER RULES ----
---------------------

-- blurls applied only to layer-shell namespaces. Entries such as Thunar,
-- Gedit, and Catfish are normal windows, but are retained here harmlessly
-- in case a matching layer-shell namespace exists.
local blurred_layer_namespaces = {
	"wofi",
	"thunar",
	"gedit",
	"gtk-layer-shell",
	"catfish",
}

for _, namespace in ipairs(blurred_layer_namespaces) do
	hl.layer_rule({
		name = "blur-" .. namespace:gsub("[^%w]", "-"),
		match = { namespace = "^" .. namespace .. "$" },
		blur = true,
	})
end

-- Optional Waybar blur from the old commented configuration:
-- hl.layer_rule({
--     name = "blur-waybar",
--     match = { namespace = "^waybar$" },
--     blur = true,
--     ignore_alpha = 1,
-- })

----------------------
---- RULE EXAMPLES ----
----------------------

-- Modern Lua equivalents of some previously commented rules:
-- hl.window_rule({ match = { title = "^kitty$" }, float = true })
-- hl.window_rule({ match = { class = "^thunar$" }, active_opacity = 0.85, inactive_opacity = 0.85 })
-- hl.window_rule({ match = { class = "^gedit$" }, active_opacity = 0.85, inactive_opacity = 0.85 })
-- hl.window_rule({ match = { class = "^catfish$" }, active_opacity = 0.85, inactive_opacity = 0.85 })
-- hl.window_rule({ match = { class = "^wofi$" }, stay_focused = true })
