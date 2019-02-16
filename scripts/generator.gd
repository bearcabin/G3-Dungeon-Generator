#Port of https://bitbucket.org/signalsin/godot-dungeon-generator from Godot 2.1
extends Node

export var useViewportSize = false
export var dungeonSize = Vector2(256, 256)
export var numRoomTries = 20
export var extraConnectorChance = 20
export var roomExtraSize = 0
var rooms = []
var regions = []

var tileSize = 16

onready var map = get_node("../TileMap")
onready var worldSize = Vector2(get_viewport().size.x, get_viewport().size.y)

func _ready():
	randomize()
	generate()

func generate():
	regions = get_viewport().size
	if(!useViewportSize):
		regions = dungeonSize
		worldSize = dungeonSize
	
	populate_world()
	addrooms()
	add_corridors()
	set_tiles()

func populate_world():
	var x = 0
	var y = 0
	
	while x < worldSize.x / tileSize :
		while y < worldSize.y / tileSize:
			map.set_cell(x, y, 0)
			y += 1
			
		y = 0
		x += 1

func addrooms():
	var x = 0
	for room in range(numRoomTries):
		x = x + 1
		var size = (rand_range(1, (3 + roomExtraSize)) * 2 + 1) * tileSize
		var rectangularity = rand_range(0, 1 + size / 2) * 2;
		var width = size
		var height = size
		
		if randi() % 2 == 1:
			width += rectangularity
		else:
			height += rectangularity
		
		x = rand_range(0, (worldSize.x - width) / 2) * 2 + 1
		var y = rand_range(0, (worldSize.y - height) / 2) * 2 + 1
		
		room = Rect2(x, y, width, height)
		var overlaps = false
		
		for other in rooms:
			
			if room.intersects(other):
				overlaps = true
				break
		
		if overlaps:
			continue
		
		rooms.append(room)
	
	
	for room in rooms:
		carve_rect(room)

func add_corridors():
	
	var nextRoomIndex = 1
	
	for room in rooms:
		
		if nextRoomIndex > rooms.size():
			continue
		elif nextRoomIndex == rooms.size():
			nextRoomIndex = 0
		
		var nextRoom = rooms[nextRoomIndex]
		
		var curCentre = get_centre(room)
		var nextCentre = get_centre(nextRoom)
		
		add_horizontal_corridors(curCentre, Vector2(nextCentre.x, curCentre.y))
		add_vertical_corridors(Vector2(nextCentre.x, curCentre.y), nextCentre)
		
		nextRoomIndex += 1

func add_horizontal_corridors(startPos, endPos):
	var horizontal = Rect2()
	
	endPos.x = round_to_tile(endPos.x, tileSize)
	startPos.x = round_to_tile(startPos.x, tileSize)
	
	if startPos.x < endPos.x:
		horizontal = Rect2(startPos.x , startPos.y, endPos.x - startPos.x , tileSize)
	else:
		horizontal = Rect2(endPos.x, endPos.y, startPos.x - endPos.x, tileSize)
	carve_rect(horizontal)

func add_vertical_corridors(startPos, endPos):
	var vertical = Rect2()
	
	if startPos.y > endPos.y:
		endPos.y = round_to_tile(endPos.y, tileSize)
		startPos.y = round_to_tile(startPos.y, tileSize)
		vertical = Rect2(endPos.x, endPos.y, tileSize, startPos.y - endPos.y)
	else:
		vertical = Rect2(startPos.x, startPos.y, tileSize, endPos.y - startPos.y)
	
	carve_rect(vertical)

func set_tiles():
	var x = 0
	var y = 0
	
	while x < worldSize.x / tileSize:
		while y < worldSize.y / tileSize:
			if map.get_cell(x, y) >= 0:
				map.set_cell(x, y, get_tile_neighbours(x, y))
			y += 1
			
		y = 0
		x += 1

func carve_rect(rect):
	var rectMapPos = map.world_to_map(rect.position)
	var rectMapSize = map.world_to_map(rect.size)
	
	var x = rectMapPos.x
	var y = rectMapPos.y
	
	while x < (rectMapSize.x + rectMapPos.x) :
		while y < (rectMapSize.y + rectMapPos.y):
			map.set_cell(x, y, -1)
			y += 1
		y = rectMapPos.y
		x += 1

func get_centre(rect):
	var x = rect.position.x + (rect.size.x / 2)
	var y = rect.position.y + (rect.size.y / 2)
	
	return Vector2(x, y)

func round_to_tile(x, base):
    return int(base * ceil(float(x)/base))

func get_tile_neighbours(x, y):

	var sum = 0
	if map.get_cell(x, y - 1) >= 0:
		sum += 1
	if map.get_cell(x - 1, y) >= 0:
		sum += 2
	if map.get_cell(x, y + 1) >= 0:
		sum += 4
	if map.get_cell(x + 1, y) >= 0:
		sum += 8
	return sum
