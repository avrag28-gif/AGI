# Roblox Flight Simulator

Project reset for a serious Roblox flight simulator.

## Scope
- Real-aircraft-inspired systems architecture
- Fully stateful aircraft systems rather than decorative controls
- Cockpit controls wired to simulation state and instruments
- Flight physics, navigation, autopilot, radios, failures, ground operations and ATC planned as integrated systems
- Performance-conscious design for Roblox mobile and multiplayer

## First aircraft baseline
Boeing 737-800 / 737NG-style simulation architecture. Exact variant configuration will be locked before aircraft-specific implementation.

## Roblox installation
The repository contains source Lua/Luau and a bootstrap installer. The bootstrap is intended to generate the Roblox-side folder/module structure so the project can be installed without manually creating dozens of objects.

> This is a game simulation project, not certified aviation software or an official Boeing implementation.
