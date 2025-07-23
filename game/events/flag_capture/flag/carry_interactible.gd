extends Interactible

@onready var _flag: Flag = get_parent()

func _can_player_interact(player: Player) -> bool:
	return not is_instance_valid(_flag.player) and player.team != _flag.team
