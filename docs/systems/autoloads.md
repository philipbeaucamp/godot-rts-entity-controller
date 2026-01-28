# Autoloads Overview

The Godot RTS Entity Controller uses three main autoloads to manage the entire system. These are automatically initialized when the plugin is enabled.

## RTS_EventBus

**Purpose**: Central event dispatcher for events to avoid tight component coupling

## RTSController

**Purpose**: Loading essential RTS components that glue everything together

This scene is not mandatory, but it included for ease of use and demonstration purposes. You could customize the scene or split this into separate scenes to your likings, as long as all the essential components, such as the Camera Rig, Movement or Selection sripts are provided.

Perhaps most likely you would want to change the UI. In that case you could duplicate this scene and simply take out the CanvasLayer.

**Remark**: In case you do decide to change this scene (or use your own) just make sure the scripts found on the RTSController node are still accessible via ``RTS_Controls.`` for the scripts to work (since many scripts access them using the `Controls` autloaded script)

**Overview**:

- RTSController: Holds references to the scripts and managers for easy referencing
- Selection: Handles selection of entities
- PhysicsSelection: Handles non-box-selection, i.e. Raycast (click) selection of entities
- Movement: Handles group movement and patrol logic of entities
- Paths: Adds/Removes visible paths and target points for entity movement
- AbilityManager: Interprets player input and activates abilities on selected units
- MainRig: Handles camera movement
- MainCamera: Handles Raycasting/Projection logic
- CanvasLayer: Simple UI Layer
- PoolManager: Simple implementation of pooling logic for paths and waypoints
- Geometry: GeometryUtilies
- Time: Time related functionality

## RTS_PlayerInput

**Purpose**: Handles player input and and distributes it to the respective systems. See [PlayerInputSystem](player-input.md)


