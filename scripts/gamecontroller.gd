extends Node2D

var destructure_scene = preload("res://scenes/destructure.tscn")

export var world_columns = 13
export var generate_deconstructs = true

export var borderShaderMaterial: ShaderMaterial
export var glowColor: Color

onready var tileMap: TileMap = $TileMap

var rng = RandomNumberGenerator.new()
var originalColor = Vector3(1.0, 1.0, 1.0)
var glowSpeed = 1.0
var transitionToWhite = false
var transition = 0
var powerups = []

var cellTypeIds = {
	"struct": -1,
	"bound": -1,
	"wall": -1,
	"ground": -1
}

var cellTypeIndexes = {}

var grid_map = {}

func _ready():
	rng.randomize()
	
	powerups = get_tree().get_nodes_in_group("powerups")
	
	for id in tileMap.tile_set.get_tiles_ids():
		var tileName = tileMap.tile_set.tile_get_name(id)
		for type in cellTypeIds:
			if tileName.find(type) != -1:
				cellTypeIds[type] = id
				break

	_generate_map()

func _process(delta):
	_process_shader(delta)

func _process_shader(delta):
	var shader = borderShaderMaterial

	transition += delta * glowSpeed
	
	var color = shader.get_shader_param("new_color")
	
	var currentColor = Vector3(color.r, color.g, color.b)
	
	var glowColorV = Vector3(glowColor.r, glowColor.g, glowColor.b)
	
	var targetColor = originalColor if transitionToWhite else glowColorV
	var originColor = glowColorV if transitionToWhite else originalColor

	currentColor = originColor.linear_interpolate(targetColor, transition)
	
	var newColor = Color(currentColor.x, currentColor.y, currentColor.z, 1.0)
	shader.set_shader_param("new_color", newColor)
	
	if transition >= 1.0:
		transition = 0
		transitionToWhite = not transitionToWhite

func _generate_map():
	var destructRatio = 0.65
	
	var n = world_columns
	var l = 0
	var c = 0
	
	var tileType = "ground"
	var tileMatrix = []
	var tileArray = []
	
	var blankSpaces = [
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, 1),
		
		Vector2(12, 0),
		Vector2(12, 1),
		Vector2(11, 0)
	]
	
	while l != n and c != n:
		
		tileType = "wall"
		if l % 2 == 0 or c % 2 == 0:
			tileType = "ground"
			
		if generate_deconstructs and tileType == "ground" and not (Vector2(c, l) in blankSpaces):
			if rng.randf() < destructRatio:
				instance_destructure(c + 1, l + 1)

		tileArray.append(tileType)
		
		c += 1
		if c == n:
			tileMatrix.append(tileArray)
			tileArray = []
			l += 1
			c = 0
	
	l = 1
	c = 1
	for line in tileMatrix:
		for type in line:
			tileMap.set_cell(c, l, cellTypeIds[type])
			if type != "ground":
				register_cell_content(c, l, type)
			c += 1
		l += 1
		c = 1

func instance_destructure(col, line):
	var destruct = destructure_scene.instance()
	tileMap.add_child(destruct)
	destruct.position = map_to_world(Vector2(col, line)) - tileMap.position
	destruct.connect("destroyed", self, "_destructure_destroyed", [col,line])
	register_cell_content(col, line, destruct)

func _destructure_destroyed(destructure, col, line):
	delete_cell_content(col, line, destructure)

func instance_powerup(col, line, powerup_name):
	var powerup = Provider.instance_powerup(powerup_name)
	add_child(powerup)
	powerup.position = map_to_world(Vector2(col, line))
	powerup.connect("taken", self, "_powerup_gone", [col, line])
	powerup.connect("destroyed", self, "_powerup_gone", [col, line])
	register_cell_content(col, line, powerup)

func _powerup_gone(powerup, col, line):
		delete_cell_content(col, line, powerup)

func register_cell_content(col, line, content):
	if !grid_map.has(col):
		grid_map[col] = {}
	if !grid_map[col].has(line):
		grid_map[col][line] = []
	grid_map[col][line].append(content)

func delete_cell_content(col, line, content):
	if grid_map.has(col) and grid_map[col].has(line):
		var index = grid_map[col][line].find(content)
		if index != -1:
			grid_map[col][line].remove(index)
			return true
	return false

func get_cell_content(col, line):
	if grid_map.has(col) and grid_map[col].has(line):
		return grid_map[col][line]

	var tile = tileMap.get_cell(col, line)
	if tile != -1 and tile != cellTypeIds["ground"]:
		for type in cellTypeIds:
			if cellTypeIds[type] == tile:
				register_cell_content(col, line, type)
				return [type]
	return []

func map_to_world(map_pos):
	return tileMap.map_to_world(map_pos) + tileMap.position

func world_to_map(world_pos):
	return tileMap.world_to_map(world_pos - tileMap.position)
