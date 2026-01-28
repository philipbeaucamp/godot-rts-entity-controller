# Core Concepts

## Architecture Overview

The Godot RTS Entity Controller is built on a component-based architecture with an event-driven communication system.

### Component System

Units (also referred to as Entities) are composed of modular components that add specific behaviors:

- **Components** extend from a base `Component` class
- Each component handles a specific aspect of unit behavior (movement, health, selection, etc.)
- Components communicate via signals and the event bus
- Components can be mixed and matched to create different unit types

### Event Bus Pattern

The `RTS_EventBus` provides decoupled communication:

- Components emit events when things happen (unit selected, moved, damaged, etc.)
- Other systems listen for events without needing direct references
- Enables loose coupling and modularity

### Autoload System

Three core autoloads manage the overall system:

1. **RTS_EventBus** - Central event dispatcher
2. **RTSController** - Manages selected units and global state
3. **RTS_PlayerInput** - Handles input commands and translates them to gameplay actions

## Key Design Patterns

### 1. Component Pattern
Units are built from reusable, composable components rather than deep inheritance hierarchies.

### 2. Event-Driven Communication
Systems communicate through events rather than direct references, promoting loose coupling.

### 3. Separation of Concerns
- **Input layer** handles player commands
- **Selection layer** manages which units are selected
- **Command layer** translates selections into unit actions
- **Component layer** implements actual behaviors

### 4. Scene-Based
Everything is a Godot scene or node, making it familiar to Godot developers.

## Data Flow

```
Player Input
    ↓
RTS_PlayerInput (collects input to distribute)
    ↓
Selection/AbilityManager (interpret input)
    ↓
Components (implement logic)
    ↓
Visual/Audio Updates
```

Note that if one chooses, player input can be handled completely differently, for example when integrating with an existing player input system. All that's required is to send the required input data to Selection and AbilityManager to interpret the input.

## Entity Structure

A typical entity consists of:

```
Entity (RTS_Entity)
├── Components (RTS_Movable, RTS_Selectable, etc.)
├── Model (visual representation)
└── Sub-components (weapons, attachments, etc.)
```

Components are "composed into" units rather than units inheriting from them.

See [Entity System ](systems/entity.md) for details.

## Selection Model

- **Selection** is managed globally by the `RTSController`
- Units can be **selected** or **deselected**
- Multiple units can be selected simultaneously
- Selection groups be assign to hotkeys (1-9)
- Selection changes trigger events that other systems listen to

See [Selection System ](systems/selection.md) for details.

## Navigation & Movement

- Uses Godot's built-in `NavigationServer3D` for static pathfinding 
- `RTS_Movable` handles unit-specific movement logic, including separation, avoidance, etc
- Supports both individual movement and group movement

See [Movement & Navigation](systems/movement.md) for details.

## Combat & Abilities

- **Attacks** are handled by weapon components
- **Abilities** are special actions with cooldowns and effects
- Both use the event bus to communicate results

See [Combat System](systems/combat.md) for details.

## Performance Considerations

- **Spatial Hashing** optimizes spatial queries (finding nearby units)
- **Collision layers** help with efficient physics queries
- Components only process what they need each frame

See [Advanced Topics](advanced/spatial-hashing.md) for optimization details.
