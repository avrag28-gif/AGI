# FlightSim Architecture

## Purpose

This document is the engineering contract for the Roblox Flight Simulator. The project is intended to grow into a multiplayer-capable aircraft simulation, not an arcade controller.

## Design rules

1. Server authority: aircraft/system state is authoritative on the server. Clients request actions and render the resulting state.
2. One aircraft, one state: state belongs to an aircraft instance.
3. Systems are modular: electrical, fuel, engines, hydraulics, flight controls, landing gear/brakes, avionics, navigation, MCP/VNAV, autopilot/autothrottle, ATC, environmental systems, failures and aircraft physics are separate systems.
4. Data first: cockpit controls issue commands; systems validate commands and change authoritative state.
5. Units are explicit: internal values document their units and conversions happen at boundaries.
6. Fixed simulation step: simulation systems run from a controlled tick rather than render frequency.
7. Presentation is downstream: cockpit animation, gauges, sounds and UI read state only.
8. Server validation: range, ownership/seat, interlocks and rate limits are server-side.
9. Failure-ready: systems expose normal and degraded states.
10. Testable: important transitions are deterministic enough to test without a 3D cockpit.

## Target runtime layout

```text
ReplicatedStorage/FlightSim
├── Shared
│   ├── Config
│   ├── Units
│   ├── Types
│   └── StateSchema
└── Remotes
    ├── AircraftCommand
    └── Telemetry

ServerScriptService/FlightSim
├── FlightSimRuntime.server.lua
└── FlightSimSystems
    ├── AircraftRegistry.lua
    ├── CommandRouter.lua
    ├── Electrical.lua
    ├── Fuel.lua
    ├── Engine.lua
    ├── Hydraulic.lua
    ├── FlightControls.lua
    ├── LandingGear.lua
    ├── Brakes.lua
    ├── Avionics.lua
    ├── Radio.lua
    ├── Transponder.lua
    ├── NAVReceiver.lua
    ├── Navigation.lua
    ├── VNAV.lua
    ├── MCP.v02.lua
    ├── Autopilot.lua
    ├── AutoThrottle.lua
    ├── ATC.lua
    ├── Approach.lua
    ├── VOR.lua
    ├── Failures.lua
    └── Physics.lua
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
      |                 +-- Electrical / Fuel / Engines / Hydraulics
      |                 +-- Flight Controls / Gear / Brakes
      |                 +-- Avionics / Radios / Transponder
      |                 +-- Navigation / FMC / VOR / ILS
      |                 +-- MCP / VNAV / Autopilot / Autothrottle
      |                 +-- ATC
      |                 +-- Environment / Failures
      |                 +-- Aerodynamic / ground physics
      v
Telemetry Snapshot
      |
      v
Client / Cockpit / Instruments
```

## Guidance ownership

MCP stores pilot-selected targets and modes. Navigation, VNAV and raw radio/ILS producers calculate guidance inputs. Autopilot consumes those inputs and produces flight-control commands. Autothrottle consumes selected/VNAV speed targets and produces engine throttle commands. Presentation modules do not overwrite computed guidance state.

The go-around chain is command-driven: cockpit `GoAround` → server validation → autopilot go-around guidance + autothrottle TOGA → engine/flight-control response → telemetry. This is a game-simulation approximation, not certified Boeing logic.

## ATC ownership

ATC is authoritative per aircraft. It owns callsign, controller phase, clearance, pending readback, assigned squawk/frequency/runway and readback result. A clearance request creates a structured clearance; the pilot must return a structured readback for validation. ATC synchronizes the assigned squawk into the transponder state. Later phases can add taxi routing, departure instructions, traffic separation, approach sequencing, emergency handling and multi-aircraft controller state without coupling those rules to cockpit UI.

## Engine-out integration

Engine failures are server-authoritative. A failed engine loses running state/thrust, while the physics layer integrates left/right thrust asymmetry into a yaw moment and exposes `EngineIntegration` telemetry. Failure logic stays in the failure/engine systems; cockpit code never directly injects engine failure effects.

## Electrical source priority

Electrical models source availability rather than treating Battery/APU/engine generators as equivalent booleans. Engine generator availability depends on a stable running engine; APU generator availability depends on a running/stable APU; external power is an independent ground source. Boeing-specific behavior is implemented progressively from public system knowledge.

## Migration rule

`FlightSimBootstrap.server.lua` is a development installer, not the final production runtime. New systems are written as source modules and then wired into the runtime. The legacy MCP implementation is retired in favor of `MCP.v02.lua`.

## Current phase

The core aircraft simulation chain is now wired through MCP/VNAV, ILS/VOR receiver ownership, autopilot, autothrottle/TOGA, engine-out asymmetric-thrust integration, ATC clearance/readback foundation, and deterministic subsystem contract tests. The next layers are airport/aircraft content integration, richer ATC traffic/clearance logic, weather/environment, emergency procedures, cockpit hardware, multiplayer traffic coordination, and optimization.
