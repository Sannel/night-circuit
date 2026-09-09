-- Night Circuit 2076 screensaver: float it fullscreen so it never grabs a
-- tiling slot and always covers the monitor. Append to hyprland.lua.
o.window({ class = "^chrome-127.0.0.1__-Default$" }, {
  fullscreen = true,
})
