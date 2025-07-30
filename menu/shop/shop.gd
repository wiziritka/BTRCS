extends Control


func _ready() -> void:
	_update_coins()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func _on_quit_pressed() -> void:
	queue_free()


func _update_coins() -> void:
	(%CoinsCount as Label).text = str(Globals.get_int("coins"))
