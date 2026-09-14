extends RefCounted
## All artwork and glyphs are original opaque, integer-aligned pixel shapes.
const INK := Color("101419")
const CHAR := Color("252d32")
const STONE := Color("59615d")
const BROWN := Color("594b36")
const GOLD := Color("b58a43")
const MOSS := Color("628548")
const PALE := Color("b5cf83")
const WHITE := Color("f3efd9")
const GLYPHS := {
	"A": [14,17,17,31,17,17,17], "B": [30,17,17,30,17,17,30],
	"C": [14,17,16,16,16,17,14], "D": [30,17,17,17,17,17,30],
	"E": [31,16,16,30,16,16,31], "F": [31,16,16,30,16,16,16],
	"G": [14,17,16,23,17,17,15], "H": [17,17,17,31,17,17,17],
	"I": [31,4,4,4,4,4,31], "J": [7,2,2,2,18,18,12],
	"K": [17,18,20,24,20,18,17], "L": [16,16,16,16,16,16,31],
	"M": [17,27,21,21,17,17,17], "N": [17,25,25,21,19,19,17],
	"O": [14,17,17,17,17,17,14], "P": [30,17,17,30,16,16,16],
	"Q": [14,17,17,17,21,18,13], "R": [30,17,17,30,20,18,17],
	"S": [15,16,16,14,1,1,30], "T": [31,4,4,4,4,4,4],
	"U": [17,17,17,17,17,17,14], "V": [17,17,17,17,17,10,4],
	"W": [17,17,17,21,21,21,10], "X": [17,17,10,4,10,17,17],
	"Y": [17,17,10,4,4,4,4], "Z": [31,1,2,4,8,16,31],
	"0": [14,17,19,21,25,17,14], "1": [4,12,4,4,4,4,14],
	"2": [14,17,1,2,4,8,31], "3": [30,1,1,14,1,1,30],
	"4": [2,6,10,18,31,2,2], "5": [31,16,16,30,1,1,30],
	"6": [14,16,16,30,17,17,14], "7": [31,1,2,4,8,8,8],
	"8": [14,17,17,14,17,17,14], "9": [14,17,17,15,1,1,14],
	"/": [1,1,2,4,8,16,16], " ": [0,0,0,0,0,0,0]
}

func box(c: Node2D, x: float, y: float, w: float, h: float, color: Color) -> void:
	c.draw_rect(Rect2(floorf(x), floorf(y), w, h), color)

func text(c: Node2D, value: String, x: int, y: int, color: Color) -> void:
	for character in value:
		var rows: Array = GLYPHS.get(character, GLYPHS[" "])
		for row in range(7):
			for column in range(5):
				if int(rows[row]) & (1 << (4 - column)):
					box(c, x + column, y + row, 1, 1, color)
		x += 6

