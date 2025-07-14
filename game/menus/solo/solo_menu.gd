extends Control

@onready var _game: Game = get_parent()

func _ready() -> void:
	_game.started.connect(_on_game_started)
	_game.closed.connect(_on_game_closed)


func _on_game_started() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED


func _on_game_closed() -> void:
	show()
	process_mode = Node.PROCESS_MODE_INHERIT


func _on_story_pressed() -> void:
	pass


func _on_challenges_pressed() -> void:
	pass


func _on_training_pressed() -> void:
	_game.load_solo_world("uid://f6bay2nx1wy3")


func _on_quit_pressed() -> void:
	Globals.main.open_menu()
