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

This is an interaction contract, not a finished 3D cockpit. The next aircraft-model pass should name physical controls consistently and add the corresponding attributes/detectors.
