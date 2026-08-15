extends Node2D

var playerFile := "user://PlayerFile.json"

#var grid_pos: Vector2i = Vector2i(0, 0)
var p_mhp: float = 100.0
var p_hp: float = p_mhp
var p_gp: int = 100
var p_inv: Array = ["one", "two"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !FileAccess.file_exists(playerFile):
		push_error("File [%s] does not exist" % playerFile)
	else:
		var file := FileAccess.open(playerFile, FileAccess.READ)
		var content := file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) != OK:
			push_error("file [%s] is corrupted")
		else:
			var data = json.data
			print("access data:")
			print(data)
			p_mhp = data.get("mhp", 99)
			p_hp = data.get("hp", 50)
			p_gp = data.get("gp", 200)
			p_inv = data.get("inv", [])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _exit_tree() -> void:
	var data := {
		"mhp": p_mhp,
		"hp": p_hp,
		"gp": p_gp,
		"inv": p_inv
	}
	print("exit data: ")
	print(data)
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(playerFile, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to open file [%s]" % playerFile)
	
