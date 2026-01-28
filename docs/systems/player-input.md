# Player Input System

The Player Input System translates raw player input into game commands like unit selection, movement, and camera control.

## Overview

The `RTSPlayerInput` autoload collects input pertaining to:

- **Unit Selection** - Click to select, drag to box select
- **Movement Commands** - Right-click to move selected units
- **Ability Activation** - Keyboard shortcuts for unit abilities
- **Camera Control** - Pan, rotate, and zoom the camera
- **Event Generation** - Emits events for other systems to handle

All input actions should automatically be added to the Input Map in Godot when enabling the plugin.

**Remark**:
There seems to be a Godot bug where the added input actions don't immediately show up. Try manually adding a new input action or restarting the editor for the actions to show up.

## Basic Usage

As long as the PlayerInput is loaded (as Autoload or included somewhere else in the scene), all input should be distributed to the respective systems. One can choose to customize or overwrite the provided PlayerInput by disabling the Autoload and collecting input oneself. Just make sure the required input (found in PlayerInput) is distributed to the required components; Selection and AbilityManager.

## Selection

### Single Selection

- **Left Click** on a unit to select it
- Previous selection is deselected

### Multiple Selection (Box Select)

- **Left Click + Drag** to create a selection box
- All units within the box are selected
- Adds to current selection if holding **Shift**
- Clears previous selection otherwise

## Movement Commands

### Move Selected Units

- **Right Click** on a destination point
- All selected units will move to that location
- Uses pathfinding for intelligent navigation

### Chain Move

- While holding **Ctrl** it is possible to chain multiple movement targets
- This logic is not limited to movement, but is a general trait of the Ability Component

## Camera Control

### Pan
- Move Mouse to the edge of the screen

### Zoom

- **Mouse Wheel** up/down
- Adjusts camera distance from focus point
- Respects min/max zoom constraints

## Raycasting & Targeting

The input system uses raycasting to determine:

- Which unit was clicked (Layer Selection)
- Where movement commands should send units (Layer Selection/Navigation)
- Whether the click hit the ground or an object (Layer Selection/Navigation)

Configure layers and masks in your rst_settings.tres and project settings for proper raycasting behavior.

## See Also

- [Core Concepts](../core-concepts.md) - System overview
- [Selection System](selection.md) - Detailed selection logic
- [Movement & Navigation](movement.md) - How units move
