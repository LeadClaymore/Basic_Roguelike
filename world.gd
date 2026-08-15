extends Node2D

@export var input_timeout := 100.0
var timeout_end := 0.0

enum Turn {P, W}
var CTurn: Turn = Turn.P

@onready var player: Node2D = $Player
@onready var player_starting_pos: Vector2i = Vector2i(5, 5)
@onready var player_curr_pos: Vector2i = player_starting_pos

@onready var entity_parent: Node2D = $Entities
## Dictionary of Vector2i (Position) to Node2D (Entity that is there)
var entity_list: Dictionary[Vector2i, Node2D] = {}

@onready var tilemap: TileMapLayer = $TileMapLayer
## map size in x and y
@export var map_size: int = 100
## Y = passable, N = not passable, U = unknown
enum Tile {Y, N, U}
const T_Yes: Vector2i = Vector2i(1, 1)
const T_No: Vector2i = Vector2i(1, 0)
const T_Unk: Vector2i = Vector2i(4, 7)
## 2D array of Tile enums
var tile_list: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for ii in range(map_size):
		var map_slice: Array[Tile] = []
		for jj in range(map_size):
			if ii > 0 && ii < map_size - 1 && jj > 0 && jj < map_size - 1:
				map_slice.append(Tile.Y)
			else:
				map_slice.append(Tile.N)
	
		tile_list.append(map_slice)
	_set_tileset()
	
	entity_list.set(player_curr_pos, player)
	player.position = Vector2(player_starting_pos.x * 8, player_starting_pos.y * 8)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# only 1 input every (input_timeout)
	if Time.get_ticks_msec() < timeout_end:
		return
	
	var dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	if dir.length() == 0:
		#no input #TODO when interact is added this might need to change
		return
	
	timeout_end = Time.get_ticks_msec() + input_timeout
	
	#print("dir: %s" %[dir])
	if dir.x != 0 && dir.x > 0:
		dir.x = pow(dir.x, 0)
	elif dir.x != 0 && dir.x < 0:
		dir.x = -pow(dir.x, 0)
	
	if dir.y != 0 && dir.y > 0:
		dir.y = pow(dir.y, 0)
	elif dir.y != 0 && dir.y < 0:
		dir.y = -pow(dir.y, 0)
	
	print("%s -> %s" %[player_curr_pos, player_curr_pos + Vector2i(dir)])
	if !_move_to(player, player_curr_pos, player_curr_pos + Vector2i(dir)):
		# Something stoped the player from moving
		return
	
	# TODO Enemy turn
	
func _move_to(who: Node2D, from: Vector2i, to: Vector2i) -> bool:
	#print(who.position)
	if to.x < 0 || to.x > map_size || to.y < 0 || to.y > map_size:
		push_error("%s is trying to move to %s, map_size is %d" %[who, to, map_size])
		return false
	
	if entity_list.has(to):
		push_warning("ran into a %s" %[entity_list.get(to)])
		# TODO handle attack
		return true
	
	match tile_list[to.x][to.y]:
		Tile.Y:
			pass
		Tile.N:
			return false
		Tile.U:
			return false
		_:
			push_error("%s is trying to move into %s at %s, but I would have expected an error instead" %[who, tile_list[to.x][to.y], to])
			return false
	
	entity_list.erase(from)
	entity_list.set(to, who)
	who.position = Vector2(to.x * 8, to.y * 8)
	if who == player:
		player_curr_pos = to
	return true

func _set_tileset() -> void:
	for ii in range(tile_list.size()):
		for jj in range(tile_list[0].size()):
			match tile_list[ii][jj]:
				Tile.Y:
					tilemap.set_cell(Vector2i(ii, jj), 0, T_Yes)
				Tile.N:
					tilemap.set_cell(Vector2i(ii, jj), 0, T_No)
				Tile.U:
					tilemap.set_cell(Vector2i(ii, jj), 0, T_Unk)
				_:
					tilemap.set_cell(Vector2i(ii, jj), 0, T_Unk)
