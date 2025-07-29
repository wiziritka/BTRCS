extends Timer

@onready var _player: Player = get_parent()

func _ready() -> void:
	_player.make_immune()
	(_player.get_node(^"Visual/Skin") as CanvasItem).modulate = Color(1.0, 1.0, 1.0, 0.5)


func _on_timeout() -> void:
	_player.unmake_immune()
	var tween: Tween = create_tween()
	tween.tween_property(_player.get_node(^"Visual/Skin") as CanvasItem,
			^":modulate", Color.WHITE, 0.3)
