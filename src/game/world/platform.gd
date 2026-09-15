extends CourseEntity
@export var textures: Array[Texture2D] = []
@onready var sprite: Sprite2D = $Sprite2D

func set_width(width: float) -> void:
	super.set_width(width)
	sprite.region_enabled = false
	for texture in textures:
		if texture.get_width() == int(width):
			sprite.texture = texture
			return
	# Custom/test lengths repeat the default masonry texture.
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, width, 112)
