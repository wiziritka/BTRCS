class_name Loot
extends Control


signal proceeded

var _coins_textures: Array[Texture2D] = [
	load("uid://com744p7pvw4r"),
	load("uid://to0f0otv0eap"),
	load("uid://cbs68u50ugaxe"),
	load("uid://bouq57xti1igf"),
]

@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _wait_timer: Timer = $WaitTimer


func _ready() -> void:
	($Proceed as Control).grab_focus.call_deferred()


func show_loot(loot: Array[String]) -> void:
	for item: String in loot:
		_hide_screens()
		
		var splits: PackedStringArray = item.split(':')
		var type: String = splits[0]
		var value: String = splits[1]
		match type:
			"coins":
				_show_screen(^"Coins")
				var amount: int = int(value)
				_anim.play(&"coins")
				_anim.seek(0.0, true)
				($Coins/Visual/Count as Label).text = "x %s" % value
				if amount < 60:
					($Coins/Visual/Texture as TextureRect).texture = _coins_textures[0]
				elif amount < 150:
					($Coins/Visual/Texture as TextureRect).texture = _coins_textures[1]
				elif amount < 300:
					($Coins/Visual/Texture as TextureRect).texture = _coins_textures[2]
				else:
					($Coins/Visual/Texture as TextureRect).texture = _coins_textures[3]
				await proceeded
			
			"weapon", "skill", "skin":
				_show_screen(^"Equip")
				_anim.play(&"equip")
				_anim.seek(0.0, true)
				
				var item_rarity: ItemsDB.Rarity
				var item_name: String
				var item_description: String
				var item_type: String
				var image: Texture2D
				
				if type == "weapon":
					var data: WeaponData = Globals.items_db.weapons_by_id[value]
					item_type = "Оружие"
					item_name = data.name
					item_description = data.damage_text.format(data.stats) \
							+ '\n' + data.ammo_text.format(data.stats)
					item_rarity = data.rarity
					image = load(data.image_path)
				elif type == "skill":
					var data: SkillData = Globals.items_db.skills_by_id[value]
					item_type = "Навык"
					item_name = data.name
					item_description = data.brief_description.format(data.stats) \
							+ '\n' + data.usage_text.format(data.stats)
					item_rarity = data.rarity
					image = load(data.image_path)
				elif type == "skin":
					var data: SkinData = Globals.items_db.skins_by_id[value]
					item_type = "Скин"
					item_name = data.name
					item_description = data.brief_description
					item_rarity = data.rarity
					image = load(data.image_path)
				
				($Equip/Info/Name as Label).text = item_name
				($Equip/Info/Description as Label).text = item_description
				($Equip/Info/Type as Label).text = item_type
				($Equip/Info/Rarity as Label).text = ItemsDB.RARITY_NAMES[item_rarity]
				($Equip/Info/Rarity as Label).add_theme_color_override(&"font_color",
						ItemsDB.RARITY_COLORS[item_rarity])
				($Equip/Item as TextureRect).texture = image
				($Background as ColorRect).color = ItemsDB.RARITY_COLORS[item_rarity]
				
				($Equip/ScreenGlitch as CanvasItem).visible = item_rarity == ItemsDB.Rarity.SECRET
				match item_rarity:
					ItemsDB.Rarity.COMMON, ItemsDB.Rarity.RARE:
						($Equip/Glow/Glow as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.5)
						($Equip/Glow/EquipLight as CanvasItem).hide()
						($Equip/Glow/Stars as CanvasItem).hide()
					ItemsDB.Rarity.EPIC:
						($Equip/Glow/Glow as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.4)
						($Equip/Glow/Stars as CanvasItem).show()
						($Equip/Glow/EquipLight as CanvasItem).hide()
					ItemsDB.Rarity.LEGENDARY:
						($Equip/Glow/Glow as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.6)
						($Equip/Glow/EquipLight as CanvasItem).show()
						($Equip/Glow/EquipLight as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.4)
						($Equip/Glow/Stars as CanvasItem).show()
					ItemsDB.Rarity.SECRET, ItemsDB.Rarity.SPECIAL:
						($Equip/Glow/Glow as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.3)
						($Equip/Glow/EquipLight as CanvasItem).show()
						($Equip/Glow/EquipLight as CanvasItem).self_modulate = \
								ItemsDB.RARITY_COLORS[item_rarity].lightened(0.1)
						($Equip/Glow/Stars as CanvasItem).show()
				
				_wait_timer.start(1.3)
				await _wait_timer.timeout
				await proceeded
			
			"equip_box", "skin_box", "equip_case", "skin_case":
				pass


func _show_screen(screen: NodePath) -> void:
	(get_node(screen) as CanvasItem).show()
	get_node(screen).process_mode = Node.PROCESS_MODE_INHERIT


func _hide_screens() -> void:
	($Coins as CanvasItem).hide()
	($Equip as CanvasItem).hide()
	($Box as CanvasItem).hide()
	($BoxOpening as CanvasItem).hide()
	
	$Coins.process_mode = Node.PROCESS_MODE_DISABLED
	$Equip.process_mode = Node.PROCESS_MODE_DISABLED
	$Box.process_mode = Node.PROCESS_MODE_DISABLED
	$BoxOpening.process_mode = Node.PROCESS_MODE_DISABLED


func _on_proceed_pressed() -> void:
	proceeded.emit()
