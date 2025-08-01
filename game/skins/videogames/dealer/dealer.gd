extends PlayerSkin

@export var normal_texture: Texture2D
@export var damaged_texture: Texture2D

func _initialize() -> void:
	player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		texture = damaged_texture
	elif new_value > old_value:
		texture = normal_texture
