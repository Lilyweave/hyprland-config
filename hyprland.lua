-- ───────────── macOS-style Hyprland (Lua config, Hyprland 0.55+) ─────────────
-- Save as ~/.config/hypr/hyprland.lua
-- Needs: waybar rofi nwg-dock-hyprland swaync swaybg grim slurp wl-clipboard
--        cliphist brightnessctl playerctl wlogout kitty nautilus polkit-gnome hyprlock
-- Theme: whitesur-gtk-theme whitesur-icon-theme whitesur-cursor-theme inter-font

---------------------
---- YOUR OPTIONS ----
---------------------
-- true in VMs / no GPU acceleration: turns off blur, shadows and hardware cursors
local software_rendering = true

local home        = os.getenv("HOME")
local wallpaper   = home .. "/Pictures/wallpaper.jpg"
local terminal    = "kitty"
local fileManager = "nautilus"
local launcher    = "rofi -show drun -theme ~/.config/rofi/spotlight.rasi"
local shots       = home .. "/Pictures/Screenshots"
local mainMod     = "SUPER" -- acts as Command (⌘)

-- Runs a block that might not match your exact Hyprland version without
-- aborting the rest of the file if it fails.
local function try(name, fn)
  local ok, err = pcall(fn)
  if not ok then
    print("[macos-config] skipped '" .. name .. "': " .. tostring(err))
  end
end

------------------
---- MONITORS ----
------------------
hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = "auto",
})

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
  hl.exec_cmd("mkdir -p '" .. shots .. "'")
  hl.exec_cmd("waybar")
  hl.exec_cmd("nwg-dock-hyprland -d -i 52 -mb 10")
  hl.exec_cmd("swaync")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("wl-paste --watch cliphist store")

  -- GTK theme / icons / cursor / font
  hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Inter 11'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

  -- Wallpaper (swaybg works in VMs; hyprpaper needs GPU buffers)
  local f = io.open(wallpaper, "r")
  if f then
    f:close()
    hl.exec_cmd("swaybg -i '" .. wallpaper .. "' -m fill")
  end
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "WhiteSur-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "WhiteSur-cursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "WhiteSur-Dark")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
  general = {
    gaps_in  = 6,
    gaps_out = 12,
    border_size = 1,
    col = {
      active_border   = "rgba(ffffff40)",
      inactive_border = "rgba(ffffff14)",
    },
    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 12,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = not software_rendering,
      range = 40,
      render_power = 3,
      color = 0x66000000,
    },
    blur = {
      enabled = not software_rendering,
      size = 10,
      passes = 3,
      vibrancy = 0.25,
    },
  },

  animations = { enabled = true },

  dwindle = { preserve_split = true },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },

  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = { natural_scroll = true },
  },
})

-- Extras: each in its own try() so one wrong option name can't break the rest
try("blur extras", function()
  hl.config({ decoration = { blur = { noise = 0.02, contrast = 1.0, brightness = 1.0 } } })
end)
try("shadow inactive", function()
  hl.config({ decoration = { shadow = { color_inactive = 0x33000000 } } })
end)
try("dwindle pseudotile", function()
  hl.config({ dwindle = { pseudotile = true } })
end)
try("touchpad", function()
  hl.config({ input = { touchpad = {
    scroll_factor = 0.4,
    tap_to_click = true,
    clickfinger_behavior = true,
    disable_while_typing = true,
  } } })
end)
if software_rendering then
  try("software cursor", function()
    hl.config({ cursor = { no_hardware_cursors = true } })
  end)
end

-- Animations: soft overshoot "spring" feel
hl.curve("ease",      { type = "bezier", points = { {0.25, 0.10}, {0.25, 1.00} } })
hl.curve("overshoot", { type = "bezier", points = { {0.34, 1.30}, {0.64, 1.00} } })

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 5, bezier = "overshoot", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "ease",      style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "ease" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "border",     enabled = true, speed = 6, bezier = "ease" })
hl.animation({ leaf = "layers",     enabled = true, speed = 5, bezier = "ease", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "ease", style = "slide" })

-- 3-finger swipe between workspaces ("Spaces")
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Blur behind bar / dock / launcher / notifications
if not software_rendering then
  try("layer blur", function()
    for _, ns in ipairs({ "waybar", "rofi", "nwg-dock", "swaync-control-center", "swaync-notification-window" }) do
      hl.layer_rule({
        name  = "blur-" .. ns,
        match = { namespace = "^(" .. ns .. ")$" },
        blur  = true,
      })
    end
  end)
end

---------------------
---- KEYBINDINGS ----
---------------------
-- Apps
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(launcher))                       -- Spotlight
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))                    -- Finder
hl.bind(mainMod .. " + TAB",    hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/spotlight.rasi")) -- App switcher
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("cliphist list | rofi -dmenu -theme ~/.config/rofi/spotlight.rasi | cliphist decode | wl-copy"))

-- Windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close())                                -- Quit app
hl.bind(mainMod .. " + W", hl.dsp.window.close())                                -- Close window
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M",          hl.dsp.window.move({ workspace = "special:minimized" }))  -- Minimize
hl.bind(mainMod .. " + SHIFT + M",  hl.dsp.workspace.toggle_special("minimized"))             -- Show minimized
hl.bind(mainMod .. " + CTRL + Q",   hl.dsp.exec_cmd("hyprlock"))                              -- Lock screen
hl.bind(mainMod .. " + SHIFT + Q",  hl.dsp.exit())                                            -- Log out

try("fullscreen bind", function()
  hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen())
end)

-- Screenshots (⌘⇧3 / ⌘⇧4 / ⌘⇧5)
local stamp = "$(date +'%Y-%m-%d_%H-%M-%S')"
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd("grim - | tee '" .. shots .. "/" .. stamp .. ".png' | wl-copy"))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | tee '" .. shots .. "/" .. stamp .. ".png' | wl-copy"))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Spaces: Ctrl+arrows, Ctrl+number (Shift to send the window)
hl.bind("CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
for i = 1, 9 do
  hl.bind("CTRL + " .. i,           hl.dsp.focus({ workspace = i }))
  hl.bind("CTRL + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end

-- Mouse: ⌘+drag to move, ⌘+right-drag to resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- Optional: float every window like macOS (very different from tiling)
-- hl.window_rule({ name = "float-everything", match = { class = ".*" }, float = true })
