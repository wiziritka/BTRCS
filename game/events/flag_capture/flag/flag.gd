class_name Flag
extends Area2D

## Флаг для события "Захват флага".

## Команда, которой принадлежит этот флаг.
@export var team: int = 0
## Время, за которое флаг возвращается на базу при нахождении на земле.
@export_range(1.0, 20.0, 0.01) var return_time := 5.0
## Сколько секунд нужно удерживать кнопку стрельбы, чтобы отпустить флаг.
@export_range(0.2, 5.0, 0.01) var drop_time := 1.0

var _player: Player
var _base_position: Vector2
var _return_timer := 0.0
var _drop_timer := 0.0

@onready var _timer_progress: TextureProgressBar = $TimerProgress
@onready var _event: FlagCapture = get_tree().get_first_node_in_group(&"Event")


func _ready() -> void:
	if _event.local_team != team:
		$ScreenMarker.queue_free()
	
	_base_position = position
	await get_tree().process_frame # Ждём пока заработает VisibleOnScreenNotifier2D
	_update_minimap_marker(_event.local_team)


func _exit_tree() -> void:
	if is_instance_valid(_player):
		drop()


func _process(delta: float) -> void:
	if _return_timer > 0.0:
		_return_timer -= delta
		_timer_progress.value = _return_timer / return_time
		if _return_timer <= 0.0:
			_timer_progress.hide()
			if multiplayer.is_server():
				teleport_to_base.rpc()
	
	if _drop_timer > 0.0:
		_drop_timer -= delta
		_timer_progress.value = _drop_timer / drop_time
		if _drop_timer <= 0.0 and multiplayer.is_server():
			_drop()


@rpc("reliable", "call_local", "authority", 3)
func carry(id: int) -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	if not id in _event.players:
		return
	
	_return_timer = 0.0
	_drop_timer = 0.0
	_timer_progress.hide()
	_player = _event.players[id]
	_player.block_weapon_usage()
	if multiplayer.is_server():
		_player.tree_exiting.connect(_drop)
	if multiplayer.is_server() or _player.is_local():
		_player.player_input.shooting_started.connect(_on_player_shooting_started)
		_player.player_input.shooting_ended.connect(_on_player_shooting_ended)
	
	var rt := RemoteTransform2D.new()
	rt.name = &"FlagRemote"
	rt.update_rotation = false
	rt.update_scale = false
	_player.add_child(rt)
	rt.remote_path = get_path()
	rt.reset_physics_interpolation()
	print_verbose("Flag of team %d picked up by %d." % [team, _player.id])


@rpc("reliable", "call_local", "authority", 3)
func drop(where: Vector2 = position) -> void:
	print_verbose("Flag of team %d dropped." % team)
	_return_timer = return_time
	_drop_timer = 0.0
	_timer_progress.show()
	position = where
	reset_physics_interpolation()
	
	if not is_instance_valid(_player):
		return
	if multiplayer.is_server():
		_player.tree_exiting.disconnect(_drop)
	if multiplayer.is_server() or _player.is_local():
		_player.player_input.shooting_started.disconnect(_on_player_shooting_started)
		_player.player_input.shooting_ended.disconnect(_on_player_shooting_ended)
	
	(_player.get_node(^"FlagRemote") as RemoteTransform2D).remote_path = ^""
	_player.get_node(^"FlagRemote").queue_free()
	_player.unblock_weapon_usage()
	_player = null


@rpc("reliable", "call_local", "authority", 3)
func teleport_to_base() -> void:
	if multiplayer.get_remote_sender_id() != MultiplayerPeer.TARGET_PEER_SERVER:
		push_error("This method must be called only by server.")
		return
	
	print_verbose("Teleporting team's %d flag to base." % team)
	position = _base_position
	reset_physics_interpolation()


func _drop() -> void:
	drop.rpc(position)


func _update_minimap_marker(local_team: int) -> void:
	if team == local_team:
		$Minimap/MinimapNotifier.set_block_signals(true)
		($Minimap/MinimapMarker/Visual as CanvasItem).show()
	else:
		$Minimap/MinimapNotifier.set_block_signals(false)
		($Minimap/MinimapMarker/Visual as CanvasItem).visible = \
				($Minimap/MinimapNotifier as VisibleOnScreenNotifier2D).is_on_screen()


func _on_player_shooting_started() -> void:
	_drop_timer = drop_time
	if _player.is_local():
		_timer_progress.show()


func _on_player_shooting_ended() -> void:
	_drop_timer = 0.0
	if _player.is_local():
		_timer_progress.hide()


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server() or is_instance_valid(_player):
		return
	var player := body as Player
	if player and player.team != team:
		carry.rpc(player.id)
