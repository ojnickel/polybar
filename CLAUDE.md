# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal polybar configuration for a Gentoo Linux + i3wm desktop. The repo is symlinked to `~/.config/polybar/` and contains bar definitions, module configs, custom scripts, and bundled third-party themes.

## Launching

```bash
# Kill existing bars and launch both bars (top + mybar):
~/.config/polybar/launch.sh
```

This starts two bars: `top` (centered title bar, override-redirect, floating) and `mybar` (bottom bar with system info, i3 workspaces, weather, clock, etc.).

## Architecture

- **`config.ini`** — Main config orchestrator. Defines both bars (`[bar/top]`, `[bar/mybar]`) and includes colors + modules via `include-file` directives.
- **`config-dark.ini`** — Dark color variant. Same bar layout, different `colors/colors-dark.ini`.
- **`config-hell.ini`** — Light color variant. Different bar colors + inline overrides for `network-ip` and `i3` modules.
- **`colors/`** — Color definitions, one file per variant:
  - `colors.ini` — Main palette
  - `colors-dark.ini` — Dark variant (darker transparencies)
  - `colors-hell.ini` — Light variant
- **`modules/`** — One file per polybar module (23 files). Each contains a single `[module/X]` section. Shared across all config variants via `include-file`.
- **`launch.sh`** — Startup script called from i3 config to (re)start polybar.
- **`scripts/`** — Custom shell/python scripts executed by `custom/script` modules:
  - `weather.sh` — OpenWeatherMap API (city: Munich)
  - `temp-colored.sh` — CPU temp with polybar `%{B}%{F}` formatting tags for colored backgrounds
  - `cpu-temp.sh` — Simple CPU temp via `sensors`
  - `network-ip.sh` — LAN/WiFi IP display (interfaces: `eno1`, `wlan0`)
  - `ip.sh` — One-liner IP via `ip route`
  - `dexcom.sh` / `dexcom_polybar.py` — Dexcom glucose monitor integration (uses Python venv at `/home/ossi/dexcom/`)
- **`polybar/`** — Bundled third-party polybar themes (blocks, colorblocks, cuts, docky, forest, etc.). Reference themes, not actively loaded.

## Adding/Editing Modules

To add a new module: create `modules/newmodule.ini` with a `[module/newmodule]` section, then add `include-file = ~/.config/polybar/modules/newmodule.ini` to the config files that need it. Add the module name to the appropriate `modules-left`, `modules-center`, or `modules-right` in the bar definition.

To edit an existing module: modify the file in `modules/` — changes apply to all config variants that include it. For variant-specific overrides, define the module inline in that config file instead of including the shared file (see `config-hell.ini` for examples).

## Key Conventions

- Fonts: Ubuntu Mono Bold Nerd Font (size 10), Symbols Nerd Font (size 10), Noto Sans Mono — icons come from Nerd Font glyphs
- Color format: `#AARRGGBB` where first two hex digits are transparency (`00` = fully transparent, `FF` = opaque)
- Module scripts output raw text or polybar formatting tags (`%{B#color}`, `%{F#color}`, `%{B-}`, `%{F-}`)
- Config uses polybar INI syntax with `${colors.name}` and `${self.property}` variable references
- Include paths use `~/.config/polybar/` prefix (resolved by polybar via the symlink)

## Credentials Warning

- `scripts/weather.sh` contains an OpenWeatherMap API key
- `scripts/dexcom_polybar.py` contains Dexcom account credentials
