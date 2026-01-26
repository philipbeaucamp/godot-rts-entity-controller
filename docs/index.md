# Godot RTS Entity Controller Documentation

Welcome to the Godot RTS Entity Controller addon documentation. This addon provides a comprehensive toolkit for building Real-Time Strategy (RTS) games in Godot, with systems for unit selection, movement, combat, and more.

## Quick Start

New to the addon? Start here:

1. [Getting Started](getting-started.md) - Installation and basic setup
2. [Core Concepts](core-concepts.md) - Understand the architecture

## Documentation Structure

### Systems & Features
- [Player Input System](player-input.md) - Selection, movement commands, and camera control
- [Entities](systems/entity.md) - Creating entities using building blocks
- [Selection System](systems/selection.md) - Unit selection and group management
- [Movement & Navigation](systems/movement.md) - Unit pathfinding and movement
- [Abilities System](advanced/abilities.md) - Creating custom abilities
- [Combat System](systems/combat.md) - Targeting, abilities, and attacks
- [Autoloads](systems/autoloads.md) - Event bus, controller, and utilities

### Components Deep Dive
- [Component Overview](components/overview.md) - Component system overview
- [Selectable Component](components/selectable.md) - Making units selectable
- [Movable Component](components/movable.md) - Movement capabilities
- [Health Component](components/health.md) - Health and damage
- [Defense Component](components/defense.md) - Defense and damage reduction
- [Attack Component](components/attack.md) - Attacking and weapons
- [Visual Component](components/visual.md) - Pivots and visuals

### Advanced Topics
- [Spatial Hashing](advanced/spatial-hashing.md) - Performance optimization

### Reference
- [Best Practices](reference/best-practices.md) - Tips and patterns
- [Troubleshooting](reference/troubleshooting.md) - Common issues and solutions

## Features

- **Selection System** - Select individual or multiple units with box selection
- **Movement & Navigation** - Pathfinding and group movement
- **Combat** - Attack systems, abilities, and damage
- **Animation** - AnimationTree integration for smooth animations
- **Events** - Decoupled communication via event bus
- **Performance** - Spatial hashing for efficient queries
- **Extensible** - Component-based architecture for easy customization

## Downloadable Content

- **Godot Addon**: All scripts, basic unit templates, and essential assets are included free in the open source project on [Github](https://github.com/philipbeaucamp/godot-rts-entity-controller)
- **Free Demo**: A free Executable demonstrating more advanced units and abilities can be found on [itcho.io](https://philipbeaucamp.itch.io/godot-rts-entity-controller)
- **Example Project** (Paid): A example project containing more advanced units and abilities, as well as assets, can be found on  [itcho.io](https://philipbeaucamp.itch.io/godot-rts-entity-controller)

## Support

For issues, questions, or suggestions, please refer to the [Troubleshooting](reference/troubleshooting.md) section or check the repository issues.
