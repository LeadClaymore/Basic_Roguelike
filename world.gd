extends Node2D

@export var input_timeout := 100.0
var timeout_end := 0.0

enum Turn {P, W}
var CTurn: Turn = Turn.P

@onready var player: Node2D = $Player
@onready var player_pos: Vector2i = Vector2i(0, 0)

@onready var entity_parent: Node2D = $Entities
var entity_list: Dictionary[Vector2i, Node2D] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
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
	who.position = Vector2(where.x * 80, where.y * 80)
	who.grid_pos = where
	pass
