# Getting Started

## Installation

1. Clone the repository
2. Add the `godot-rts-entity-controller` folder into your project's `addons/` directory
3. Open your Godot project and navigate to **Project > Project Settings > Plugins**
4. Find the Godot RTS Entity Controller plugin and click **Enable**

## Basic Setup

### 1. Enable Required Autoloads

The addon requires several autoloads to function. These should be automatically added during plugin initialization:

- **RTSController** - Main scene handling camera & unit controls
- **RTSPlayerInput** - Handles player input and commands
- **RTSEventBus** - Central event system

Check **Project > Project Settings > Autoload** to verify they're present.

### 2. Verify RTS Settings

Make yourself familiar with the global settings found at rts_settings.tres, such as collision layer, input and debugging settings. Adjust collision layers if they are conflicting with your existing project.

### 3. Create Your First Unit

Create a scene with the following structure:

```
Unit (Node3D)
├── Model (Node3D or MeshInstance3D)
├── SelectableComponent
├── MovableComponent
├── HealthComponent
└── (other components as needed)
```

Check **ExampleUnit.tscn** for a minimally, but fully setup up unit. For more details on the unit & component setup check the [Component](components/overview.md) section.

### 4. Set Up a Basic Level

Create a level scene with:

```
Level (Node3D)
├── NavigationRegion3D (with NavMesh for pathfinding)
├── Ground/Terrain
├── Units (instantiate your unit scenes)
├── PhysicsCatchLayer
├── SpatialHashArea
└── CameraBoundaryAndPosition (if using Camera bounds)
```

Check **ExampleScene.tscn** for a demonstration of a ready to play scene!

## Next Steps

- Read [Core Concepts](core-concepts.md) to understand the architecture
- Explore [Components](components/overview.md) to build your units
- Check out the [examples](../examples/) folder in the addon for reference implementations
