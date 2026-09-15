class_name RunnerPlayerVisual
extends AnimatedSprite2D

const SPRITE_ORIGIN := Vector2(-24.0, -32.0)
const RUN_FRAME_COUNT := 8
const RUN_FPS := 12.0
# These source frames shift the whole torso/head down one pixel.
const RUN_Y_OFFSETS: Array[float] = [0.0, -1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0]

var _run_phase := 0.0

func reset_animation() -> void:
	_run_phase = 0.0

func advance_animation(delta: float, player: RunnerPlayer) -> void:
	if player.dead or not player.grounded or player.dash_left > 0.0:
		return
	# Integrate the current rate: elapsed * current speed also accelerates all
	# past animation time, causing an overly fast cadence and a hitch at the cap.
	_run_phase = fposmod(_run_phase + delta * RUN_FPS * player.speed / player.settings.initial_speed, RUN_FRAME_COUNT)

func update_pose(player: RunnerPlayer) -> void:
	visible = not player.dead or player.death_time < 0.65
	var pose := int(_run_phase)
	if not player.grounded:
		pose = 8 if player.vy < 0.0 else 9
	if player.dash_left > 0.0:
		pose = 10
	if player.dead:
		pose = 11
	frame = pose
	offset = Vector2(0.0, RUN_Y_OFFSETS[pose] if pose < RUN_FRAME_COUNT else 0.0)
	# Match the camera's floor operation before rendering. Independent rounding
	# of a fractional player transform can otherwise move it a pixel sideways.
	global_position = player.global_position.floor() + SPRITE_ORIGIN
