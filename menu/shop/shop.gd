extends Control


func _ready() -> void:
	# TODO обновлять магаз при получении лута
	_update_coins()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func _on_quit_pressed() -> void:
	queue_free()


func _update_coins() -> void:
	(%CoinsCount as Label).text = str(Globals.get_int("coins"))

# TEST
func _on_line_edit_text_submitted(new_text: String) -> void:
	var loot: Array[String]
	loot.assign(new_text.split(','))
	Globals.main.receive_loot(loot)


func _on_button_pressed() -> void:
	Globals.set_variant("unlocked_weapons", [] as Array[String])
	Globals.set_variant("unlocked_skins", [] as Array[String])
	Globals.set_variant("unlocked_skills", [] as Array[String])
