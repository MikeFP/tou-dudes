extends Node2D

export var world_columns = 13
export var generate_deconstructs = true
export var powerup_spawn_probability := 0.25
export var obstacle_spawn_probability := 0.5

export var borderShaderMaterial: ShaderMaterial
export var glowColor: Color

const CELL_WIDTH = 16

var TileType = Global.TileType

onready var tileMap: TileMap = $TileMap

var rng := RandomNumberGenerator.new()
var originalColor = Vector3(1.0, 1.0, 1.0)
var glowSpeed = 1.0
var transitionToWhite = false
var transition = 0
var powerups = []

var cellTypeIds = {
	TileType.DESTRUCTURE: -1,
	TileType.BOUNDS: -1,
	TileType.WALL: -1,
	TileType.GROUND: -1
}

var cellTypeIndexes = {}

var grid_map = {}

var destructure_scene = preload("res://scenes/destructure.tscn")

var powerup_data = [
	{
		"name": "ammo",
		"probability_weight": 1.0,
	},
	{
		"name": "hold",
		"probability_weight": 0.25,
	},
	{
		"name": "intensity",
		"probability_weight": 1.0,
	},
	{
		"name": "kick",
		"probability_weight": 0.5,
	},
	{
		"name": "punch",
		"probability_weight": 0.25,
	},
	{
		"name": "speed",
		"probability_weight": 0.75,
	},
]

func _ready():
	rng.randomize()
	
	powerups = get_tree().get_nodes_in_group("powerups")
	
	for id in tileMap.tile_set.get_tiles_ids():
		var tileName = tileMap.tile_set.tile_get_name(id)
		for type in cellTypeIds:
			if tileName.find(Global.enum_as_string(TileType, type).to_lower()) != -1:
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
	var destructRatio = obstacle_spawn_probability
	
	var n = world_columns
	var l = 0
	var c = 0
	
	var tileType = TileType.GROUND
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
	
	while l != n && c != n:
		
		tileType = TileType.WALL
		if l % 2 == 0 || c % 2 == 0:
			tileType = TileType.GROUND
			
		if generate_deconstructs && tileType == TileType.GROUND && !(Vector2(c, l) in blankSpaces):
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
			if type != TileType.GROUND:
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
	maybe_spawn_powerup(col, line)

func maybe_spawn_powerup(col: int, line: int):
	var should_spawn := rng.randf_range(0.0, 1.0) < powerup_spawn_probability

	if not should_spawn:
		return

	var powerup_options := []
	var weights := []
	for powerup in powerup_data:
		powerup_options.append(powerup)
		weights.append(powerup.probability_weight)

	var choice = Global.random_choice(powerup_options, weights)
	instance_powerup(col, line, choice.name)

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
	var c = int(col)
	var l = int(line)

	var new = false
	if !grid_map.has(c):
		grid_map[c] = {}
		new = true
	if !grid_map[c].has(l):
		grid_map[c][l] = []
		new = true
	
	if new:
		_check_tilemap_for_content(c, l)

	if !(content in grid_map[c][l]):
		grid_map[c][l].append(content)

func _check_tilemap_for_content(col, line):
	var tile = tileMap.get_cell(col, line)
	if tile != -1 and tile != cellTypeIds[TileType.GROUND]:
		for type in cellTypeIds:
			if cellTypeIds[type] == tile:
				register_cell_content(col, line, type)
				return [type]
	return []

func delete_cell_content(col, line, content):
	var c = int(col)
	var l = int(line)
	var index = get_cell_content(Vector2(c, l)).find(content)
	if index != -1:
		grid_map[c][l].remove(index)
		return true
	return false

func move_cell_content(content, to, from = null):
	if from != null:
		var items = get_cell_content(from)
		if content in items:
			delete_cell_content(from.x, from.y, content)
	register_cell_content(to.x, to.y, content)

func get_cell_content(grid_position):
	var col = int(grid_position.x)
	var line = int(grid_position.y)

	if grid_map.has(col) and grid_map[col].has(line):
		return grid_map[col][line]

	return _check_tilemap_for_content(col, line)

func map_to_world(map_pos):
	return tileMap.map_to_world(map_pos) + tileMap.position

func world_to_map(world_pos):
	return tileMap.world_to_map(world_pos - tileMap.position)

func is_out_of_bounds(grid_position: Vector2):
	var c = int(grid_position.x)
	var l = int(grid_position.y)

	var col_offset = 0
	var line_offset = 0

	if c < 0:
		col_offset = 1
	if c > world_columns:
		col_offset = -1
	if l < 0:
		line_offset = 1
	if l > world_columns:
		line_offset = -1

	var res = Vector2() + Vector2.RIGHT * col_offset + Vector2.DOWN * line_offset
	return res
