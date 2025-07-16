extends CanvasLayer

@onready var _training: Training = get_parent()
@onready var _equip_selector: EquipSelector = %EquipSelector

func _on_quit_dialog_confirmed() -> void:
	Globals.main.game.close()


func _on_heal_pressed() -> void:
	_training.player_restore_health()


func _on_ammo_pressed() -> void:
	_training.player_restore_ammo()


func _on_skill_pressed() -> void:
	_training.player_restore_skill()


func _on_teleport_to_spawn_pressed() -> void:
	_training.player_teleport_to_spawn()


func _on_menu_pressed() -> void:
	($Menu as CanvasItem).show()
	get_tree().paused = true


func _on_close_pressed() -> void:
	($Menu as CanvasItem).hide()
	get_tree().paused = false


func _on_equip_selector_items_changed() -> void:
	_training.player_update_equip(_equip_selector.selected_skin, _equip_selector.selected_skill,
			_equip_selector.selected_light_weapon, _equip_selector.selected_heavy_weapon,
			_equip_selector.selected_support_weapon, _equip_selector.selected_melee_weapon)