func paint(g: Node2D) -> void:
	box(g, 0, 0, 320, 180, INK)
	var camera: float = floorf(g.x) - 80.0
	# Infinite repeated architecture, anchored in world space, never recycled on-screen.
	for layer in range(2):
		var parallax := 0.15 if layer == 0 else 0.4
		var span := 112 if layer == 0 else 144
		var shift := int(floor(camera * parallax))
		var first := int(floor(float(shift) / span)) - 1
		for i in range(first, first + 6):
			var px := float(i * span - shift)
			ruins(g, px, 29.0 if layer == 0 else 64.0, layer, i)
	for platform in g.course.platforms:
		platform_art(g, floorf(float(platform.x) - camera), float(platform.y), float(platform.end) - float(platform.x), int(platform.x))
	for relic in g.course.relics:
		var rx := floorf(float(relic.x) - camera)
		var ry := floorf(float(relic.y))
		box(g, rx, ry - 4, 1, 9, BROWN)
		box(g, rx - 2, ry - 2, 5, 5, GOLD)
		box(g, rx - 3, ry - 1, 7, 3, GOLD)
		box(g, rx, ry - 3, 1, 6, WHITE)
		box(g, rx - 1, ry - 1, 1, 2, PALE)
	for stone in g.course.stones:
		var sx := floorf(float(stone.x) - camera)
		var sy := float(stone.y)
		box(g, sx - 6, sy - 24, 12, 24, BROWN)
		box(g, sx - 4, sy - 28, 8, 3, GOLD)
		box(g, sx - 5, sy - 25, 9, 23, GOLD)
		box(g, sx - 3, sy - 25, 1, 21, WHITE)
		box(g, sx, sy - 21, 1, 12, INK)
		box(g, sx + 1, sy - 20, 2, 2, INK)
		box(g, sx + 1, sy - 15, 2, 2, INK)
		box(g, sx - 2, sy - 12, 2, 2, INK)
		box(g, sx - 7, sy - 3, 14, 3, BROWN)
	for ghost in g.ghosts:
		unicorn(g, float(ghost.x) - camera, ghost.y, 10, true)
	if not g.dead or g.death_time < 0.65:
		var pose := int(g.elapsed * 12.0 * g.speed / 80.0) % 8
		if not g.grounded:
			pose = 8 if g.vy < 0.0 else 9
		if g.dash_left > 0.0:
			pose = 10
		if g.dead:
			pose = 11
		unicorn(g, 80.0, g.y, pose, false)
	for effect in g.effects:
		box(g, effect.p.x - camera, effect.p.y, 2, 2, WHITE if effect.ivory else GOLD)
	box(g, 0, 0, 320, 17, INK)
	box(g, 0, 16, 320, 1, CHAR)
	text(g, "SCORE %06d" % g.score, 7, 5, WHITE)
	var relic_label := "RELICS %03d" % g.relic_count
	text(g, relic_label, 314 - relic_label.length() * 6, 5, GOLD)
	box(g, 5, 158, 78, 20, INK)
	text(g, "DASH READY" if g.cooldown <= 0.00001 and g.dash_left == 0.0 else "DASH", 8, 161, PALE)
	box(g, 8, 172, 70, 3, CHAR)
	var charge: float = 1.0 - g.cooldown / 0.7
	if g.dash_left > 0.0:
		charge = g.dash_left / 0.2
	box(g, 8, 172, floorf(70.0 * charge), 2, MOSS)
	if g.elapsed < 6.0 and not g.dead:
		box(g, 221, 156, 96, 22, INK)
		text(g, "SPACE / Z  JUMP", 226, 159, WHITE)
		text(g, "SHIFT / X  DASH", 226, 169, PALE)
	if g.dead:
		box(g, 104, 63, 112, 49, STONE)
		box(g, 105, 64, 110, 47, INK)
		box(g, 109, 68, 102, 1, MOSS)
		text(g, "RUN ENDED", 133, 77, WHITE)
		text(g, "R TO RETRY", 130, 95, GOLD)

func ruins(c: Node2D, x: float, y: float, layer: int, index: int) -> void:
	var color := CHAR
	# Stepped arch made entirely of square masonry, with open central span.
	box(c, x, y + 19, 14, 125, color)
	box(c, x + 76, y + 19, 14, 125, color)
	box(c, x + 9, y + 10, 72, 12, color)
	box(c, x + 18, y + 3, 54, 10, color)
	box(c, x + 29, y, 32, 5, color)
	box(c, x + 14, y + 20, 8, 10, color)
	box(c, x + 68, y + 20, 8, 10, color)
	box(c, x - 3, y + 37, 20, 5, color)
	box(c, x + 73, y + 37, 20, 5, color)
	if layer == 1:
		for row in range(9):
			box(c, x + 2, y + 22 + row * 9, 10, 1, STONE if row % 4 == 0 else INK)
			box(c, x + 78, y + 25 + row * 9, 10, 1, INK)
		box(c, x + 20, y + 4, 19, 2, STONE)
		box(c, x + 51, y + 9, 12, 1, STONE)
		for j in range(7):
			box(c, x + 8 + (j % 2) * 2, y + 8 + j * 5, 2, 6, MOSS)
			if j % 2 == 0:
				box(c, x + 5, y + 11 + j * 5, 4, 2, MOSS)
		# Ruined parapets and rubble vary by repeat index.
		box(c, x + 103, y + 35 + posmod(index, 3) * 8, 20, 85, CHAR)
		box(c, x + 105, y + 30 + posmod(index, 3) * 8, 7, 6, CHAR)
		box(c, x + 117, y + 27 + posmod(index, 3) * 8, 6, 9, CHAR)

