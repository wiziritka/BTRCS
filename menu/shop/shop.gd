extends Control


const SPECIAL_OFFERS_START_ID: int = 500
const ONLINE_OFFERS_START_ID: int = 1000
const ITEMS_NAMES: Dictionary[String, String] = {
	"coins": "Монеты",
	"weapon": "Оружие",
	"skill": "Навык",
	"skin": "Скин",
	"skin_box": "Ящик со скином",
	"skin_elite_box": "Элитный ящик со скином",
	"equip_box": "Ящик с экипировкой",
	"equip_elite_box": "Элитный ящик с экипировкой",
}

# TODO: переменные для ящиков

var _items_offer_icons: Dictionary[String, Texture2D] = {
	"coins": load("uid://dmpm2a2wq3u4p"),
	"skin_box": load("uid://u3uysy5do7nd"),
	"skin_elite_box": load("uid://bagp5s7stcybl"),
	"equip_box": load("uid://dx36ekj6pm8tr"),
	"equip_elite_box": load("uid://1e2hpb4yqrq3"),
}
var _offer_scene: PackedScene = preload("uid://dn1f63651tgy0")
var _offer_item_scene: PackedScene = preload("uid://dbnx3sb61pp2")
@onready var _purchase_dialog: ConfirmationDialog = $Purchase


func _ready() -> void:
	# TODO: генерация и листинг офферов
	_list_offer(50, "coins:100,equip_box:1", "Подарок)", 100, 1)
	
	Globals.main.loot_received.connect(_update_shop)
	_update_shop()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func buy(cost: int, rewards_str: String, offer_id: int = -1) -> void:
	var rewards: Array[String]
	rewards.assign(rewards_str.split(','))
	print_verbose("Purchase of %s with cost %d (offer ID: %d) requested." % [
		str(rewards),
		cost,
		offer_id,
	])
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
		var description: String
		match type:
			"coins":
				description = value
			"skin_box", "skin_elite_box", "equip_box", "equip_elite_box":
				description = "%s шт." % value
			"weapon":
				description = Globals.items_db.weapons_by_id[value].name
			"skill":
				description = Globals.items_db.skills_by_id[value].name
			"skin":
				description = Globals.items_db.skins_by_id[value].name
		_purchase_dialog.dialog_text += "- %s: %s\n" % [ITEMS_NAMES[type], description]
	
	_purchase_dialog.dialog_text += "за монеты: %d?" % cost
	if _purchase_dialog.confirmed.is_connected(_on_purchase_confirmed):
		_purchase_dialog.confirmed.disconnect(_on_purchase_confirmed)
	_purchase_dialog.confirmed.connect(_on_purchase_confirmed.bind(cost, rewards, offer_id))
	_purchase_dialog.popup_centered(Vector2i(_purchase_dialog.size.x, 0))
	print_verbose("Waiting for purchase confirmation...")


