class_name PlayerInput
extends EntityInput

## Узел с вводом для игрока.

## Игрок начал стрельбу.
signal shooting_started
## Игрок закончил стрельбу.
signal shooting_ended
## Игрок нажал кнопку взаимодействия.
signal interaction_started
## Игрок отпустил кнопку взаимодействия.
signal interaction_ended
## Издаётся, когда количество объектов, с которыми игрок может взаимодействовать, меняется.
signal interactibles_changed

## Ведётся ли стрельба.
var shooting := false:
	set(value):
		if value and not shooting:
			shooting_started.emit()
		elif not value and shooting:
			shooting_ended.emit()
		shooting = value
## Нажата ли кнопка использования.
var interacting := false:
	set(value):
		if value and not interacting:
			interaction_started.emit()
		elif not value and interacting:
			interaction_ended.emit()
		interacting = value

## Показывается ли линия прицела.
var showing_aim := false

var _interactibles_counter: int = 0


## Добавить объект, с которым может взаимодействовать игрок.
func add_interactible() -> void:
	_interactibles_counter += 1
	interactibles_changed.emit()


## Убрать объект, с которым может взаимодействовать игрок.
func remove_interactible() -> void:
	_interactibles_counter -= 1
	interactibles_changed.emit()


## Возвращает [code]true[/code], если есть объекты, с которыми может взаимодействовать игрок.
func has_interactibles() -> bool:
	return _interactibles_counter > 0
