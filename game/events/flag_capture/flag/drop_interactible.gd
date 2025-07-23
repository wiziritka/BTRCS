extends Interactible

@onready var _flag: Flag = get_parent()

func _can_player_interact(player: Player) -> bool:
	return player == _flag.player
