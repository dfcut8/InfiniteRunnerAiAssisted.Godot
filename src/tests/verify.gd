extends SceneTree
const Runner = preload("res://game/runner.gd")
const Course = preload("res://game/course.gd")
const DT := 1.0 / 120.0
var failures := 0
var checks := 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func ticks(count: int) -> void:
	for i in range(count):
		game.step(DT)

func jump() -> void:
	game.jump_held = true
	game.buffer = 0.12
	game.step(DT)

func runway() -> void:
	game.reset(42)
	game.course.platforms.assign([{"x": -100.0, "end": 10000.0, "y": 132.0}])
	game.course.stones.clear()
	game.course.relics.clear()

func run() -> void:
	game = Runner.new()
	root.add_child(game)
	game.set_physics_process(false)
	runway()
	jump()
	var held_peak: float = game.y
	for i in range(45):
		game.step(DT)
		held_peak = minf(held_peak, game.y)
	runway()
	jump()
	game.cut_jump()
	var tap_peak: float = game.y
	for i in range(45):
		game.step(DT)
		tap_peak = minf(tap_peak, game.y)
	check(tap_peak - held_peak > 14.0, "Held jumps must be substantially higher than taps")
	runway()
	jump()
	ticks(8)
	jump()
	check(game.jumps == 0 and game.vy < -130.0, "Second press resets ascent and consumes recovery")
	ticks(2)
	var before: float = game.vy
	jump()
	check(game.vy > before and game.jumps == 0, "Third airborne press cannot jump")
	ticks(100)
	check(game.grounded and game.jumps == 2, "Landing restores both jumps")
	runway()
	game.course.platforms[0].end = 0.0
	game.course.platforms.append({"x": 1000.0, "end": 10000.0, "y": 132.0})
	game.x = 10.0
	ticks(5)
	jump()
	check(game.jumps == 1 and game.vy < 0.0, "Coyote jump preserves recovery")
	runway()
	game.course.platforms[0].end = 0.0
	game.course.platforms.append({"x": 1000.0, "end": 10000.0, "y": 132.0})
	game.x = 10.0
	ticks(15)
	check(game.jumps == 1, "Walking off consumes ground jump after grace")
	jump()
	check(game.jumps == 0, "Walk-off permits only one recovery")
	runway()
	game.y = 125.0
	game.vy = 50.0
	game.grounded = false
	game.jumps = 0
	game.buffer = 0.12
	game.jump_held = true
	ticks(13)
	check(game.vy < 0.0 and game.jumps == 1, "Buffered input jumps on landing")
	runway()
	jump()
	var suspended_y: float = game.y
	var suspended_vy: float = game.vy
	game.start_dash()
	ticks(24)
	check(is_equal_approx(game.y, suspended_y), "Dash suspends vertical travel for 0.20 seconds")
	check(game.dash_left == 0.0 and is_equal_approx(game.cooldown, 0.7), "Cooldown starts after dash ends")
	check(is_equal_approx(game.vy, suspended_vy) and game.jumps == 1, "Dash resumes velocity without granting jumps")
	game.start_dash()
	check(game.dash_left == 0.0, "Dash cannot restart during cooldown")
	ticks(83)
	check(game.cooldown > 0.0, "Landing does not bypass dash cooldown")
	ticks(1)
	game.start_dash()
	check(game.dash_left > 0.0, "Dash recharges after exactly 0.70 seconds")
	runway()
	game.course.stones.assign([{"x": 12.0, "y": 132.0}])
	ticks(1)
	check(game.dead, "Undashed runestone contact is fatal")
	var frozen_score: int = game.score
	var frozen_x: float = game.x
	ticks(100)
	check(game.score == frozen_score and game.x == frozen_x, "Death freezes movement and scoring")
	runway()
	game.course.stones.assign([{"x": 12.0, "y": 132.0}])
	game.start_dash()
	ticks(1)
	check(not game.dead and game.broken == 1, "Active dash breaks runestones")
	ticks(20)
	check(game.broken == 1 and game.course.stones.is_empty(), "Runestones award only once")
	runway()
	game.course.relics.assign([{"x": 2.0, "y": 118.0}])
	ticks(2)
	check(game.relic_count == 1 and game.score == int(floor(game.x / 16.0 * 10.0)) + 25, "Relic scores 25 once plus distance")
	for dash in [false, true]:
		runway()
		game.course.platforms.assign([{"x": 12.0, "end": 900.0, "y": 124.0}])
		if dash:
			game.start_dash()
		ticks(8)
		check(game.dead, "Platform front is fatal, including during dash")
	runway()
	game.y = 229.0
	ticks(1)
	check(game.dead, "Falling six units ends the run")
	game.reset(43)
	check(game.x == 0.0 and game.score == 0 and game.relic_count == 0 and game.broken == 0 and game.speed == 80.0 and game.jumps == 2 and game.dash_left == 0.0 and game.cooldown == 0.0 and not game.dead and game.effects.is_empty() and game.ghosts.is_empty(), "Retry resets all state")
	var arrangement: String = str(game.course.platforms)
	game.reset(44)
	check(str(game.course.platforms) != arrangement, "Different seeds produce fresh courses")
	verify_course()
	verify_long_runs()
	# Same fixed physics simulation with 30/60/144 Hz presentation schedules.
	var distances: Array[float] = []
	for fps in [30, 60, 144]:
		runway()
		var accumulator := 0.0
		for frame in range(fps * 3):
			accumulator += 1.0 / float(fps)
			while accumulator + 0.0000001 >= DT:
				game.step(DT)
				accumulator -= DT
		distances.append(game.x)
	check(is_equal_approx(distances[0], distances[1]) and is_equal_approx(distances[1], distances[2]), "Display frame rates do not change movement")
	print("VERIFIED: %d checks, %d failures" % [checks, failures])
	game.free()
	quit(1 if failures else 0)

