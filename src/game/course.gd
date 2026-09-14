extends RefCounted
## Bounded, deterministic-for-a-seed course data in logical pixels.
const GROUND := 132.0
var rng := RandomNumberGenerator.new()
var platforms: Array[Dictionary] = []
var relics: Array[Dictionary] = []
var stones: Array[Dictionary] = []
var last_stone := -1000.0

func reset(seed_value: int = -1) -> void:
	if seed_value < 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	platforms.clear()
	relics.clear()
	stones.clear()
	last_stone = -1000.0
	platforms.append({"x": -128.0, "end": 384.0, "y": GROUND})
	for i in range(5):
		relics.append({"x": 64.0 + i * 16.0, "y": GROUND - 14.4})
	# Preserve all 24 units of safe runway; hazards begin on later platforms.
	ensure_ahead(0.0)

func arrival_time(x: float) -> float:
	# Integral of speed: x = 80t + (64/240)t² until 120 seconds.
	if x <= 13440.0:
		return (-80.0 + sqrt(6400.0 + 4.0 * (64.0 / 240.0) * x)) / (128.0 / 240.0)
	return 120.0 + (x - 13440.0) / 144.0

func ensure_ahead(x: float) -> void:
	while float(platforms.back().end) < x + 720.0:
		var previous: Dictionary = platforms.back()
		var t := arrival_time(float(previous.end))
		var gap := 20.0 if t < 8.0 else rng.randf_range(24.0, lerpf(32.0, 56.0, clampf((t - 8.0) / 112.0, 0.0, 1.0)))
		var y := float(previous.y)
		if t >= 20.0:
			y = clampf(y + float(rng.randi_range(-1, 1)) * 8.0, GROUND - 16.0, GROUND + 16.0)
		var start := float(previous.end) + gap
		var length := float([224, 256, 288][rng.randi_range(0, 2)])
		platforms.append({"x": start, "end": start + length, "y": y})
		var arch := rng.randf() < 0.5
		for i in range(5):
			var height := 14.4
			if arch:
				height = [12.8, 28.0, 36.8, 28.0, 12.8][i]
			relics.append({"x": start + 20.0 + i * 13.6, "y": y - height})
		var stone_x := start + 96.0
		if stone_x - last_stone >= 206.4 and rng.randf() < 0.85:
			stones.append({"x": stone_x, "y": y})
			last_stone = stone_x
	while platforms.size() > 1 and float(platforms[0].end) < x - 180.0:
		platforms.pop_front()
	relics = relics.filter(func(r: Dictionary) -> bool: return float(r.x) > x - 180.0)
	stones = stones.filter(func(s: Dictionary) -> bool: return float(s.x) > x - 180.0)
