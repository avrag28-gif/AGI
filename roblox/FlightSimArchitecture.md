# FlightSim Architecture

## Purpose

This document is the engineering contract for the Roblox Flight Simulator. The project is intended to grow into a multiplayer-capable aircraft simulation, not an arcade controller.

## Design rules

1. Server authority: aircraft/system state is authoritative on the server. Clients request actions and render the resulting state.
2. One aircraft, one state: state must belong to an aircraft instance. Never keep the live aircraft state as one global singleton once aircraft instances exist.
3. Systems are modular: electrical, fuel, engines, hydraulics, flight controls, landing gear/brakes, avionics, navigation, MCP/VNAV, autopilot/autothrottle, environmental systems, failures and aircraft physics are separate systems.
4. Data first: cockpit controls do not directly change physics. They issue commands; a system validates the command, changes state, and produces effects/telemetry.
5. Units are explicit: internal values must document their units. Avoid mixing Roblox studs, SI units, knots, feet and pounds without conversion at a boundary.
6. Fixed simulation step: simulation systems should run from a controlled tick rather than depending on render frequency.
7. Presentation is downstream: cockpit animation, gauges, sounds and UI read state; they do not own authoritative simulation state.
8. Validation belongs on the server: range checks, ownership/seat checks, system interlocks and command rate limits are server-side.
9. Failure-ready: each system should expose normal operation and failure/degraded states so failures can later be injected without rewriting the whole aircraft.
10. Testable: important system transitions should be deterministic enough to test without a 3D cockpit.

## Target runtime layout

```text
ReplicatedStorage
└── FlightSim
    ├── Shared
    │   ├── Config
    │   ├── Units
    │   ├── Types
    │   └── StateSchema
    └── Remotes
        ├── AircraftCommand
        └── Telemetry

ServerScriptService
└── FlightSim
    ├── Main.server.lua
    ├── Simulation.lua
    ├── AircraftRegistry.lua
    ├── CommandRouter.lua
    └── Systems
        ├── Electrical.lua
        ├── Fuel.lua
        ├── Engine.lua
        ├── Hydraulic.lua
        ├── FlightControls.lua
        ├── LandingGear.lua
        ├── Brakes.lua
        ├── Avionics.lua
        ├── NAVReceiver.lua
        ├── Navigation.lua
        ├── VNAV.lua
        ├── MCP.v02.lua
        ├── Autopilot.lua
        ├── AutoThrottle.lua
        ├── Environment.lua
        └── Failures.lua

StarterPlayer
└── StarterPlayerScripts
    └── FlightSimClient.client.lua
```

## System dependency direction

```text
Cockpit / Client
      |
      v
CommandRouter
      |
      v
 Aircraft State <---- Systems
      |                 |
      |                 +-- Electrical
      |                 +-- Fuel
      |                 +-- Engines
      |                 +-- Hydraulics
      |                 +-- Flight Controls
      |                 +-- Gear/Brakes
      |                 +-- Avionics
      |                 +-- NAV Receivers
      |                 +-- Navigation / FMC / VOR / ILS
      |                 +-- MCP / VNAV
      |                 +-- Autopilot / Autothrottle
      |                 +-- Environment
      |                 +-- Failures
      |                 +-- Aerodynamic / ground physics
      v
 Telemetry Snapshot
      |
      v
 Client / Cockpit / Instruments
```

## Guidance ownership

MCP stores pilot-selected targets and modes. Navigation, VNAV and raw radio/ILS producers calculate guidance inputs. Autopilot consumes those inputs and produces flight-control commands. Autothrottle consumes selected/VNAV speed targets and produces engine throttle commands. No presentation module should overwrite computed guidance state.

The go-around chain is explicitly command-driven: cockpit `GoAround` → server command validation → autopilot go-around guidance + autothrottle TOGA state → engine thrust/flight-control response → telemetry. The implementation is a game-simulation approximation, not certified Boeing logic.

## Engine-out integration

Engine failures are server-authoritative. A failed engine loses running state/thrust, while the physics layer integrates the resulting left/right thrust asymmetry into a yaw moment and exposes `EngineIntegration` telemetry. This keeps engine failure effects downstream of the engine system rather than embedding failure logic inside the cockpit.

## Electrical source priority

The electrical system must model source availability rather than treating Battery/APU/engine generators as equivalent booleans.

A source is available only when its prerequisites are satisfied. Engine generator availability depends on a stable running engine. APU generator availability depends on a running/stable APU. External power is an independent ground source.

The exact 737 behavior will be implemented progressively from public aircraft-system knowledge; this project is not official Boeing software and is not intended for real-world flight use.

## Migration rule

The current `FlightSimBootstrap.server.lua` is a development installer for the prototype. It must not be treated as the final production architecture. New systems should be written as real source files first, then wired into the runtime. The bootstrap can be updated as an installer during the migration, but it must not become a dumping ground for the entire simulator.

## Current phase

Core flight-management foundation: MCP/VNAV guidance, ILS/VOR receiver ownership, autopilot, autothrottle/TOGA, engine-out asymmetric-thrust integration, and deterministic subsystem contract tests are wired into the modular runtime. Remaining work continues upward into full cockpit hardware, aircraft/airport content, ATC, weather, failures and multiplayer/optimization passes.
