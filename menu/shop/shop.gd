extends Control

@onready var _purchase_dialog: ConfirmationDialog = $Purchase

func _ready() -> void:
	Globals.main.loot_received.connect(_on_loot_received)
	_update_coins()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func buy(cost: int, rewards_str: String, offer_id: int = -1) -> void:
	var rewards: Array[String]
	rewards.assign(rewards_str.split(','))
	print_verbose("Purchase of %s with cost %d requested." % [str(rewards), cost])
	rewards = Globals.main.verify_loot(rewards)
	if rewards.is_empty():
		print_verbose("Nothing to purchase, ignoring.")
		return
	
	if cost > Globals.get_int("coins"):
		print_verbose("Not enough coins.")
		($NoCoins/AnimationPlayer as AnimationPlayer).play(&"not_enough")
		($NoCoins/AnimationPlayer as AnimationPlayer).seek(0.0)
		return
	if cost <= 0:
		_on_purchase_confirmed(cost, rewards, offer_id)
		return
	
	_purchase_dialog.dialog_text = "Ты действительно хочешь купить:\n"
	for reward: String in rewards:
		var type: String = Utils.strip_string(reward.get_slice(':', 0))
		var value: String = Utils.strip_string(reward.get_slice(':', 1))
		match type:
			"coins":
				_purchase_dialog.dialog_text += "- Монеты: %d" % int(value)
			"skin_box":
				_purchase_dialog.dialog_text += "- Ящик со скинами: %d шт." % int(value)
			"skin_elite_box":
				_purchase_dialog.dialog_text += "- Элитный ящик со скинами: %d шт." % int(value)
			"equip_box":
				_purchase_dialog.dialog_text += "- Ящик с экипировкой: %d шт." % int(value)
			"equip_elite_box":
				_purchase_dialog.dialog_text += "- Элитный ящик с экипировкой: %d шт." % int(value)
			"weapon":
				_purchase_dialog.dialog_text += "- Оружие: %s" \
						% Globals.items_db.weapons_by_id[value].name
			"skill":
				_purchase_dialog.dialog_text += "- Навык: %s" \
						% Globals.items_db.skills_by_id[value].name
			"skin":
				_purchase_dialog.dialog_text += "- Скин: %s" \
						% Globals.items_db.skins_by_id[value].name
		_purchase_dialog.dialog_text += '\n'
	
	_purchase_dialog.dialog_text += "за монеты: %d?" % cost
	if _purchase_dialog.confirmed.is_connected(_on_purchase_confirmed):
		_purchase_dialog.confirmed.disconnect(_on_purchase_confirmed)
	_purchase_dialog.confirmed.connect(_on_purchase_confirmed.bind(cost, rewards, offer_id))
	_purchase_dialog.popup_centered(Vector2i(_purchase_dialog.size.x, 0))
	print_verbose("Waiting for purchase confirmation...")


func _update_coins() -> void:
	(%CoinsCount as Label).text = str(Globals.get_int("coins"))


func _on_purchase_confirmed(cost: int, rewards: Array[String], offer_id: int = -1) -> void:
	print_verbose("Purchase confirmed.")
	if offer_id >= 0:
		pass # TODO
	Globals.set_int("coins", Globals.get_int("coins") - cost)
	Globals.main.receive_loot(rewards)


func _on_loot_received() -> void:
	_update_coins()
	# TODO: обновлять акции


func _on_quit_pressed() -> void:
	queue_free()

# TEST
func _on_line_edit_text_submitted(new_text: String) -> void:
	var loot: Array[String]
	loot.assign(new_text.split(','))
	Globals.main.receive_loot(loot)


func _on_button_pressed() -> void:
	Globals.set_variant("unlocked_weapons", [] as Array[String])
	Globals.set_variant("unlocked_skins", [] as Array[String])
	Globals.set_variant("unlocked_skills", [] as Array[String])
	Globals.set_variant("used_promocodes", [] as Array[String])
