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
enum Tile {Y, N, U, Yb}
# for these (x, y, z): (x, y) is the tileset position, (z) is the tileSet sourceID
const T_Yes: Vector3i = Vector3i(1, 1, 0)
const T_Yes_b: Vector3i = Vector3i(0, 0, 1)
const T_No: Vector3i = Vector3i(1, 0, 0)
const T_Unk: Vector3i = Vector3i(4, 7, 0)
## 2D array of Tile enums
var tile_list: Array = []
# 9223372036854775807 is int max
var tile_min_bounds: Vector2i = Vector2i(9223372036854775807, 9223372036854775807)
var tile_max_bounds: Vector2i = Vector2i(-9223372036854775807, -9223372036854775807)

# Note on my testing, Dad got 100, I had 15ish when trying but should see if 30 or 50 work better
@export var input_delay: float = 50.0
var delay_end: float = 0.0
var curr_inputs: Dictionary[String, bool] = {}

const DIRECTIONS = [
	Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for ii in range(map_size):
		var map_slice: Array[Tile] = []
		for jj in range(map_size):
			if tile_min_bounds.x > ii:
				tile_min_bounds.x = ii
			elif tile_max_bounds.x < ii:
				tile_max_bounds.x = ii
			
			if tile_min_bounds.y > jj:
				tile_min_bounds.y = jj
			elif tile_max_bounds.y < jj:
				tile_max_bounds.y = jj
			
			if ii > 0 && ii < map_size - 1 && jj > 0 && jj < map_size - 1:
				if (ii + jj) % 2 == 0:
					map_slice.append(Tile.Y)
				else:
					map_slice.append(Tile.Yb)
			else:
				map_slice.append(Tile.N)
	
		tile_list.append(map_slice)
	_set_tileset()
	
	entity_list.set(player_curr_pos, player)
	player.position = Vector2(player_starting_pos.x * 8, player_starting_pos.y * 8)
	
	# TODO delete testing
	tile_list[6][6] = Tile.N
	print("y: %s, n: %s, u: %s, yb: %s"%[Tile.Y, Tile.N, Tile.U, Tile.Yb])
	for ii in range(tile_list.size()):
		print(tile_list[ii])
		
	print("_AStar start time %s"%[Time.get_ticks_usec()])
	print(_AStar(tile_list, Vector2i(1, 1), Vector2i(18, 18), false))
	print("_AStar start time %s"%[Time.get_ticks_usec()])
	# testing end
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# only 1 input every (input_timeout)
	if Time.get_ticks_msec() < timeout_end:
		return
	
	if curr_inputs && !delay_end:
		delay_end = Time.get_ticks_msec() + input_delay
		#print("Delay till <%s>"%[delay_end])
		return
	elif delay_end > Time.get_ticks_msec():
		return
	
	var dir: Vector2i = Vector2i.ZERO
	for ii in curr_inputs.keys():
		match ii:
			"up":
				dir += Vector2i(0, -1)
			"down":
				dir += Vector2i(0, 1)
			"left":
				dir += Vector2i(-1, 0)
			"right":
				dir += Vector2i(1, 0)
			"interact":
				pass
			_:
				pass
				
	if dir:
		curr_inputs.clear()
		delay_end = 0.0
		print("%s -> %s, <%s>" %[player_curr_pos, player_curr_pos + Vector2i(dir), Time.get_ticks_msec()])
		if !_move_to(player, player_curr_pos, player_curr_pos + Vector2i(dir)):
			# Something stoped the player from moving
			return
	
	# TODO Enemy turn

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("up"):
		curr_inputs.set("up", true)
	if event.is_action_pressed("down"):
		curr_inputs.set("down", true)
	if event.is_action_pressed("left"):
		curr_inputs.set("left", true)
	if event.is_action_pressed("right"):
		curr_inputs.set("right", true)
	if event.is_action_pressed("interact"):
		curr_inputs.set("interact", true)
	pass

func _move_to(who: Node2D, from: Vector2i, to: Vector2i) -> bool:
	#print(who.position)
	if to.x < tile_min_bounds.x || to.x > tile_max_bounds.x || to.y < tile_min_bounds.y || to.y > tile_max_bounds.y:
		push_error("%s is trying to move to %s, map_size is %d, min_bound = %s, max_bound = %s" %[who, to, map_size, tile_min_bounds, tile_max_bounds])
		return false
	
	if entity_list.has(to):
		push_warning("ran into a %s" %[entity_list.get(to)])
		# TODO handle attack
		return true
	
	match tile_list[to.x][to.y]:
		Tile.Y:
			pass
		Tile.Yb:
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
					tilemap.set_cell(Vector2i(ii, jj), T_Yes.z, Vector2i(T_Yes.x, T_Yes.y))
				Tile.N:
					tilemap.set_cell(Vector2i(ii, jj), T_No.z, Vector2i(T_No.x, T_No.y))
				Tile.U:
					tilemap.set_cell(Vector2i(ii, jj), T_Unk.z, Vector2i(T_Unk.x, T_Unk.y))
				Tile.Yb:
					tilemap.set_cell(Vector2i(ii, jj), T_Yes_b.z, Vector2i(T_Yes_b.x, T_Yes_b.y))
				_:
					tilemap.set_cell(Vector2i(ii, jj), T_Unk.z, Vector2i(T_Unk.x, T_Unk.y))

func _AStar(grid: Array, from: Vector2i, to: Vector2i, _debug = false) -> Array:
	# bound check
	if grid.size() == 0 || map_size < maxi(maxi(from.x, to.x), maxi(from.y, to.y)) || 0 > mini(mini(from.x, to.x), mini(from.y, to.y)):
		if _debug:
			print("invalid AStar with \nfrom %s \nto %s \ngrid %s"%[from,to,grid])
		return []
	if _debug:
		print("_AStar start time %s"%[Time.get_ticks_msec()])
	
	var open_set: Array = [from]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0}
	var f_score: Dictionary = {from: to.distance_to(from)}
	var closed_set: Dictionary = {}
	
	while open_set.size() > 0:
		var curr: Vector2i = open_set[0]
		var curr_ii = 0
		for ii in range(open_set.size()):
			var pos = open_set[ii]
			if f_score.get(pos, 9223372036854775807) < f_score.get(curr, 9223372036854775807):
				curr = pos
				curr_ii = ii
		
		if curr == to:
			var ret = [curr]
			while came_from.has(curr):
				curr = came_from[curr]
				ret.append(curr)
			ret.reverse()
			if _debug:
				print("_AStar start time %s"%[Time.get_ticks_msec()])
			return ret
		
		open_set.remove_at(curr_ii)
		closed_set[curr] = true
		
		for dir in DIRECTIONS:
			var neighbor = curr + dir
			if map_size < neighbor.x || map_size < neighbor.y || 0 > neighbor.x || 0 > neighbor.y:
				# is out of bounds
				continue
			if grid[neighbor.x][neighbor.y] != Tile.Y && grid[neighbor.x][neighbor.y] != Tile.Yb:
				# cant pass
				if _debug:
					print("tile %s at %s"%[grid[neighbor.x][neighbor.y], neighbor])
				continue
			if closed_set.has(neighbor):
				# allready counted
				continue
			
			var tentative_g = g_score.get(curr, 9223372036854775807) + 1
			
			if tentative_g < g_score.get(neighbor, 9223372036854775807):
				came_from[neighbor] = curr
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + to.distance_to(neighbor)
				
				if !open_set.has(neighbor):
					open_set.append(neighbor)
	if _debug:
		print("no path from %s to %s"%[from, to])
		print("_AStar start time %s"%[Time.get_ticks_msec()])
	return []
