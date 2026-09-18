# Cockpit Control Contract

The aircraft model can expose physical controls using either `ClickDetector` or `ProximityPrompt`.

Put these Attributes on the control Part/Model:

- `Command` (string): one of the server AircraftCommand names.
- `A` (number/string/bool): first argument.
- `B` (number/string/bool): second argument.
- `Toggle` (bool, optional): automatically flips a local `State` attribute before sending.

Examples:

| Control | Command | A | B |
|---|---|---:|---:|
| Battery switch | Battery | — | — |
| APU switch | APU | — | — |
| Engine 1 starter | EngineStarter | 1 | true/false |
| Engine 2 starter | EngineStarter | 2 | true/false |
| Engine 1 fuel | EngineFuel | 1 | true/false |
| Engine 2 fuel | EngineFuel | 2 | true/false |
| Engine 1 ignition | EngineIgnition | 1 | true/false |
| Engine 2 ignition | EngineIgnition | 2 | true/false |
| Gear lever | Gear | true/false | — |
| Parking brake | ParkingBrake | true/false | — |
| Flap selector | Flap | 0..1 | — |
| Autopilot | AP | true/false | — |
| MCP heading selector | MCPHeading | degrees | — |
| MCP altitude selector | MCPAltitude | feet | — |
| MCP speed selector | MCPSpeed | knots | — |
| MCP vertical-speed selector | MCPVerticalSpeed | feet/min | — |
| MCP mode selector | MCPMode | HDG/LNAV/VNAV/VOR/APP/ALT_HOLD/LCHG/VS/OFF | — |
| Autothrottle switch | AutoThrottle | true/false | — |
| TOGA / go-around switch | GoAround | true/false | — |

The keyboard client maps `X` to `GoAround=true` for the simulation prototype. A physical TOGA control should use the same server command.

MCP targets are pilot selections stored in authoritative aircraft state. Navigation/autopilot systems consume those selections; MCP does not directly overwrite computed navigation guidance outputs.

Autothrottle telemetry exposes `Enabled`, `Active`, `Mode`, `Protection`, `TargetSpeed`, `SpeedError`, and per-engine throttle commands. During go-around the simulation uses `Mode=TOGA` and commands maximum available engine throttle; this is a game-simulation approximation, not certified Boeing logic.

This is an interaction contract, not a finished 3D cockpit. The aircraft-model pass should name physical controls consistently and add the corresponding attributes/detectors.


## 3D MCP knob interaction

For a physical SPD/HDG/ALT/VS selector, put a ClickDetector or ProximityPrompt under the knob Part/Model and add:

- `Interaction = "MCP_KNOB"`
- `Command = "MCPSpeed"`, `"MCPHeading"`, `"MCPAltitude"`, or `"MCPVerticalSpeed"`
- `Step` = increment per click
- `Min` / `Max` = optional hard limits
- `Direction` = `1` or `-1`
- `Wrap = true` for cyclic values such as heading
- `ValueAttribute` = optional model attribute override

Recommended 737-style setup:

| Knob | Command | Step | Min | Max | Wrap |
|---|---|---:|---:|---:|---|
| SPD | MCPSpeed | 1 | 60 | 350 | false |
| HDG | MCPHeading | 1 | 0 | 359 | true |
| ALT | MCPAltitude | 100 | 0 | 60000 | false |
| VS | MCPVerticalSpeed | 100 | -6000 | 6000 | false |

A click advances by `Step*Direction`. The client reads the aircraft model's live `FlightSimMCP*` attribute before each click, while the server remains authoritative and applies validation/clamping.

## Physical rotary drag

MCP SPD/HDG/ALT/VS knobs can use a `DragDetector` under the same Part/Model.

Required attributes remain:
- `Interaction = "MCP_KNOB"`
- `Command`
- `Step`
- `Min` / `Max`
- `Direction`
- optional `Wrap`
- optional `ValueAttribute`

Optional:
- `DegreesPerStep` — default `3.6` degrees of physical rotation per logical step.
- `RotateAxis` — `X`, `Y`, or `Z`; default is `Y`.

Recommended starting values:
- SPD: Step 1 kt, DegreesPerStep 3.6
- HDG: Step 1°, DegreesPerStep 3.6, Wrap true
- ALT: Step 100 ft, DegreesPerStep 3.6
- VS: Step 100 ft/min, DegreesPerStep 3.6

Roblox's DragDetector supports `RotateAxis` for one-dimensional rotation. This implementation uses its custom response path so simulator state remains authoritative rather than letting the detector directly control flight state.