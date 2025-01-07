extends Node2D
var is_bomb = false
signal explode
var is_flagged = false
var is_clicked = false : set = _activate
var num_neighbors : set = _set_num_neighbors
signal zero_revealed
signal revealed
var pos_index: Vector2
var original_color
signal flagged_tile

var colors = {1: "CYAN", 2: "LAWN_GREEN", 3: "RED"}


# Called when the node enters the scene tree for the first time.
func _ready():
	num_neighbors = 0
	original_color = $ColorRect.color


func _set_num_neighbors(num_n):
	num_neighbors = num_n
	if num_n == 0:
		return
	$Label.text = str(num_n)
	var color = colors.get(num_n, "YELLOW")
	$Label.label_settings.font_color = color
		

func _activate(clicked):
	if not is_clicked and clicked and not is_flagged:
		is_clicked = true
		if is_bomb:
			explode.emit()
			$ColorRect.color = "BLACK"
		else:
			revealed.emit(pos_index)
			if num_neighbors == 0:
				zero_revealed.emit(pos_index)
			$Label.show()
			$ColorRect.color = "SLATE_GRAY"
		

func _show_value():
	if is_bomb:
		$ColorRect.color = "BLACK"
		$Label.hide()
	else:
		$ColorRect.color = "SLATE_GRAY"
		$Label.show()


		
func toggle_mark():
	if is_clicked:
		return
		
	if is_flagged:
		is_flagged = false
		$ColorRect.color = original_color
	else:
		is_flagged = true
		$ColorRect.color = "FIREBRICK"
	flagged_tile.emit(is_flagged)
		

func _on_button_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:  # Left mouse button click
			is_clicked = true
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:  # Right mouse button click
			toggle_mark()
	pass # Replace with function body.
