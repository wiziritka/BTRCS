extends Control

signal save_requested

func _ready() -> void:
	var right: bool = Globals.get_controls_bool("shoot_area_right")
	($RightShootAreaHSplit as CanvasItem).visible = right
	($LeftShootAreaHSplit as CanvasItem).visible = not right
	
	if right:
		($RightShootAreaHSplit as SplitContainer).split_offset = \
				roundi(size.x - Globals.get_controls_vector2("shoot_area").x)
		($RightShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset = \
				roundi(Globals.get_controls_vector2("shoot_area").y)
	else:
		($LeftShootAreaHSplit as SplitContainer).split_offset = \
				roundi(Globals.get_controls_vector2("shoot_area").x)
		($LeftShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset = \
				roundi(Globals.get_controls_vector2("shoot_area").y)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST when visible:
			_on_quit_pressed()


func _on_quit_pressed() -> void:
	queue_free()


func _on_discard_pressed() -> void:
	propagate_call(&"_ready")


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_save_requested() -> void:
	var right: bool = ($RightShootAreaHSplit as CanvasItem).visible
	Globals.set_controls_bool("shoot_area_right", right)
	
	var shoot_area: Vector2
	if right:
		shoot_area = Vector2(int(size.x) - ($RightShootAreaHSplit as SplitContainer).split_offset,
				($RightShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset)
	else:
		shoot_area = Vector2(($LeftShootAreaHSplit as SplitContainer).split_offset,
				($LeftShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset)
	Globals.set_controls_vector2("shoot_area", shoot_area)


func _on_shoot_area_move_right_pressed() -> void:
	($LeftShootAreaHSplit as CanvasItem).hide()
	($RightShootAreaHSplit as CanvasItem).show()
	
	($RightShootAreaHSplit as SplitContainer).split_offset = \
			int(size.x) - ($LeftShootAreaHSplit as SplitContainer).split_offset
	($RightShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset = \
			($LeftShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset


func _on_shoot_area_move_left_pressed() -> void:
	($RightShootAreaHSplit as CanvasItem).hide()
	($LeftShootAreaHSplit as CanvasItem).show()
	
	($LeftShootAreaHSplit as SplitContainer).split_offset = \
			int(size.x) - ($RightShootAreaHSplit as SplitContainer).split_offset
	($LeftShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset = \
			($RightShootAreaHSplit/ShootAreaVSplit as SplitContainer).split_offset
