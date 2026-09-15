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
persistence, or third-party asset dependency. Original pixel art and 5 × 7 glyphs
are stored in `src/assets` as PNG textures and a bitmap font.

## Implementation

Open `src/game/runner.tscn` to edit the composed game:

```text
PixelUnicornRunner               session, score, reset, fixed 120 Hz tick
├── Backdrop/Background          repeated texture strips on a stationary canvas
├── World
│   ├── Course                   instances and retires terrain/entity scenes
│   ├── Effects                  particle and dash-ghost scene instances
│   ├── Player                   movement and jump/dash state
│   │   ├── Visual               AnimatedSprite2D with external SpriteFrames
│   │   ├── Hitbox               Inspector-editable RectangleShape2D
│   │   └── CollisionResolver    swept collision rules
│   └── Camera2D
├── HUD/Controls                 Control nodes, Labels, Panels, ProgressBar
└── Input                        Input Map actions, connected through signals
```

### Editing the game

| Change | Scene or resource under `src/game` |
| --- | --- |
| Player silhouette, frames, hitbox | `player/player.tscn`, `player/unicorn_frames.tres` |
| Jump, gravity, speed ramp, dash | `player/movement.tres` |
| Course lengths, gaps, heights, pickup/obstacle placement | `world/course_settings.tres` |
| Terrain art and collision shape | `world/platform.tscn` |
| Pickup and obstacle art/hitboxes | `world/relic.tscn`, `world/runestone.tscn` |
| Background layout and scrolling | `world/background.tscn` |
| Particle textures and lifetimes | `effects/gold.tscn`, `effects/ivory.tscn`, `effects/ghost.tscn` |
| HUD layout, typography, colors | `ui/hud.tscn`, `ui/theme.tres` |

The course and player share the movement resource so projected arrival times
follow the configured speed ramp. Course generation still runs in code because
the world is endless; it instantiates authored PackedScenes instead of creating
node trees or drawing shapes. PNGs are the editable art sources; no runtime art
generator is required. Terrain uses authored texture variants for its standard
widths and repeats a texture for custom widths.

The unicorn visual registers the running frames to a shared head/torso anchor
with pixel offsets, preserving the original PNGs and nearest-neighbor style.
Its run clock advances at 12 fps scaled by current speed, pauses during airborne
and dash poses, and resets on retry. The sprite uses the camera's pixel-floor
alignment so fractional world movement does not produce sideways shimmer.

Entity roots are Area2D nodes with authored collision shapes. Monitoring is
disabled because the collision component explicitly tests those bounds each
fixed tick, including swept front faces. This preserves dash timing, coyote time,
and masonry collision behavior. Movement doesn't use `move_and_slide()`.
Platform shapes are local to each scene instance so resizing one platform
doesn't resize every platform. Signals connect input, rewards, death and effects
in the main scene. Runtime state belongs to nodes; shared resources are read-only.

If the editor was already open during the refactor, restart it once to reload
the new Jump/Dash/Retry Input Map actions from `project.godot`.

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
Scene checks also cover input signal wiring, shared movement configuration,
independent platform shapes, deterministic generation, node cleanup, and HUD
state after death/retry. Tests instantiate the actual game and course scenes.

For actual rendered review and window transform diagnostics:

```powershell
godot --path src --script res://tests/capture.gd
```

This writes opening, jumping, dashing and death previews in the repository root,
plus `preview-run-cycle.png` showing all eight run poses and the loop seam.
