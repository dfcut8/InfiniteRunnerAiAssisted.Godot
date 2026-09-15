extends Node2D
## Session orchestration; reusable children own simulation and presentation.
@onready var player: RunnerPlayer = $World/Player
@onready var course: RunnerCourse = $World/Course
@onready var effects: RunnerEffects = $World/Effects
@onready var hud: RunnerHUD = $HUD/Controls
@onready var camera: Camera2D = $World/Camera2D
var relic_count: int = 0
var broken: int = 0
var score: int = 0

func _ready() -> void:
	reset()

func reset(seed_value: int = -1) -> void:
	course.reset(seed_value)
	player.reset(course.settings.ground)
	player.visual.reset_animation()
	effects.clear()
	relic_count = 0
	broken = 0
	score = 0
	refresh_view()

func _physics_process(delta: float) -> void:
	step(delta)

func step(delta: float) -> void:
	effects.step(delta)
	player.step(delta, course)
	player.visual.advance_animation(delta, player)
	if not player.dead:
		course.ensure_ahead(player.x)
		_update_score()
	refresh_view()

func refresh_view() -> void:
	camera.position.x = floorf(player.x) + 80.0
	camera.force_update_scroll()
	$Backdrop/Background.update_scroll(floorf(player.x) - 80.0)
	player.visual.update_pose(player)
	hud.update_state(player, score, relic_count)

func _update_score() -> void:
	score = int(floor(player.x / 16.0 * 10.0)) + relic_count * 25 + broken * 100

func _on_relic_collected() -> void:
	relic_count += 1

func _on_stone_broken() -> void:
	broken += 1

func _on_retry_pressed() -> void:
	if player.dead:
		reset()
