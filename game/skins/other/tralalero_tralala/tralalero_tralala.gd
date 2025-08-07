extends PlayerSkin

@onready var _anim: AnimationPlayer = $AnimationPlayer

func _process(_delta: float) -> void:
	if player.get_real_velocity().is_zero_approx():
		if _anim.current_animation == &"walk":
			_anim.play(&"idle")
			_anim.speed_scale = 1.0
	else:
		if _anim.current_animation == &"idle":
			_anim.play(&"walk")
		_anim.speed_scale = player.get_real_velocity().length() / player.speed
