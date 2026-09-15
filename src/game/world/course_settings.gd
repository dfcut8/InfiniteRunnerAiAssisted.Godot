class_name RunnerCourseSettings
extends Resource
## Generation data shared by the course scene; runtime state stays on its node.
@export var movement: RunnerMovementSettings
@export var ground: float = 132.0
@export var opening_left: float = -128.0
@export var opening_right: float = 384.0
@export var look_ahead: float = 720.0
@export var retire_distance: float = 180.0
@export var platform_lengths: Array[int] = [224, 256, 288]
@export var easy_seconds: float = 8.0
@export var height_change_seconds: float = 20.0
@export var easy_gap: float = 20.0
@export var minimum_gap: float = 24.0
@export var early_maximum_gap: float = 32.0
@export var late_maximum_gap: float = 56.0
@export var height_step: float = 8.0
@export var height_range: float = 16.0
@export var relic_height: float = 14.4
@export var relic_arch: Array[float] = [12.8, 28.0, 36.8, 28.0, 12.8]
@export var arch_probability: float = 0.5
@export var relic_start_offset: float = 20.0
@export var relic_spacing: float = 13.6
@export var opening_relic_start: float = 64.0
@export var opening_relic_spacing: float = 16.0
@export var stone_offset: float = 96.0
@export var stone_spacing: float = 206.4
@export var stone_probability: float = 0.85
