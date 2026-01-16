@tool
extends EditorPlugin

const AUTOLOADS := [
	{
		"name": "Controls",
		"path": "res://addons/rts_entity_controller/autoloads/scenes/RTSController.tscn"
	},
	{
		"name": "RTSPlayerInput",
		"path": "res://addons/rts_entity_controller/autoloads/scenes/RTSPlayerInput.tscn"
	},
	{
		"name": "RTSEventBus",
		"path": "res://addons/rts_entity_controller/autoloads/scenes/RTSEventBus.tscn"
	}
]

# Add autoloads here.
func _enable_plugin() -> void:
	for entry in AUTOLOADS:
		var name: String = entry["name"]
		var path: String = entry["path"]
		if not Engine.has_singleton(name):
			print("RTS: Adding autoload: " + name + " at path: " + path)
			add_autoload_singleton(name,path)

#Remove autoloads here.
func _disable_plugin() -> void:
	for entry in AUTOLOADS:
		var name: String = entry["name"]
		var path: String = entry["path"]
		print("RTS: Removing autoload: " + name + " at path: " + path)
		remove_autoload_singleton(name)


# Initialization of the plugin goes here.
func _enter_tree() -> void:
	create_doc_button()
	install_inputmap_from_dict(INPUT_MAP, true)
	ProjectSettings.save()


# Clean-up of the plugin goes here.
func _exit_tree() -> void:
	destroy_doc_button()

var docs_button: Button

func create_doc_button():
	docs_button = Button.new()
	docs_button.text = "RTS RTS_Entity Controller Documentation"
	docs_button.icon = EditorInterface.get_base_control().get_theme_icon("Snap", "EditorIcons")
	docs_button.pressed.connect(_on_pressed)
	self.add_control_to_container(self.CONTAINER_TOOLBAR,docs_button)

func destroy_doc_button():
	remove_control_from_container(self.CONTAINER_TOOLBAR,docs_button)
	docs_button.free()	

func _on_pressed():
	print("todo opening docs")

func install_inputmap_from_dict(data: Dictionary, overwrite_deadzone: bool = false) -> void:

	for action_name_variant in data.keys():
		var action_name := StringName(str(action_name_variant))
		var action_def: Dictionary = data[action_name_variant]

		var deadzone := float(action_def.get("deadzone", 0.5))
		var events: Array = action_def.get("events", [])

		if action_name == "" || action_name == null:
			print("RTS Plugin: Skipping invalid InputMap action name: " + str(action_name))
			continue

		if ProjectSettings.has_setting("input/rts_" + str(action_name)):
			continue

		var input_events: Array[InputEvent] = []
		for ev_def_variant in events:
			if typeof(ev_def_variant) != TYPE_DICTIONARY:
				continue
			var ev_def: Dictionary = ev_def_variant

			var ie := _input_event_from_min_def(ev_def)
			if ie == null:
				print("RTS Plugin: Skipping invalid InputEvent definition for action: " + str(action_name))
				continue
			input_events.append(ie)

		ProjectSettings.set_setting("input/rts_" + str(action_name), {
			"deadzone": deadzone,
			"events": input_events
		})


func _input_event_from_min_def(d: Dictionary) -> InputEvent:
	var t := String(d.get("type", "")).to_lower()
	var device := int(d.get("device", -1))
	print("Creating InputEvent of type: " + t + " for device: " + str(device))
	match t:
		"key":
			var e := InputEventKey.new()
			e.device = device

			# Optional modifier flags if you ever include them
			e.alt_pressed = bool(d.get("alt_pressed", false))
			e.shift_pressed = bool(d.get("shift_pressed", false))
			e.ctrl_pressed = bool(d.get("ctrl_pressed", false))
			e.meta_pressed = bool(d.get("meta_pressed", false))

			# Prefer physical_keycode; fall back to keycode
			var pk := int(d.get("physical_keycode", 0))
			var kc := int(d.get("keycode", 0))
			if pk != 0:
				e.physical_keycode = pk
			if kc != 0:
				e.keycode = kc

			# Note: InputMap stores events regardless of "pressed"
			e.pressed = false
			return e

		"mouse_button":
			var e := InputEventMouseButton.new()
			e.device = device
			e.button_index = int(d.get("button_index", MOUSE_BUTTON_LEFT))
			e.pressed = false
			return e
		_:
			# Unknown event type
			printerr("RTS Plugin: Unknown InputEvent type in input map JSON: " + t)
			return null



const INPUT_MAP := {
  "shift": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 4194325 }
	]
  },
  "stop": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 83 }
	]
  },
  "patrol": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 81 }
	]
  },
  "attack": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 65 }
	]
  },
  "control": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 4194326 }
	]
  },
  "1": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 49 } ] },
  "2": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 50 } ] },
  "3": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 51 } ] },
  "4": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 52 } ] },
  "5": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 53 } ] },
  "6": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 54 } ] },
  "7": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 55 } ] },
  "8": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 56 } ] },
  "9": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 57 } ] },
  "0": { "deadzone": 0.5, "events": [ { "type": "key", "device": -1, "physical_keycode": 48 } ] },
  "escape": {
	"deadzone": 0.5,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 4194305 }
	]
  },
  "mouse_left": {
	"deadzone": 0.5,
	"events": [
	  { "type": "mouse_button", "device": -1, "button_index": 1 }
	]
  },
  "mouse_right": {
	"deadzone": 0.5,
	"events": [
	  { "type": "mouse_button", "device": -1, "button_index": 2 }
	]
  },
  "hold": {
	"deadzone": 0.2,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 72 }
	]
  },
  "debug": {
	"deadzone": 0.2,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 78 }
	]
  },
  "move": {
	"deadzone": 0.2,
	"events": [
	  { "type": "mouse_button", "device": -1, "button_index": 2 }
	]
  },
  "zoom_in": {
	"deadzone": 0.2,
	"events": [
	  { "type": "mouse_button", "device": -1, "button_index": 4 }
	]
  },
  "zoom_out": {
	"deadzone": 0.2,
	"events": [
	  { "type": "mouse_button", "device": -1, "button_index": 5 }
	]
  },
  "space": {
	"deadzone": 0.2,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 32 }
	]
  },
	"entity_debug_rotate_right": {
	"deadzone": 0.2,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 4194442 }
	]
  },
	"entity_debug_rotate_left": {
	"deadzone": 0.2,
	"events": [
	  { "type": "key", "device": -1, "physical_keycode": 4194444 }
	]
  },
}
