# Godot RTS Entity Controller Documentation

Welcome to the Godot RTS Entity Controller addon documentation. This addon is a comprehensive toolkit for building Real-Time Strategy (RTS) games in Godot and includes ready to use components for **selecting, moving, attack units or buildings and casting abilities**.

The play and feel of these components (especially the movement and combat system) is **heavily inspired by Starcraft 2**, which should make people familiar with it feel right at home. This means you will find all the basic controlling blocks, such as moving, patrolling, move-attacking or casting abilities for units (or buildings) that you are used from Starcraft 2.

As a result one of the highlights of this addon is the responsive control over units, best suited for RTS or RTT games with unit counts in the tens or low hundreds. The systems in this addon were not developed for armies of thousands of units, but rather **optimized for a high degree of control, modularity and customization** over the behaviours of units.


## Quick Start

New to the addon? Start here:

1. [Getting Started](getting-started.md) - Installation and basic setup
2. [Core Concepts](core-concepts.md) - Understand the architecture

## Documentation Structure

### Systems & Features
- [Player Input System](systems/player-input.md) - Selection, movement commands, and camera control
- [Entities](systems/entity.md) - Creating entities using building blocks
- [Selection System](systems/selection.md) - Unit selection and group management
- [Movement & Navigation](systems/movement.md) - Unit pathfinding and movement
- [Abilities System](systems/abilities.md) - Creating and using custom abilities
- [Combat System](systems/combat.md) - Auto targeting, weapon and combat systems
- [Autoloads](systems/autoloads.md) - Controller and utility logic

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
