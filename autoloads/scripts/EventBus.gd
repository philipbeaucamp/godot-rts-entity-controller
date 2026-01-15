@warning_ignore("UNUSED_SIGNAL")
extends Node

#Debug
signal debug_console_opened(value: bool)
signal debug_draw(value: bool)

#Nav
signal grid_ready(grid: SpatialHashArea)
signal navigation_obstacle_tree_exit(obstacle: NavigationObstacleComponent)

#Selection
signal select_control_group(index: int, selectables: Array[Selectable])
signal update_control_group(index: int, selectables : Array[Selectable], selection: Selection)

#camera
signal set_camera_boundary(area: Area3D, value: bool)
signal set_camera_start_position(start: Vector3)
signal pixel_resolution_changed(res: Vector2i)

#Entity
signal entity_ready(entity: Entity) #be careful, only called once, use enter tree to work with reparenting
signal entity_entered_tree(entity: Entity)
signal entity_exiting_tree(entity: Entity)
signal entity_screen_visible(entity: Entity, is_visible: bool)
signal entity_reparented(entity: Entity)

#Enemy/AI
signal squad_created(squad: Squad, is_waiting: bool)
signal squad_is_ready(squad: Squad)
signal squad_became_empty(squad: Squad)
signal threat_changed(defense: Defense)

#Abilities
signal click_ability_cast(click_ability: ClickAbility)
signal click_abilities_initiated(abilities: Array[ClickAbility])
signal click_abilities_terminated(abilities: Array[ClickAbility], cancelled: bool)
