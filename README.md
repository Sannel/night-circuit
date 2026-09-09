# Night Circuit 2076 — a WebGL cyberpunk motorcycle-chase screensaver for Omarchy.
#
# Three acts on a loop: high-altitude mega-city cruise, a dive between the
# towers down to street level, then a rainy neon chase where the bike weaves
# through traffic it dodges on its own. Any key, click, or mouse flick exits.

## Run it

```sh
./neon-racer-run.sh force   # preview right now (any input exits)
```

`SUPER + SHIFT + S` previews it too once the Omarchy wiring below is in place.
Idle auto-launch takes over after a session restart (see wiring).

## How it works

- `night-circuit.html` — the whole show: three.js scene (vendored, offline),
  canvas `captureStream` mirrored through a `<video>` overlay, `/exit` wiring.
- `server.py` — tiny localhost static server (also serves `vendor/`).
  Usage: `python3 server.py <document-root> <port>`.
- `neon-racer-run.sh` — launches the server plus a fullscreen
  `chromium --app` window, tears everything down on exit.
- `vendor/three.module.js` — three.js r160, vendored so it runs offline
  (© three.js authors, MIT).

## Omarchy wiring (`omarchy/`)

Copy into place (paths are `$HOME`-relative):

| Repo file | Install target |
|---|---|
| `omarchy/bin/omarchy-launch-screensaver` | `~/.local/bin/` (idle auto-launch override) |
| `omarchy/bin/omarchy-screensaver` | `~/.local/bin/` (preview entry point) |
| `omarchy/config/90-screensaver-path` | `~/.config/uwsm/env.d/` (needs session restart) |
| `omarchy/config/hyprland-rule.lua` | append to `~/.config/hypr/hyprland.lua` |
| `omarchy/config/bindings-snippet.lua` | append to `~/.config/hypr/bindings.lua` |

Requires: `chromium`, Hyprland with Lua config, hardware WebGL
(Intel/AMD iGPU is plenty; software GL does not present reliably).
