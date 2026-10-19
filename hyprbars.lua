-- macOS-style traffic-light title bars via the hyprbars plugin.
-- Does nothing until the plugin is installed:
--   hyprpm update
--   hyprpm add https://github.com/hyprwm/hyprland-plugins
--   hyprpm enable hyprbars
local M = {}

function M.register(opts)
  opts = opts or {}

  local function setup()
    -- Plugin not loaded (yet) -> skip, so we never produce "unknown config key" errors
    if not (hl.plugin and hl.plugin.hyprbars) then return end

    hl.config({
      plugin = {
        hyprbars = {
          enabled = true,
          bar_height = 28,
          bar_color = "rgba(2a2a2ce6)",
          bar_blur = not opts.software_rendering,
          bar_text_size = 11,
          bar_text_font = "Inter",
          bar_text_align = "center",
          bar_padding = 12,
          bar_button_padding = 8,
          bar_buttons_alignment = "left",
          bar_part_of_window = true,
          bar_precedence_over_border = true,
        },
      },
    })

    -- Traffic lights: close (red), minimize (yellow), zoom (green)
    hl.plugin.hyprbars.add_button({
      bg_color = "rgb(ff5f57)", fg_color = "rgb(4d0000)", size = 12, icon = " ",
      action = "hyprctl dispatch 'hl.dsp.window.close()'",
    })
    hl.plugin.hyprbars.add_button({
      bg_color = "rgb(febc2e)", fg_color = "rgb(5a3d00)", size = 12, icon = " ",
      action = "hyprctl dispatch 'hl.dsp.window.move({ workspace = \"special:minimized\" })'",
    })
    hl.plugin.hyprbars.add_button({
      bg_color = "rgb(28c840)", fg_color = "rgb(003d00)", size = 12, icon = " ",
      action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    })
  end

  -- Plugins load after the config is first read, so apply again once they are in
  hl.on("config.reloaded", setup)
  hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload -n && sleep 1 && hyprctl reload")
  end)
  setup()
end

return M
