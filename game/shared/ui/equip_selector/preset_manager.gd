extends Window

@export_node_path("EquipSelector") var equip_selector_path: NodePath

func _ready() -> void:
	var equip_selector: EquipSelector = get_node(equip_selector_path)
	for preset: PanelContainer in %PresetsContainer.get_children():
		preset.set(&"equip_selector", equip_selector)
