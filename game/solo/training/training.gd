class_name Training
extends World


signal stats_changed

var damaged: int = 0
var kills: int = 0

var _player: Player
var _current_map: Node2D
var _spawn_point: Marker2D


func _initialize() -> void:
	load_default_map()
	for i: int in 5:
		spawn_dummy(Vector2(randf_range(-800, 800), randf_range(-800, 800)), randi_range(50, 150))


func spawn_player() -> void:
	var player: Player = entity_scenes[0].instantiate()
	player.position = _spawn_point.global_position
	player.team = 0
	player.id = multiplayer.get_unique_id()
	player.player_name = Globals.get_string("player_name")
	player.equip_data = [
		Globals.items_db.skins_by_id[Globals.get_string("selected_skin")].idx_in_db,
		Globals.items_db.skills_by_id[Globals.get_string("selected_skill")].idx_in_db,
		Globals.items_db.weapons_by_id[Globals.get_string("selected_light_weapon")].idx_in_db,
		Globals.items_db.weapons_by_id[Globals.get_string("selected_heavy_weapon")].idx_in_db,
		Globals.items_db.weapons_by_id[Globals.get_string("selected_support_weapon")].idx_in_db,
		Globals.items_db.weapons_by_id[Globals.get_string("selected_melee_weapon")].idx_in_db,
	]
	player.equip_data.append(-1)
	player.name = "Player%d" % player.id
	player.killed.connect(_on_player_killed.bind(player))
	
	($Camera as SmartCamera).teleport_to(_spawn_point.global_position)
	$Entities.add_child(player, true)
	_player = player


func spawn_dummy(position: Vector2, max_health: int) -> void:
	var dummy: Entity = entity_scenes[1].instantiate()
	dummy.position = position
	dummy.team = 1
	dummy.id = -randi()
	dummy.name += str(dummy.id)
	dummy.max_health = max_health
	dummy.health_changed.connect(_on_mob_health_changed)
	dummy.died.connect(_on_mob_died.bind(dummy))
	$Entities.add_child(dummy, true)


func load_default_map() -> void:
	cleanup()
	if _current_map:
		remove_child(_current_map)
		_current_map.queue_free()
	var map_scene: PackedScene = load("uid://bo4g1oix6cim0")
	var map: Node2D = map_scene.instantiate()
	_spawn_point = map.get_node(^"SpawnPoint")
	# загрузка кастомной карты
	add_child(map)
	_current_map = map
	# запекание навигации
	spawn_player()
	
	if not tracks.is_empty():
		($Music as AudioStreamPlayer).stream = tracks.pick_random()
		($Music as AudioStreamPlayer).play()
		($Music as AudioStreamPlayer).stream_paused = get_tree().paused


func load_map(event_idx: int, map_idx: int) -> void:
	cleanup()
	if _current_map:
		remove_child(_current_map)
		_current_map.queue_free()
	var map_scene: PackedScene = load(Globals.items_db.events[event_idx].maps[map_idx].scene_path)
	var map: Map = map_scene.instantiate()
	_spawn_point = map.get_node(^"SoloSpawnPoint")
	add_child(map)
	_current_map = map
	spawn_player()
	
	var tracks_to_play: Array[AudioStream]
	if not map.custom_tracks.is_empty():
		if Globals.get_setting_bool("official_tracks"):
			tracks_to_play.append_array(map.custom_tracks)
		if Globals.get_setting_bool("custom_tracks"):
			tracks_to_play.append_array(Globals.main.custom_tracks.values())
	else:
		tracks_to_play = tracks
	
	if not tracks_to_play.is_empty():
		($Music as AudioStreamPlayer).stream = tracks_to_play.pick_random()
		($Music as AudioStreamPlayer).play()
		($Music as AudioStreamPlayer).stream_paused = get_tree().paused


func player_restore_health() -> void:
	if _player.current_health == _player.max_health:
		return
	_player.heal(_player.max_health)


func player_restore_ammo() -> void:
	_player.add_ammo_to_weapon.rpc(Weapon.Type.LIGHT, 1.0)
	_player.add_ammo_to_weapon.rpc(Weapon.Type.HEAVY, 1.0)
	_player.add_ammo_to_weapon.rpc(Weapon.Type.SUPPORT, 1.0)
	_player.add_ammo_to_weapon.rpc(Weapon.Type.MELEE, 1.0)


func player_restore_skill() -> void:
	if _player.skill.is_cooldown_blocked(): # чтобы нельзя было использовать, пока действует эффект
		_player.skill_vars[0] = _player.skill.use_times
	else:
		_player.skill_vars = [_player.skill.use_times, 0]


func player_teleport_to_spawn() -> void:
	_player.teleport_to.rpc(_spawn_point.global_position)
	($Camera as SmartCamera).teleport_to(_spawn_point.global_position)


func player_update_equip(skin: String, skill: String, light_weapon: String,
		heavy_weapon: String, support_weapon: String, melee_weapon: String) -> void:
	if _player.skin.data.id != skin:
		_player.set_skin(Globals.items_db.skins_by_id[skin])
	if _player.skill.data.id != skill and not _player.skill.is_cooldown_blocked():
		_player.set_skill(Globals.items_db.skills_by_id[skill], true)
	
	if (_player.weapons.get_child(Weapon.Type.LIGHT) as Weapon).data.id != light_weapon:
		_player.set_weapon(Weapon.Type.LIGHT, Globals.items_db.weapons_by_id[light_weapon])
	if (_player.weapons.get_child(Weapon.Type.HEAVY) as Weapon).data.id != heavy_weapon:
		_player.set_weapon(Weapon.Type.HEAVY, Globals.items_db.weapons_by_id[heavy_weapon])
	if (_player.weapons.get_child(Weapon.Type.SUPPORT) as Weapon).data.id != support_weapon:
		_player.set_weapon(Weapon.Type.SUPPORT, Globals.items_db.weapons_by_id[support_weapon])
	if (_player.weapons.get_child(Weapon.Type.MELEE) as Weapon).data.id != melee_weapon:
		_player.set_weapon(Weapon.Type.MELEE, Globals.items_db.weapons_by_id[melee_weapon])


func _on_mob_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		damaged += old_value - new_value
		stats_changed.emit()


func _on_mob_died(mob: Entity) -> void:
	damaged += mob.current_health
	kills += 1
	stats_changed.emit()


func _on_player_killed() -> void:
	($RespawnTimer as Timer).start()
