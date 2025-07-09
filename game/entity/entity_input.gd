class_name EntityInput
extends MultiplayerSynchronizer

## Узел с вводом для сущности.

## Направление движения сущности.
var move_direction := Vector2():
	set(value):
		if not value.is_finite():
			move_direction = Vector2.ZERO
		elif value.length_squared() > 1.0:
			move_direction = value.limit_length(1.0)
		else:
			move_direction = value
## Направление прицеливания.
var aim_direction := Vector2.RIGHT:
	get:
		if not is_multiplayer_authority() or turn_with_aim:
			return aim_direction
		if not is_zero_approx(move_direction.x):
			aim_direction.x = absf(aim_direction.x) * signf(move_direction.x)
		return aim_direction
	set(value):
		if not value.is_finite() or value.is_zero_approx():
			aim_direction = Vector2.RIGHT
		elif value.length_squared() > 1.0:
			aim_direction = value.limit_length(1.0)
		else:
			aim_direction = value

## Если равно [code]true[/code], то сущность поворачивается в направлении прицеливания,
## иначе направление прицела поворачивается в сторону движения сущности (если движется).
var turn_with_aim := false
