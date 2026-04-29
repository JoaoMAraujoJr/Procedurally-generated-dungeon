extends Node
signal potion_picked
signal chest_collected
signal monster_collide
signal door_entered
signal died

@export var cur_life : int = 2
var potions :int = 0 
var lvl_monster_num :int =0
var monsters :int = 0
var chests :int = 0
var level :int= 1
var cur_keys :int = 0
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	potion_picked.connect(_potion_picked)
	door_entered.connect(_door_entered)
	died.connect(_die)
	monster_collide.connect(_monster_collide)
	chest_collected.connect(_chest_collected)
	
func _chest_collected():
	chests+=1
	
func _potion_picked():
	potions+=1
	if cur_life <2:
		cur_life+=1
	return potions
func  _monster_collide():
	cur_life -=1
	if cur_life <= 0:
		print("died")
		died.emit()
	monsters +=1
func _die():
	level = 0
	cur_life= 2
	monsters=0
	lvl_monster_num = 0
	chests=0
	potions=0
	cur_keys = 0
	get_tree().reload_current_scene()
func _door_entered():
	level += 1
	cur_life= 2
	monsters=0
	lvl_monster_num = 0
	potions=0
	cur_keys= 0
	get_tree().reload_current_scene()
