class_name Utils

## Класс с различными вспомогательными методами.

## Проверяет имя игрока и исправляет при необходимости. Если [param id] равен 0, не печатает
## никаких предупреждений. В [param valid] можно передать массив, который после выполнения
## функции будет содержать [code]true[/code], если имя игрока допустимо.[br]
## Недопустимое имя заменяется на "Игрок[[param id], если указан]".
static func validate_player_name(player_name: String, id: int = 0,
		valid: Array[bool] = []) -> String:
	# Там, где якобы пусто, стоит пустой символ
	player_name = strip_string(player_name)
	valid.append(not player_name.is_empty())
	if player_name.is_empty():
		var new_name: String = "Игрок%d" % id if id != 0 else "Игрок"
		if id != 0:
			push_warning("Client's %d player name length is invalid. Falling back to %s." % [
				id,
				new_name,
			])
		return new_name
	elif player_name.length() > Game.MAX_PLAYER_NAME_LENGTH:
		if id != 0:
			push_warning("Client's %d player name length (%d) is more than allowed (%d)." % [
				id,
				player_name.length(),
				Game.MAX_PLAYER_NAME_LENGTH,
			])
		return player_name.left(Game.MAX_PLAYER_NAME_LENGTH)
	return player_name


## Возвращает текстовое представление закодированного в двух числах (тип и значение) события ввода.
static func encoded_input_event_as_text(type: Globals.EncodedInputEventType, value: int) -> String:
	match type:
		Globals.EncodedInputEventType.KEY:
			return OS.get_keycode_string(value)
		Globals.EncodedInputEventType.MOUSE_BUTTON:
			match value:
				MOUSE_BUTTON_LEFT:
					return "ЛКМ"
				MOUSE_BUTTON_MIDDLE:
					return "СКМ"
				MOUSE_BUTTON_RIGHT:
					return "ПКМ"
				MOUSE_BUTTON_XBUTTON1:
					return "X1"
				MOUSE_BUTTON_XBUTTON2:
					return "X2"
				MOUSE_BUTTON_WHEEL_DOWN:
					return "Колесо вниз"
				MOUSE_BUTTON_WHEEL_LEFT:
					return "Колесо влево"
				MOUSE_BUTTON_WHEEL_RIGHT:
					return "Колесо вправо"
				MOUSE_BUTTON_WHEEL_UP:
					return "Колесо вверх"
	return "НЕИЗВЕСТНО"


## Возвращает [code]true[/code], если указанный адрес в [param address] может использоваться
## для подключения к серверу. Если [param check_domain] равняется [code]true[/code], то
## также выполняется проверка существования домена (если указан не IP-адрес).
static func is_valid_address(address: String, check_domain: bool) -> bool:
	return (
			address.is_valid_ip_address()
			or (address.count('.') > 0 and address.find('.') > 0
			and address.rfind('.') < address.length() - 1)
			and not (check_domain and IP.resolve_hostname(address).is_empty())
	)


## Избавляет строку от различных вспомогательных символов (пробелы, ...).
static func strip_string(string: String) -> String:
	return string.strip_edges().strip_escapes().lstrip('⁣').rstrip('⁣')


## Считает шансы для ящиков, где [param *_base] - базовые шансы, [param *_got] - сколько предметов
## определённых редкостей было получено без награды, [param chance_increase] - на сколько процентов
## относительно базового повышается шанс на редкость за каждое открытие без награды.
## Возвращает массив из трёх элементов - непосредственно шансы. Всё указывается в процентах.
static func calculate_box_chances(rare_base: float, epic_base: float, legendary_base: float,
		chance_increase: float, rare_got: int, epic_got: int, legendary_got: int) -> Array[float]:
	const MIN_CHANCE := 0.2
	var chances: Array[float]
	chances.append(rare_base)
	chances.append(epic_base)
	chances.append(legendary_base)
	
	for i: int in legendary_got:
		var rare_increase: float = rare_base * chance_increase / 100.0
		var epic_increase: float = epic_base * chance_increase / 100.0
		var decrease: float = minf(rare_increase + epic_increase,
				chances[2] - legendary_base * MIN_CHANCE)
		if is_zero_approx(decrease):
			continue
		rare_increase = decrease / (rare_increase + epic_increase) * rare_increase
		epic_increase = decrease / (rare_increase + epic_increase) * epic_increase
		chances[0] += rare_increase
		chances[1] += epic_increase
		chances[2] -= decrease
	
	for i: int in epic_got:
		var rare_increase: float = rare_base * chance_increase / 100.0
		var legendary_increase: float = legendary_base * chance_increase / 100.0
		var decrease: float = minf(rare_increase + legendary_increase,
				chances[1] - epic_base * MIN_CHANCE)
		if is_zero_approx(decrease):
			continue
		rare_increase = decrease / (rare_increase + legendary_increase) * rare_increase
		legendary_increase = decrease / (rare_increase + legendary_increase) * legendary_increase
		chances[0] += rare_increase
		chances[1] -= decrease
		chances[2] += legendary_increase
	
	for i: int in rare_got:
		var epic_increase: float = epic_base * chance_increase / 100.0
		var legendary_increase: float = legendary_base * chance_increase / 100.0
		var decrease: float = minf(epic_increase + legendary_increase,
				chances[0] - rare_base * MIN_CHANCE)
		if is_zero_approx(decrease):
			continue
		epic_increase = decrease / (epic_increase + legendary_increase) * epic_increase
		legendary_increase = decrease / (epic_increase + legendary_increase) * legendary_increase
		chances[0] -= decrease
		chances[1] += epic_increase
		chances[2] += legendary_increase
	
	return chances
