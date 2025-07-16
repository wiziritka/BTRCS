extends CanvasLayer


var _selected_event: int = -1
var _selected_map: int = -1
var _selecting_event: int

@onready var _training: Training = get_parent()
@onready var _stats: Label = $Main/Stats

@onready var _equip_selector: EquipSelector = %EquipSelector
@onready var _item_selector: Window = %EquipSelector/ItemSelector
@onready var _items_grid: ItemsGrid = %EquipSelector/%ItemsGrid


func _ready() -> void:
	_items_grid.item_selected.connect(_on_item_selected)


func _change_map() -> void:
	(%CurrentMap as Label).text = "Загрузка карты..."
	(%ReturnToTraining as CanvasItem).show()
	
	await get_tree().process_frame
	await get_tree().process_frame
	_training.load_map(_selected_event, _selected_map)
	(%CurrentMap as Label).text = Globals.items_db.events[_selected_event].maps[_selected_map].name


func _on_item_selected(type: ItemsDB.Item, idx: int) -> void:
	match type:
		ItemsDB.Item.EVENT:
			_item_selector.title = "Выбор карты"
			_item_selector.show()
			_selecting_event = idx
			_items_grid.list_maps_of_event(_selecting_event,
					_selected_map if _selected_event == _selecting_event else -1)
		ItemsDB.Item.MAP:
			if _selecting_event == _selected_event and _selected_map == idx:
				return
			_selected_map = idx
			_selected_event = _selecting_event
			_change_map()


func _on_quit_dialog_confirmed() -> void:
	Globals.main.game.close()


func _on_heal_pressed() -> void:
	_training.player_restore_health()


func _on_ammo_pressed() -> void:
	_training.player_restore_ammo()


func _on_skill_pressed() -> void:
	_training.player_restore_skill()


func _on_teleport_to_spawn_pressed() -> void:
	_training.player_teleport_to_spawn()


func _on_menu_pressed() -> void:
	($Menu as CanvasItem).show()
	get_tree().paused = true


func _on_close_pressed() -> void:
	($Menu as CanvasItem).hide()
	get_tree().paused = false


func _on_equip_selector_items_changed() -> void:
	_training.player_update_equip(_equip_selector.selected_skin, _equip_selector.selected_skill,
			_equip_selector.selected_light_weapon, _equip_selector.selected_heavy_weapon,
			_equip_selector.selected_support_weapon, _equip_selector.selected_melee_weapon)


func _on_training_stats_changed() -> void:
	_stats.text = "Нанесённый урон: %d\nУбийств: %d" % [_training.damaged, _training.kills]


func _on_return_to_training_pressed() -> void:
	_selected_event = -1
	_selected_map = -1
	(%CurrentMap as Label).text = "Загрузка карты..."
	(%ReturnToTraining as CanvasItem).hide()
	
	await get_tree().process_frame
	await get_tree().process_frame
	_training.load_default_map()
	(%CurrentMap as Label).text = "Тренировка"


func _on_select_map_pressed() -> void:
	_items_grid.list_items(ItemsDB.Item.EVENT, _selected_event)
	_item_selector.title = "Выбор события"
	_item_selector.popup_centered()
