extends Node2D
class_name DungeonTile

enum TileType {
	WALL,
	PATH
}

enum ObjectType {
	AGENT,
	POTION,
	ENEMY,
	CHEST,
	EXIT,
	KEY,
	GATE,
	EMPTY
}

@export var type := TileType.WALL
@export var contains := ObjectType.EMPTY

# Adicionamos "_scene" ao nome para não confundir com os nós instanciados
@export_group("Base Scenes")
@export var wall_scene: PackedScene
@export var path_scene: PackedScene

@export_group("Object Scenes")
@export var potion_scene: PackedScene
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var exit_scene: PackedScene
@export var chest_scene: PackedScene
@export var gate_scene :PackedScene
@export var key_scene :PackedScene

func _ready() -> void:
	setup_visual()

func setup_visual() -> void:
	# =========================
	# 1. INSTANCIAR A BASE
	# =========================
	var base_node: Node = null
	
	if type == TileType.WALL and wall_scene:
		base_node = wall_scene.instantiate()
	elif type == TileType.PATH and path_scene:
		base_node = path_scene.instantiate()
		
	if base_node:
		add_child(base_node)

	# =========================
	# 2. INSTANCIAR O OBJETO
	# =========================
	var object_node: Node = null
	
	match contains:
		ObjectType.AGENT:
			if player_scene: object_node = player_scene.instantiate()
		ObjectType.POTION:
			if potion_scene: object_node = potion_scene.instantiate()
		ObjectType.ENEMY:
			if enemy_scene: object_node = enemy_scene.instantiate()
		ObjectType.CHEST:
			if chest_scene: object_node = chest_scene.instantiate()
		ObjectType.EXIT:
			if exit_scene: object_node = exit_scene.instantiate()
		ObjectType.GATE:
			if gate_scene: object_node = gate_scene.instantiate()
		ObjectType.KEY:
			if key_scene: object_node = key_scene.instantiate()
	if object_node:
		add_child(object_node)