func verify_course() -> void:
	var course := Course.new()
	var transitions := 0
	var last_end := -1.0
	var fair := true
	var bounded := true
	var spacing := true
	for seed_value in range(20):
		course.reset(seed_value)
		last_end = -1.0
		# Over an hour of travel per seed, including the full speed ramp.
		for position in range(0, 600000, 240):
			course.ensure_ahead(float(position))
			bounded = bounded and course.platforms.size() < 8 and course.relics.size() < 40 and course.stones.size() < 8
			for i in range(1, course.platforms.size()):
				var a: Dictionary = course.platforms[i - 1]
				var b: Dictionary = course.platforms[i]
				if float(b.end) <= last_end:
					continue
				last_end = b.end
				var speed := lerpf(80.0, 144.0, minf(course.arrival_time(a.end) / 120.0, 1.0))
				var height := float(a.y) - float(b.y)
				# Conservative descending crossing; reserve 8 px on either side.
				var flight := (144.0 + sqrt(144.0 * 144.0 - 896.0 * height)) / 448.0 - DT
				fair = fair and speed * flight > float(b.x) - float(a.end) + 16.0
				transitions += 1
			for i in range(1, course.stones.size()):
				spacing = spacing and float(course.stones[i].x) - float(course.stones[i - 1].x) >= 206.4
	check(fair, "Every generated transition is single-jump clearable with takeoff/landing margins")
	check(bounded, "Extended generation keeps entity counts bounded")
	check(spacing, "All runestones respect dash recovery spacing")
	print("COURSE: %d transitions checked across 20 seeds and 12 million pixels" % transitions)

func verify_long_runs() -> void:
	var completed := true
	for seed_value in range(5):
		game.reset(seed_value)
		for tick in range(120 * 240):
			# Bot uses the same public control state as keyboard input, with no immunity.
			for stone in game.course.stones:
				if float(stone.x) > game.x and float(stone.x) - game.x < 25.0:
					game.start_dash()
			if game.grounded:
				for platform in game.course.platforms:
					if game.x >= float(platform.x) and game.x < float(platform.end) and float(platform.end) - game.x < 16.0:
						game.jump_held = true
						game.buffer = 0.12
			game.step(DT)
			if game.dead:
				print("BOT failed seed %d at %.2fs, x %.2f" % [seed_value, game.elapsed, game.x])
				completed = false
				break
		check(game.speed == 144.0, "Normal speed caps at nine units per second")
	check(completed, "Five four-minute runs survive using single jumps and dashes")
