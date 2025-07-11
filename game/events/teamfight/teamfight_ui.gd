class_name TeamfightUI
extends EventUI


func set_kills(red: int, blue: int) -> void:
	($Main/RedCount as Label).text = str(red)
	($Main/BlueCount as Label).text = str(blue)


func show_winner(team: int) -> void:
	if team < 0:
		($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"draw")
		return
	($Main/GameEnd/AnimationPlayer as AnimationPlayer).play(&"victory")
	($Main/GameEnd/Team as Label).text = "Красная" if team == 0 else "Синяя"
	($Main/GameEnd/Team as Control).add_theme_color_override(&"font_color",
			Entity.TEAM_COLORS[team])


func set_time(time: int) -> void:
	($Main/Timer as Label).text = "%d:%02d" % [floori(time / 60.0), time % 60]


func show_comeback(time: int) -> void:
	var comeback: Label = $Main/Comeback
	comeback.show()
	
	var countdown: int = time
	while countdown > 0:
		comeback.text = "Возвращение через %d..." % countdown
		await get_tree().create_timer(1.0, false).timeout
		countdown -= 1
	
	comeback.hide()
