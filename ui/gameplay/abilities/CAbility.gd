extends BlockingControl

class_name CAbility

@export var resource: AbilityResource
@export var button: Button
@export var progress_bar: ProgressBar
@export var ap_label: Label
@export var texture_rect: TextureRect
@export var user_count: Label

@export var color_overlay_normal: Color = Color.WHITE
@export var color_overlay_cant_activate: Color = Color.WHITE
@export var color_rect_overlay: ColorRect
@export var description: CAbilityDescription

var abilities : Array[Ability] # All Selected Instances of this AbilityResources

#todo refactor this: next should not be compute here in the view, but in the abilitymanager each frame,
#this view should only react to next ability changes

var next: Ability #Next one to be activated

var revert_timer : SceneTreeTimer
var container: CAbilityContainer

func set_up(_abilities: Array):
	resource = _abilities[0].resource
	abilities = _abilities
	next = abilities[0]
	determine_next()
	if resource.is_common || next.ability_container || _abilities.size() <= 1:
		user_count.visible = false
	else:
		user_count.text = str(_abilities.size())
		
	description.set_up(resource)

# func set_ability_container(_container: CAbilityContainer):
# 	container = _container

func _ready():
	super._ready()
	progress_bar.visible = false
	if !resource.display_ap:
		ap_label.visible = false
	
	#Set up manual button clicking
	button.pressed.connect(on_pressed)
	
	var hover_stylebox = button.get_theme_stylebox("hover")
	if hover_stylebox is StyleBoxTexture:
		hover_stylebox.texture = resource.icon_hover
	
	var pressed_stylebox = button.get_theme_stylebox("pressed")
	if pressed_stylebox is StyleBoxTexture:
		pressed_stylebox.texture = resource.icon_pressed

	var normal_stylebox = button.get_theme_stylebox("normal")
	if normal_stylebox is StyleBoxTexture:
		normal_stylebox.texture = resource.icon_normal
		
	if resource.background:
		texture_rect.texture = resource.background

	Controls.ability_manager.abilities_activated.connect(on_abilities_activated)
	RTSEventBus.click_ability_cast.connect(on_click_ability_cast)
	if resource is ClickAbilityResource:
		RTSEventBus.click_abilities_initiated.connect(on_click_abilities_initiated)
		RTSEventBus.click_abilities_terminated.connect(on_click_abilities_terminated)

	# tree_exiting.connect(on_tree_exiting)
	
	
# Displays the ability with shortest cooldown out of an array of same type abilities
func determine_next():
	var shortest_cooldown: float = INF
	for a in abilities:
		if a._ap <= 0:
			continue
		if a.cooldown_timer == null:
			next = a
			break
		if a.cooldown_timer.time_left < shortest_cooldown:
			next = a
			shortest_cooldown = a.cooldown_timer.time_left
	
	#update ap display
	if resource.display_ap:
		ap_label.text = str(next._ap)

func _process(_delta):
	if next:
		if next.cooldown_timer != null:
			var time_left :float = next.cooldown_timer.time_left
			if time_left > 0:
				progress_bar.visible = true
				progress_bar.value = next.cooldown_timer.time_left/next.resource.cooldown_duration
		else:
			progress_bar.visible = false
		
		if next.can_be_activated():
			color_rect_overlay.color = color_overlay_normal
		else:
			color_rect_overlay.color = color_overlay_cant_activate
	else:
		progress_bar.visible = false
	
func on_click_abilities_initiated(_abilities: Array[ClickAbility]):
	if resource == _abilities[0].resource:
		button.set_pressed(true)

func on_click_abilities_terminated(_abilities: Array[ClickAbility],_cancelled: bool):
	if resource == _abilities[0].resource:
		button.set_pressed(false)

#always same type
func on_abilities_activated(_abilities: Array):
	var rep = _abilities[0]
	if rep.resource != resource:
		return
	if resource is ClickAbilityResource:
		button.set_pressed(false)
	else:
		button.set_pressed(true)
		if revert_timer != null && revert_timer.time_left > 0:
			revert_timer.timeout.disconnect(on_revert_timeout)
		revert_timer = get_tree().create_timer(0.05)
		revert_timer.timeout.connect(on_revert_timeout)
	determine_next()
	
func on_click_ability_cast(_click_ability: ClickAbility):
	pass #todo

func on_revert_timeout():
	button.set_pressed(false)
	
func on_pressed():
	if next:
		var event := InputEventAction.new()
		event.action = next.resource.id
		event.pressed = true
		Input.parse_input_event(event)

		await get_tree().process_frame

		var release := InputEventAction.new()
		release.action = next.resource.id
		release.pressed = false
		Input.parse_input_event(release)

# func on_tree_exiting():
# 	if container:
# 		container.remove_ability(self)
