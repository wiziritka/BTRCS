class_name Map
extends Node2D
## Базовый класс для карт.

## Список треков для этой карты. Если не пуст, переопределяет заданные в [Event].
@export var custom_tracks: Array[AudioStream]
## Ссылка на [Event] этой карты. Может быть [code]null[/code].
var event: Event

func _ready() -> void:
	event = get_parent() as Event
	if event and not custom_tracks.is_empty():
		event.tracks = custom_tracks
	_initialize()


## Виртуальный метод для инициализации карты. Для доступа к событию используйте [member event],
## однако перед этим проверьте его на [code]null[/code].
func _initialize() -> void:
	pass
