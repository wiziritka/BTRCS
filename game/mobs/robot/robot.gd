extends Mob


func _process_logic() -> void:
	if agent.is_navigation_finished():
		return
	entity_input.move_direction = global_position.direction_to(agent.get_next_path_position())


func _target_updated() -> void:
	agent.target_position = target.global_position
