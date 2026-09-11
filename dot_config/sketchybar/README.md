# SketchyBar

Shell-based SketchyBar configuration with AeroSpace workspaces, calendar,
clock, volume scrolling, battery, CPU utilization, and network throughput.

## Configuration

- `settings.sh`: fonts, colors, workspace names, sampling intervals, volume
  step, and low-battery threshold.
- `sketchybarrc`: bar appearance, item layout, and event subscriptions.
- `plugins/`: item handlers; `common.sh` supplies settings and cache helpers.
- `helpers/cpu.c`: reads aggregate macOS CPU ticks. `cpu.sh` builds it with
  `xcrun clang` on first use or after the source changes.

Requires SketchyBar, AeroSpace, JetBrainsMono Nerd Font Mono, `jq`, and Xcode
or the Xcode Command Line Tools. Other commands ship with macOS.

CPU and network sample every three seconds by default; the clock keeps seconds.
The first CPU sample after startup/wake is `…` until a second sample is available.
Network rates use binary units (KiB/s, MiB/s, GiB/s) and track the default-route
interface, including VPN interfaces. Reconnects, changed interfaces, counter
resets, and long sampling gaps establish a new baseline.

Runtime state and the compiled CPU helper live in
`${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar`, outside the managed config.
They can be regenerated automatically.

Workspace appearance is refreshed by AeroSpace focus, workspace, window-create,
and move-binding hooks, plus SketchyBar window/display/wake events. A 30-second
fallback covers missed events, such as background window closures. Failed
AeroSpace queries preserve the last good display. When changing workspace names,
also update `~/.config/aerospace/aerospace.toml` (persistent names and bindings).

The calendar grid refreshes when opened, on a date change, and at bar reload.
Volume handles initialization, scrolling, and mute state in one script, with
a 30-second fallback for missed notifications. Battery icons distinguish active
charging, external power without charging, and discharge; low battery is red.

## Chezmoi workflow

To edit the source directly:

```sh
chezmoi edit ~/.config/sketchybar/settings.sh
chezmoi apply ~/.config/sketchybar
sketchybar --reload
```

After editing deployed files, capture only the changed paths, for example:

```sh
chezmoi add ~/.config/sketchybar/settings.sh ~/.config/sketchybar/sketchybarrc
chezmoi diff ~/.config/sketchybar ~/.config/aerospace/aerospace.toml
```

Capture AeroSpace changes with `chezmoi add ~/.config/aerospace/aerospace.toml`,
validate with `aerospace reload-config --dry-run --no-gui`, and activate with
`aerospace reload-config`. Source changes can then be reviewed and committed
in the chezmoi Git repository.
