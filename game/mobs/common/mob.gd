class_name Mob
extends Entity

## Моб.
##
## Базовый класс для различных мобов - сущностей, не являющихся игроками, способных двигаться
## и искать пути.

## Дистанция, с которой моб может видеть цель.
@export var vision_distance := 3200.0

## Текущая цель моба.
var target: Entity

## [NavigationAgent2D], которым пользуется этот моб.
@onready var agent: NavigationAgent2D = $NavigationAgent2D
## [RayCast2D] используемый для проверки, может ли моб стрелять в цель.
@onready var target_ray_cast: RayCast2D = $TargetRayCast


func _ready() -> void:
	super()
	if not multiplayer.is_server():
		return
	
	var find_target_timer_default_time: float = ($FindTargetTimer as Timer).wait_time
	($FindTargetTimer as Timer).start(randf_range(0.05, find_target_timer_default_time))
	($FindTargetTimer as Timer).wait_time = find_target_timer_default_time
	
	var update_target_timer_default_time: float = ($UpdateTargetTimer as Timer).wait_time
	($UpdateTargetTimer as Timer).start(randf_range(0.05, update_target_timer_default_time))
	($UpdateTargetTimer as Timer).wait_time = update_target_timer_default_time


func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and is_instance_valid(target):
		_process_logic()
	
	super(delta)


## Ищет новую цель для моба. Переопределите для альтернативной логики.
func find_target() -> void:
	target = null
	
	var entities: Array[Entity]
	entities.assign(get_tree().get_nodes_in_group(&"entity"))
	entities = entities.filter(func(entity: Entity) -> bool:
		return entity.team != team and not entity.has_effect(Effect.INVISIBILITY))
	if entities.is_empty():
		return
	
	var closest_entity: Entity
	var closest_distance: float = INF
	for entity: Entity in entities:
		var distance: float = entity.global_position.distance_to(global_position)
		if distance > vision_distance:
			continue
		if distance < closest_distance:
			closest_entity = entity
			closest_distance = distance
	
	target = closest_entity


func _calculate_aim_angle(aim_direction: Vector2 = entity_input.aim_direction) -> float:
	aim_direction.x = absf(aim_direction.x)
	return aim_direction.angle()


func _filter_entities(entity: Entity) -> bool:
	return entity.team == team or entity.has_effect(Effect.INVISIBILITY)


## Виртуальный метод для логики данного моба. Вызывается только на сервере.
func _process_logic() -> void:
	pass


## Виртуальный метод. Взывается только на сервере при обновлении цели или через заданный интервал.
## Перед вызовом данного метода также пробрасывается луч ([member target_ray_cast]) до цели.
func _target_updated() -> void:
	pass


## Виртуальный метод. Взывается только на сервере при исчезновении текущей цели. Используйте для
## сброса логики сущности.
func _target_reset() -> void:
	pass


func _on_find_target_timer_timeout() -> void:
	var target_was := false
	if is_instance_valid(target):
		target_was = true
		if target.tree_exiting.is_connected(_target_reset):
			target.tree_exiting.disconnect(_target_reset)
	
	find_target()
	if is_instance_valid(target):
		target.tree_exiting.connect(_target_reset)
	elif target_was:
		_target_reset()
	
	_on_update_target_timer_timeout()


func _on_update_target_timer_timeout() -> void:
	if not is_instance_valid(target):
		return
	target_ray_cast.target_position = to_local(target.global_position)
	target_ray_cast.force_raycast_update()
	_target_updated()
