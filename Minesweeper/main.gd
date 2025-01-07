extends Node2D

@export var tile_scene: PackedScene
var tile_size = 32
var screen_width = 600
var tile_start_width
var tile_start_height = 200

@export var small_size = 8
@export var medium_size = 13
@export var large_size = 18
@export var low_density = 0.15
@export var medium_density = 0.2
@export var high_density = 0.25

var size = "medium"
var density = "medium"

var num_bombs
var num_tiles

var tiles = Dictionary()
var num_revealed = 0
var num_correct_flagged = 0
var wrong_tile_flagged = false
var game_started = false


var density_options : OptionButton
var size_options : OptionButton
var start_button : Button
var options = []
var flagged_label : Label
var num_bombs_label : Label
# Called when the node enters the scene tree for the first time.
func _ready():
	density_options = $UI.get_node("Panel/DensityOptions")
	density_options.connect("item_selected", change_density)
	size_options = $UI.get_node("Panel/SizeOptions")
	size_options.connect("item_selected", change_size)
	start_button = $UI.get_node("Panel/StartButton")
	start_button.connect("pressed", start_game)
	options = [density_options, size_options, start_button]
	flagged_label = $UI.get_node("Panel/FlaggedLabel")
	num_bombs_label = $UI.get_node("Panel/NumBombsLabel")
	

func start_game():
	if game_started:
		return
	game_started = true
	start_button.hide()
	flagged_label.show()
	num_bombs_label.show()
	for element in options:
		element.disabled = true
	match size:
		"large":
			num_tiles = large_size
		"medium":
			num_tiles = medium_size
		"small":
			num_tiles = small_size
	tile_start_width = (screen_width - num_tiles*tile_size)/2
	match density:
		"high":
			num_bombs = high_density
		"medium":
			num_bombs = medium_density
		"low":
			num_bombs = low_density
	num_bombs = floor(num_tiles*num_tiles*num_bombs)
	num_bombs_label.text = "Number of Bombs: " + str(num_bombs)
	
	if tiles:
		for key in tiles:
			tiles[key].queue_free()
		tiles = Dictionary()
	create_tiles()
	

func change_density(new_density):
	match new_density:
		0: density="low"
		1: density="medium"
		2: density="high"
	density_options.release_focus()

func change_size(new_size):
	match new_size:
		0: size="small"
		1: size="medium"
		2: size="large"
	size_options.release_focus()


func _show_all_labels():
	for key in tiles:
		tiles[key]._show_value()
	
	
func create_tiles():
	for x in range(num_tiles):
		for y in range(num_tiles):
			var tile = tile_scene.instantiate()
			tile.pos_index = Vector2(x, y)
			tile.position = Vector2(x*tile_size, y*tile_size) + Vector2(tile_start_width, tile_start_height)
			add_child(tile)
			tiles[Vector2(x,y)] = tile
			tile.connect("explode", game_over)
			tile.connect("zero_revealed", reveal_neighboring_zeros)
			tile.connect("revealed", _tile_revealed)
			tile.connect("flagged_tile", _tile_flagged)
			



func populate_with_bombs(avoid_tiles):
	var cur_n_bombs = 0
	while cur_n_bombs < num_bombs:
		var bomb_pos = Vector2(randi_range(0, num_tiles-1), randi_range(0, num_tiles-1))
		var tile = tiles[bomb_pos]
		if tile.is_bomb or tile in avoid_tiles:
			continue
		tile.is_bomb = true
		cur_n_bombs += 1
		
		# Increase number for neighboring tiles
		for neighboring_tile in get_neighboring_tiles(bomb_pos):
			neighboring_tile.num_neighbors += 1


func reveal_neighboring_zeros(tile_pos_index):
	for tile in get_neighboring_tiles(tile_pos_index):
		if tile.is_bomb or tile.is_clicked:
			continue
		
		tile.is_clicked = true
		if tile.num_neighbors == 0:
			tile.zero_revealed.emit(tile.pos_index)
		

func get_neighboring_tiles(tile_index):
	var neighboring_tiles = []
	for x in range(-1,2):
			for y in range(-1,2):
				if x == 0 and y == 0:
					continue
				var neighbor_pos = tile_index + Vector2(x, y)
				if neighbor_pos.x < 0 or neighbor_pos.x >= num_tiles or neighbor_pos.y < 0 or neighbor_pos.y >= num_tiles:
					continue
				neighboring_tiles.append(tiles[neighbor_pos])
	return neighboring_tiles
	

func win():
	print("You win!")
	reset_game_state()


func game_over():
	print("You died!")
	reset_game_state()
	

func reset_game_state():
	reveal_bombs()
	
	start_button.show()
	for element in options:
		element.disabled = false
	num_flagged = 0
	num_revealed = 0
	num_correct_flagged = 0
	wrong_tile_flagged = false
	game_started = false
	
	
func reveal_bombs():
	for key in tiles:
		var tile = tiles[key]
		if tile.is_bomb:
			tile._show_value()

	
func _tile_revealed(tile_index):
	if num_revealed == 0:
		var avoid_tiles = get_neighboring_tiles(tile_index)
		avoid_tiles.append(tiles[tile_index])
		populate_with_bombs(avoid_tiles)
	num_revealed += 1
	if num_revealed == num_tiles*num_tiles - num_bombs:
		win()
		


var num_flagged = 0 : set = set_num_flagged

func set_num_flagged(new_num):
	num_flagged = new_num
	flagged_label.text = "Flagged Tiles: " + str(num_flagged)
	
func _tile_flagged(is_flagged):
	if is_flagged:
		num_flagged += 1
	else:
		num_flagged -= 1
	
	
	"""Thought it might be nice to win if you just flag all the bombs but
	then you can just try a bunch and google's minesweeper doesn't let
	you win that way"""
	#var tile = tiles[tile_index]
	#if tile.is_bomb:
		#num_correct_flagged += 1
		#if num_correct_flagged == num_bombs and not wrong_tile_flagged:
			#win()
	#else:
		#wrong_tile_flagged = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("debug"):
		_show_all_labels()
	elif Input.is_action_just_pressed("ui_accept"):
			start_game()
	elif Input.is_action_just_pressed("concede"):
		game_over()
