# Pixel Unicorn Runner

A complete silent endless runner for Godot 4.3+ (tested with 4.7.2). Open
`src/project.godot` and press **F6** with `game/runner.tscn` open, or **F5** after
reloading the project settings. Gameplay starts immediately.

* **Space / Z:** jump, then press again for one airborne recovery jump.
* Release jump early for a short hop.
* **Either Shift / X:** dash through ochre runestones. Masonry remains fatal.
* **R:** restart after death with a fresh course.

The game renders at 320 × 180, scales by whole integers, and centers with black
borders. Resize the window freely (minimum 320 × 180). There is no audio, menu,
persistence, or external asset dependency. All art and 5 × 7 glyphs are original
pixel drawings using the eight requested colors.

## Implementation

`src/game/runner.gd` owns the fixed 120 Hz movement, swept platform collisions,
input buffering, scoring and transient effects. `course.gd` streams and retires
course data. `pixel_art.gd` renders world layers and the HUD in one logical
viewport. The reusable entry scene is `runner.tscn`.

Terrain difficulty uses projected arrival time derived from the speed integral.
Platforms change height by at most eight pixels, and a full single jump clears
every generated transition with takeoff and landing margins. Obstacles remain
at least 206.4 pixels apart. All collections are retired behind the camera.

## Verification

Run with a Godot executable on PATH:

```powershell
godot --headless --path src --script res://tests/verify.gd
```

Checks exercise jump height, double-jump limits, coyote time, landing input
buffering, dash timing/velocity/cooldown, collision deaths, one-time rewards,
score freeze, full reset, and render-frame-rate independence. The terrain sweep
covers 20 seeds and 12 million pixels; an input-driven bot also attempts five
four-minute runs through the speed ramp using single jumps and dashes.

For actual rendered review and window transform diagnostics:

```powershell
godot --path src --script res://tests/capture.gd
```

This writes opening, jumping and death previews in the repository root.