func platform_art(c: Node2D, x: float, y: float, width: float, salt: int) -> void:
	box(c, x, y, width, 110, CHAR)
	# Only draw visible bricks; cost stays bounded on the opening platform too.
	for row in range(7):
		var offset := 12 if row % 2 else 0
		for col in range(int(width / 24.0) + 1):
			var bx := x + col * 24 - offset
			var start := maxf(x + 1, bx + 1)
			var end := minf(x + width - 1, bx + 23)
			if end > 0 and start < 320 and end > start:
				box(c, start, y + 5 + row * 10, end - start, 8, STONE if row < 3 or posmod(col + row + salt, 4) == 0 else CHAR)
	box(c, x, y, width, 3, MOSS)
	box(c, x, y + 3, width, 1, BROWN)
	for i in range(int(width / 7.0)):
		var px := x + i * 7
		if px < -8 or px > 320:
			continue
		if posmod(i + salt, 3) == 0:
			box(c, px, y - 1, 4, 1, PALE)
		box(c, px + 2, y + 2, 2, 2 + posmod(i + salt, 5), MOSS)
	box(c, x + 2, y + 8, 1, 20, BROWN)

func unicorn(c: Node2D, center: float, feet: float, pose: int, ghost: bool) -> void:
	var x := floorf(center) - 16
	var y := floorf(feet) - 28
	var body := MOSS if ghost else WHITE
	var shade := MOSS if ghost else PALE
	var mane := MOSS if ghost else PALE
	var bob := 1 if pose in [1, 2, 5, 6] else 0
	if pose == 11:
		bob = 6
	y += bob
	# Tail curls, haunch, chest, sloped neck, muzzle, ear and ivory horn.
	box(c, x + 2, y + 11, 6, 3, mane)
	box(c, x, y + 13, 5, 3, mane)
	box(c, x + 1, y + 16, 3, 2, mane)
	box(c, x + 6, y + 11, 15, 9, body)
	box(c, x + 8, y + 10, 11, 2, body)
	box(c, x + 8, y + 19, 10, 2, shade)
	box(c, x + 19, y + 7, 5, 12, body)
	box(c, x + 21, y + 4, 6, 8, body)
	box(c, x + 25, y + 7, 6, 4, body)
	box(c, x + 21, y + 1, 2, 4, body)
	box(c, x + 27, y + 1, 1, 4, body)
	box(c, x + 28, y - 1, 1, 3, body)
	box(c, x + 19, y + 4, 3, 5, mane)
	box(c, x + 17, y + 7, 3, 6, mane)
	box(c, x + 15, y + 9, 3, 2, mane)
	if not ghost:
		box(c, x + 25, y + 6, 1, 1, INK)
		box(c, x + 29, y + 10, 2, 1, BROWN)
	# Eight authored leg arrangements, plus rise/fall/dash/stumble silhouettes.
	var legs: Array = [
		[-3, 3, 3, -2], [-2, 1, 4, 0], [0, -2, 2, 3], [2, -3, 0, 4],
		[3, -2, -3, 2], [2, 0, -4, 0], [0, 3, -2, -2], [-2, 4, 0, -3],
		[-3, -1, 3, 1], [1, 2, -1, 2], [-5, -4, 5, 4], [3, 4, 3, 5]
	][pose]
	for i in range(4):
		var hip := 8 + (i % 2) * 10
		var extension := int(legs[i])
		var leg_color := shade if i < 2 else body
		var length := 4 if pose in [8, 10, 11] else 6 - posmod(pose + i, 3)
		box(c, x + hip, y + 19, 2, 3, leg_color)
		box(c, x + hip + mini(0, extension), y + 21, abs(extension) + 2, 2, leg_color)
		box(c, x + hip + extension, y + 22, 2, length - 1, leg_color)
		box(c, x + hip + extension, y + 21 + length, 3, 1, MOSS if ghost else BROWN)
	if pose == 10:
		box(c, x - 4, y + 8, 11, 1, mane)
		box(c, x - 7, y + 19, 10, 1, mane)
