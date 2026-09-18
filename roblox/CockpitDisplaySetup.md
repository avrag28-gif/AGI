# 737-800 cockpit display setup

The client display bridge can project the simulator's PFD, ND, and EICAS readouts onto optional 3D cockpit monitor parts using Roblox `SurfaceGui`.

## Optional monitor part names

Inside the player's tagged aircraft Model, create BaseParts with one of these names:

- PFD: `PFDDisplay`, `CaptainPFD`, or `LeftPFD`
- ND: `NDDisplay`, `CaptainND`, or `LeftND`
- EICAS: `EICASDisplay`, `CenterEICAS`, or `EngineDisplay`

The bridge does nothing when these parts are absent, so the normal screen instruments remain available.

## Surface orientation

The current automatic display uses the part's Front face. If the physical monitor is modeled on another face, rotate the monitor Part so its display face is Front, or extend the binder's face configuration before using it in the final cockpit.

## MCP/control-panel attributes

The aircraft Model receives these attributes from the authoritative simulation state:

- `FlightSimMCPHeading`
- `FlightSimMCPAltitude`
- `FlightSimMCPSpeed`
- `FlightSimMCPVerticalSpeed`
- `FlightSimMCPHeadingMode`
- `FlightSimMCPAltitudeMode`
- `FlightSimMCPVerticalSpeedMode`
- `FlightSimMCPFlightDirector`

Other cockpit/system attributes are documented in `AircraftModelBinder.lua`.

## Motor6D control-surface contract

Optional Motor6D names:

- `LeftAileronMotor` / `AileronLeftMotor`
- `RightAileronMotor` / `AileronRightMotor`
- `ElevatorMotor` / `ElevatorLeftMotor`
- `RudderMotor`
- `FlapMotor` / `FlapsMotor`
- `SpeedbrakeMotor` / `SpoilerMotor`
- `NoseGearMotor` / `GearNoseMotor`
- `LeftGearMotor` / `GearLeftMotor`
- `RightGearMotor` / `GearRightMotor`

The binder now uses explicit animation axes for these motors; the right aileron/elevator directions are encoded in the commanded angle rather than being confused with an axis argument.

## Roblox UI note

`SurfaceGui` is the intended Roblox in-world UI container for UI rendered on a part face. `TextLabel` supplies the text display. The generated display intentionally uses normal 3D occlusion rather than `AlwaysOnTop`, so it behaves more like a cockpit screen.

This remains a simulator presentation layer; it does not change the authoritative flight-model state.
