class_name Training
extends World


enum BlockType {
	GRASS = 0,
	WALL = 1,
	HOLE = 2,
}
enum EnemyType {
	DUMMY = 0,
	ROBOT_P350 = 1,
}

signal stats_changed
signal map_changed

const BLOCK_COLORS: Array[Color] = [
	Color.LIME_GREEN,
	Color.GOLD,
	Color.SADDLE_BROWN,
]

@export var enemies_icons: Dictionary[EnemyType, Texture2D]

var damaged: int = 0
var kills: int = 0
var enemies_data: Array[EnemyData]

var _player: Player
var _current_map: Node2D
var _spawn_point: Marker2D


func _initialize() -> void:
	load_default_map()


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


func spawn_enemy(type: EnemyType, position: Vector2, health: int, damage_multiplier: float) -> void:
	var enemy: Entity = entity_scenes[1 + type].instantiate()
	enemy.position = position
	enemy.team = 1
	enemy.id = -randi()
	enemy.name += str(enemy.id)
	enemy.max_health = health
	enemy.damage_multiplier = damage_multiplier
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.died.connect(_on_enemy_died.bind(enemy))
	$Entities.add_child(enemy, true)


func load_default_map() -> void:
	cleanup()
	if _current_map:
		remove_child(_current_map)
		_current_map.queue_free()
	
	var map_scene: PackedScene = load("uid://bo4g1oix6cim0")
	var map: Node2D = map_scene.instantiate()
	_spawn_point = map.get_node(^"SpawnPoint")
	
	var map_data: PackedByteArray = Globals.get_variant("custom_training_map", PackedByteArray())
	if not map_data.is_empty():
		var floor_layer: TileMapLayer = map.get_node(^"TileMapLayers/Floor")
		var walls_layer: TileMapLayer = map.get_node(^"TileMapLayers/Walls")
		var minimap_layer: TileMapLayer = map.get_node(^"Minimap/MinimapTiles")
		
		for x: int in 50:
			for y: int in 50:
				var map_coords := Vector2i(x - 25, y - 25)
				match map_data[y * 50 + x]:
					BlockType.GRASS:
						floor_layer.set_cell(map_coords, 1, Vector2i(0, 0))
						walls_layer.erase_cell(map_coords)
						minimap_layer.set_cell(map_coords, 0, Vector2i(0, 1))
					BlockType.WALL:
						floor_layer.set_cell(map_coords, 1, Vector2i(0, 0))
						walls_layer.set_cell(map_coords, 1, Vector2i(1, 0))
						minimap_layer.set_cell(map_coords, 0, Vector2i(0, 0))
					BlockType.HOLE:
						floor_layer.set_cell(map_coords, 1, Vector2i(0, 1))
						walls_layer.erase_cell(map_coords)
						minimap_layer.set_cell(map_coords, 0, Vector2i(1, 0))
	
	enemies_data.clear()
	if Globals.get_variant("custom_training_enemies", [{}]) == [{}]:
		_set_default_enemies_data()
	else:
		var enemies_data_dicts: Array[Dictionary] = \
				Globals.get_variant("custom_training_enemies", [] as Array[Dictionary])
		
		for dict: Dictionary in enemies_data_dicts:
			var type: EnemyType = dict["type"]
			var coords: Vector2i = dict["coords"]
			var health: int = dict["health"]
			var damage_multiplier: float = dict["damage_multiplier"]
			var enemy_data := EnemyData.new(type, coords)
			enemy_data.health = health
			enemy_data.damage_multiplier = damage_multiplier
			enemies_data.append(enemy_data)
	
	for enemy_data: EnemyData in enemies_data:
		var sprite := Sprite2D.new()
		sprite.texture = enemies_icons[enemy_data.type]
		sprite.position = Vector2(enemy_data.coords - Vector2i.ONE * 25) * 160
		sprite.position += Vector2.ONE * 80
		sprite.z_index = -4
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
		map.add_child(sprite)
	
	add_child(map)
	(map.get_node(^"NavigationRegion2D") as NavigationRegion2D).bake_navigation_polygon(false)
	_current_map = map
	
	await get_tree().process_frame
	spawn_player()
	enemies_respawn()
	
	if not tracks.is_empty():
		($Music as AudioStreamPlayer).stream = tracks.pick_random()
		($Music as AudioStreamPlayer).play()
		($Music as AudioStreamPlayer).stream_paused = process_mode == Node.PROCESS_MODE_DISABLED
	
	map_changed.emit()


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
	
	await get_tree().process_frame
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
		($Music as AudioStreamPlayer).stream_paused = process_mode == Node.PROCESS_MODE_DISABLED
	
	map_changed.emit()


func get_map_data() -> PackedByteArray:
	if _current_map is Map or not is_instance_valid(_current_map):
		push_error("Current map must be default to get map data.")
		return PackedByteArray()
	if Globals.get_variant("custom_training_map", PackedByteArray()) != PackedByteArray():
		return Globals.get_variant("custom_training_map", PackedByteArray())
	
	var data := PackedByteArray()
	data.resize(50 * 50)
	
	var floor_layer: TileMapLayer = _current_map.get_node(^"TileMapLayers/Floor")
	for x: int in 50:
		for y: int in 50:
			# отнимаем 25 т.к. в карте есть отрицательные координаты
			var atlas_coords: Vector2i = floor_layer.get_cell_atlas_coords(Vector2i(x - 25, y - 25))
			data[y * 50 + x] = BlockType.HOLE if atlas_coords == Vector2i(0, 1) else BlockType.GRASS
	
	var walls_layer: TileMapLayer = _current_map.get_node(^"TileMapLayers/Walls")
	for x: int in 50:
		for y: int in 50:
			var atlas_coords: Vector2i = walls_layer.get_cell_atlas_coords(Vector2i(x - 25, y - 25))
			if atlas_coords == Vector2i(1, 0):
				data[y * 50 + x] = BlockType.WALL
	
	return data


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


func enemies_destroy() -> void:
	for entity: Entity in entities.values():
		if not entity is Player:
			entity.queue_free()


func enemies_respawn() -> void:
	enemies_destroy()
	
	for enemy_data: EnemyData in enemies_data:
		var position := Vector2(enemy_data.coords - Vector2i.ONE * 25) * 160
		position += Vector2.ONE * 80
		spawn_enemy(enemy_data.type, position, enemy_data.health, enemy_data.damage_multiplier)


func _set_default_enemies_data() -> void:
	var enemy_data := EnemyData.new(EnemyType.DUMMY, Vector2i(30, 25))
	enemy_data.health = 1000
	enemies_data.append(enemy_data)


func _on_enemy_health_changed(old_value: int, new_value: int) -> void:
	if old_value > new_value:
		damaged += old_value - new_value
		stats_changed.emit()


func _on_enemy_died(mob: Entity) -> void:
	damaged += mob.current_health
	kills += 1
	stats_changed.emit()


func _on_player_killed() -> void:
	($RespawnTimer as Timer).start()


class EnemyData:
	var type: EnemyType
	var health: int = 100
	var damage_multiplier := 1.0
	var coords: Vector2i
	
	func _init(enemy_type: EnemyType, new_coords: Vector2i) -> void:
		type = enemy_type
		coords = new_coords
