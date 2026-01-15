extends Node

var entity_resource_map: Dictionary[String,EntityResource] = {}
var entity_resource_map_short_id: Dictionary[String,EntityResource] = {}
var item_map: Dictionary[String,Item] = {}

const unit_path : String = "res://entities/units/"
const other_entities_path : String = "res://entities/other/"
const building_path: String = "res://entities/buildings/"
const items_path : String = "res://entities/"

#Scenes
const islands_path: String = "res://scenes/islands/"
var islands: Dictionary[StringName,StringName] = {} # id to path

#Resources
const levels_path: String = "res://core/levels/"
var levels: Array[LevelData] = []


var has_initalized: bool = false
func _enter_tree():
	initialize_db()

func initialize_db():
	if has_initalized:
		return
	cache_all_entities_at(unit_path)
	cache_all_entities_at(other_entities_path)
	cache_all_entities_at(building_path)
	cache_all_items()
	cache_all_levels()
	has_initalized = true

func cache_all_entities_at(path: String):
	var units = ResourceUtils.load_all_rousources_at(path,true)
	for unit in units:
		if unit is EntityResource:
			entity_resource_map[unit.id] = unit
			entity_resource_map_short_id[unit.short_id] = unit

func load_all_entities_at(path: String) -> Dictionary[StringName,EntityResource]:
	var entities : Dictionary[StringName,EntityResource] = {}
	var resources = ResourceUtils.load_all_rousources_at(path,true)
	for res in resources:
		if res is EntityResource:
			entities.set(res.id,res)
	return entities

func cache_all_items():
	var items = ResourceUtils.load_all_rousources_at(items_path,true)
	for item in items:
		if item is Item:
			item_map.set(item.id,item)

func cache_all_levels():
	var resources : Array[Resource] = ResourceUtils.load_resources_with_suffix_at(levels_path,true,[".tres"])
	for resource in resources:
		if resource  is LevelData:
			levels.append(resource)
	levels.sort_custom(func(a: LevelData, b: LevelData) -> bool:
		return a.index < b.index
	)

func get_all_entities() -> Array[EntityResource]:
	return entity_resource_map.values()
	
func get_entity_resource(id: StringName) -> EntityResource:
	return entity_resource_map.get(id)

func get_entity_resource_by_short_id(short_id: StringName) -> EntityResource:
	return entity_resource_map_short_id[short_id]

func get_all_items() -> Array[Item]:
	return item_map.values()

func get_item(id: StringName) -> Item:
	if item_map.has(id):
		return item_map[id]
	return null

func get_level_path(id: StringName) -> StringName:
	if islands.has(id):
		return islands[id]
	return ""
