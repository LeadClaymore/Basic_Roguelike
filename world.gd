extends Node2D

@export var input_timeout := 100.0
var timeout_end := 0.0

enum Turn {P, W}
var CTurn: Turn = Turn.P

@onready var player: Node2D = $Player
@onready var player_pos: Vector2i = Vector2i(0, 0)

@onready var entity_parent: Node2D = $Entities
var entity_list: Dictionary[Vector2i, Node2D] = {}

@onready var tilemap: TileMapLayer = $TileMapLayer
## map size in x and y
@export var map_size: int = 10
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
			if ii < 3:
				map_slice.append(Tile.Y)
			else:
				map_slice.append(Tile.U)
			
		tile_list.append(map_slice)
	_set_tileset()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# only 1 input every (input_timeout)
	if Time.get_ticks_msec() < timeout_end:
		return
	
	var dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	#print("dir: %s" %[dir])
	if dir.x != 0 && dir.x > 0:
		dir.x = pow(dir.x, 0)
	elif dir.x != 0 && dir.x < 0:
		dir.x = -pow(dir.x, 0)
	
	if dir.y != 0 && dir.y > 0:
		dir.y = pow(dir.y, 0)
	elif dir.y != 0 && dir.y < 0:
		dir.y = -pow(dir.y, 0)
	
	_move_to(player, player.grid_pos + Vector2i(dir))
	
	timeout_end = Time.get_ticks_msec() + input_timeout
	
	# Enemy turn
	# move enemies
	CTurn = Turn.P
	
func _move_to(who: Node2D, where: Vector2i) -> void:
	#print(who.position)
	who.position = Vector2(where.x * 8, where.y * 8)
	who.grid_pos = where
	pass

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