func _list_offer(cost: int, rewards_str: String, offer_name: String, sale: int, id: int) -> void:
	var offer: PanelContainer = _offer_scene.instantiate()
	offer.name = str(id)
	(offer.get_node(^"VBox/Name") as Label).text = offer_name
	if sale != 0:
		(offer.get_node(^"VBox/Buy/Sale") as CanvasItem).show()
		(offer.get_node(^"VBox/Buy/Sale/Amount") as Label).text = \
				('-' if sale > 0 else '+') + str(sale) + '%'
	if cost <= 0:
		(offer.get_node(^"VBox/Buy") as Button).text = "Бесплатно"
		(offer.get_node(^"VBox/Buy") as Button).icon = null
	else:
		(offer.get_node(^"VBox/Buy") as Button).text = str(cost)
	(offer.get_node(^"VBox/Buy") as BaseButton).pressed.connect(buy.bind(cost, rewards_str, id))
	
	var rewards: Array[String]
	rewards.assign(rewards_str.split(','))
	(offer.get_node(^"VBox/Items") as GridContainer).columns = ceili(rewards.size() / 2.0)
	for reward: String in rewards:
		var offer_item: ColorRect = _offer_item_scene.instantiate()
		
		var type: String = Utils.strip_string(reward.get_slice(':', 0))
		var value: String = Utils.strip_string(reward.get_slice(':', 1))
		var description: String
		var icon: Texture2D
		match type:
			"coins":
				description = value
				icon = _items_offer_icons[type]
			"skin_box", "skin_elite_box", "equip_box", "equip_elite_box":
				description = "%s шт." % value
				icon = _items_offer_icons[type]
			"weapon":
				description = Globals.items_db.weapons_by_id[value].name
				icon = load(Globals.items_db.weapons_by_id[value].image_path)
				offer_item.color = \
						ItemsDB.RARITY_COLORS[Globals.items_db.weapons_by_id[value].rarity]
			"skill":
				description = Globals.items_db.skills_by_id[value].name
				icon = load(Globals.items_db.skills_by_id[value].image_path)
				offer_item.color = \
						ItemsDB.RARITY_COLORS[Globals.items_db.skills_by_id[value].rarity]
			"skin":
				description = Globals.items_db.skins_by_id[value].name
				icon = load(Globals.items_db.skins_by_id[value].image_path)
				offer_item.color = \
						ItemsDB.RARITY_COLORS[Globals.items_db.skins_by_id[value].rarity]
		
		(offer_item.get_node(^"Name") as Label).text = ITEMS_NAMES[type]
		(offer_item.get_node(^"Description") as Label).text = description
		(offer_item.get_node(^"Icon") as TextureRect).texture = icon
		offer.get_node(^"VBox/Items").add_child(offer_item)
	
	if id >= SPECIAL_OFFERS_START_ID:
		%SpecialOffersContainer.add_child(offer)
	else:
		%DailyOffersContainer.add_child(offer)
	print_verbose("Listed offer %s with ID %d: cost - %d, rewards - %s, sale - %d." % [
		offer_name,
		id,
		cost,
		str(rewards),
		sale,
	])


func _delete_offer(id: int) -> void:
	if id >= SPECIAL_OFFERS_START_ID:
		var offer: PanelContainer = %SpecialOffersContainer.get_node(str(id))
		%SpecialOffersContainer.remove_child(offer)
		offer.queue_free()
	else:
		var offer: PanelContainer = %DailyOffersContainer.get_node(str(id))
		%DailyOffersContainer.remove_child(offer)
		offer.queue_free()
	
	if id < ONLINE_OFFERS_START_ID:
		var offers_key := "daily_offers" if id < SPECIAL_OFFERS_START_ID else "special_offers"
		var offers: Array[Dictionary] = Globals.get_variant(offers_key, [] as Array[Dictionary])
		for idx: int in range(offers.size() - 1, -1, -1):
			var offer: Dictionary = offers[idx]
			if not "id" in offer or offer["id"] == id:
				offers.remove_at(idx)
		Globals.set_variant(offers_key, offers)
	else:
		var used_online_offers: Array[int] = \
				Globals.get_variant("used_online_offers", [] as Array[int])
		if not id in used_online_offers:
			used_online_offers.append(id)
			Globals.set_variant("used_online_offers", used_online_offers)


func _update_shop() -> void:
	(%CoinsCount as Label).text = str(Globals.get_int("coins"))
	
	# TODO: чекать и удалять акции
	
	(%SpecialOffers as CanvasItem).visible = %SpecialOffersContainer.get_child_count() > 0
	(%NoDailyOffers as CanvasItem).visible = %DailyOffersContainer.get_child_count() == 0
	(%DailyOffersContainer as CanvasItem).visible = %DailyOffersContainer.get_child_count() > 0


func _on_purchase_confirmed(cost: int, rewards: Array[String], offer_id: int = -1) -> void:
	print_verbose("Purchase confirmed.")
	if offer_id >= 0:
		_delete_offer(offer_id)
	Globals.set_int("coins", Globals.get_int("coins") - cost)
	Globals.main.receive_loot(rewards)


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
