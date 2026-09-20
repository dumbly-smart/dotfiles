-- Hyprland 0.56 Lua configuration migrated from ~/.config/hypr/hyprland.conf.
-- Ax-Shell still generates its palette as Hyprlang variables, so read those
-- values as data without asking Hyprland to parse any legacy configuration.

local home = os.getenv("HOME") or "/home/xtrmn8"
local axConfig = home .. "/.config/Ax-Shell/config/hypr"

local function readAxColors()
    local values = {}
    local file = io.open(axConfig .. "/colors.conf", "r")
    if not file then
        return values
    end

    for line in file:lines() do
        local key, value = line:match("^%$(%w+)%s*=%s*(.-)%s*$")
        if key then
            values[key] = value
        end
    end
    file:close()
    return values
end

local ax = readAxColors()
local wallpaper = ax.wallpaper or (axConfig .. "/../../assets/wallpapers_example/artist-starkiteckt-azure-gem-4k.png")
local primary = ax.primary or "96ccf8"
local surface = ax.surface or "101417"

local terminal = "alacritty"
local fileManager = "dolphin"
local browser = "firefox"
local mainMod = "SUPER"

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Legacy exec-once entries: run only when the compositor starts.
hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/battery-saver session")
    hl.exec_cmd("uwsm-app -- python " .. home .. "/.config/Ax-Shell/main.py")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- Legacy exec entries: run whenever the configuration is loaded.
hl.exec_cmd('pgrep -x "hypridle" > /dev/null || uwsm app -- hypridle')
hl.exec_cmd("systemctl --user start awww.service")
hl.exec_cmd("ln -sfn " .. string.format("%q", wallpaper) .. " " .. string.format("%q", home .. "/.current.wall"))

hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 0,
        col = {
            active_border = "rgb(" .. primary .. ")",
            inactive_border = "rgb(" .. surface .. ")",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    cursor = {
        no_warps = true,
    },
    decoration = {
        rounding = 0,
        blur = {
            enabled = true,
            size = 1,
            passes = 3,
            new_optimizations = true,
            contrast = 1,
            brightness = 1,
        },
        shadow = {
            enabled = true,
            range = 10,
            render_power = 2,
            color = 0x40000000,
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
        orientation = "center",
        mfact = 0.6,
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

-- Ax-Shell animation overrides. Ordering matches the previous sourced config.
hl.curve("myBezier", { type = "bezier", points = { {0.4, 0.0}, {0.2, 1.0} } })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 2.5, bezier = "myBezier" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "myBezier", style = "slidefade 20%" })

local function bind(keys, dispatcher, options)
    hl.bind(keys, dispatcher, options)
end

bind(mainMod .. " + Z", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + X", hl.dsp.window.close({}))
bind(mainMod .. " + M", hl.dsp.exit())
bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
bind(mainMod .. " + V", hl.dsp.window.float({ action = "off" }))
bind(mainMod .. " + P", hl.dsp.window.pseudo())
bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(browser .. " --private-window"))
bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd(home .. "/.local/bin/hypr-smart-fullscreen"))
bind(mainMod .. " + ALT + equal", hl.dsp.exec_cmd([[hyprctl keyword monitor ",preferred,auto,1"]]))
bind(mainMod .. " + ALT + minus", hl.dsp.exec_cmd([[hyprctl keyword monitor ",preferred,auto,1.6"]]))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    local short = ({ left = "l", right = "r", up = "u", down = "d" })[direction]
    bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = short }))
    bind(mainMod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = short }))
end

bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + SHIFT + left", hl.dsp.window.move({ x = -40, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ x = 40, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + SHIFT + up", hl.dsp.window.move({ x = 0, y = -40, relative = true }), { repeating = true })
bind(mainMod .. " + CTRL + SHIFT + down", hl.dsp.window.move({ x = 0, y = 40, relative = true }), { repeating = true })

bind(mainMod .. " + SPACE", hl.dsp.window.float())
bind(mainMod .. " + CTRL + C", hl.dsp.window.center({}))
bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + CTRL + SPACE", hl.dsp.window.pin())

for workspace = 1, 10 do
    local key = workspace % 10
    bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
end

bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ workspace = "r-1", follow = true }))
bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ workspace = "r+1", follow = true }))
bind(mainMod .. " + CTRL + up", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
bind(mainMod .. " + CTRL + down", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })
bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd(home .. "/.local/bin/battery-saver on"))
bind(mainMod .. " + CTRL + SHIFT + P", hl.dsp.exec_cmd(home .. "/.local/bin/battery-saver off"))
bind(mainMod .. " + G", hl.dsp.exec_cmd(home .. "/.config/Ax-Shell/scripts/gamemode.sh toggle"))
bind(mainMod .. " + F1", hl.dsp.exec_cmd(home .. "/.local/bin/hypr-keybinds"))
bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd([[kitty --title "Remote Access Dashboard" ~/.local/bin/remote-access-dashboard]]))
bind(mainMod .. " + W", hl.dsp.exec_cmd(home .. "/.local/bin/hypr-three-column-cycle"))
bind(mainMod .. " + Q", hl.dsp.exec_cmd(home .. "/.local/bin/hypr-quarter-cycle"))
bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { repeating = true, locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { repeating = true, locked = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Ax-Shell regenerates its shortcut file from its settings UI. Translate only
-- those generated exec binds into native Lua binds so customization still works.
local function loadAxBinds()
    local variables = {
        fabricSend = "fabric-cli exec ax-shell",
        axMessage = [=[notify-send "Axenide" "FIRE IN THE HOLE‼️🗣️🔥🕳️" -i "/home/xtrmn8/.config/Ax-Shell/assets/ax.png" -A "🗣️" -A "🔥" -A "🕳️" -a "Source Code"]=],
    }
    local lines = {}
    local file = io.open(axConfig .. "/ax-shell.conf", "r")
    if not file then
        return
    end

    for line in file:lines() do
        lines[#lines + 1] = line
        local name, value = line:match("^%$(%w+)%s*=%s*(.-)%s*$")
        if name then
            variables[name] = value
        end
    end
    file:close()

    for _, line in ipairs(lines) do
        local modifiers, key, command = line:match("^%s*bind%s*=%s*(.-)%s*,%s*(.-)%s*,%s*exec%s*,%s*(.-)%s*$")
        if modifiers and key and command then
            modifiers = modifiers:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " + ")
            key = key:gsub("^%s+", ""):gsub("%s+$", "")
        command = command:gsub("%s+#.*$", "")
        command = command:gsub("%$fabricSend", function() return variables.fabricSend end)
        command = command:gsub("%$axMessage", function() return variables.axMessage end)
            -- The native source handles this binding.  Passing the quoted
            -- fabric-cli command through the Lua dispatcher produces malformed
            -- Lua on Hyprland 0.56 and prevents the launcher from opening.
            if not (modifiers == "SUPER" and key == "R") then
                bind((modifiers ~= "" and (modifiers .. " + ") or "") .. key, hl.dsp.exec_cmd(command))
            end
        end
    end
end

loadAxBinds()

-- Keep the launcher binding explicit.  The generated Ax-Shell command is
-- parsed through this Lua file, while the Hyprlang source is not active in
-- this configuration mode.
bind("SUPER + R", hl.dsp.exec_cmd("fabric-cli exec ax-shell 'notch.open_notch(\"launcher\")'"))

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        xwayland = true,
        float = true,
        class = "^$",
        title = "^$",
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
