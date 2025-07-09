class_name PlayerInput
extends EntityInput

## Узел с вводом для игрока.

## Игрок начал стрельбу.
signal shooting_started
## Игрок закончил стрельбу.
signal shooting_ended

## Ведётся ли стрельба.
var shooting := false:
	set(value):
		if value and not shooting:
			shooting_started.emit()
		elif not value and shooting:
			shooting_ended.emit()
		shooting = value

## Показывается ли линия прицела.
var showing_aim := false
