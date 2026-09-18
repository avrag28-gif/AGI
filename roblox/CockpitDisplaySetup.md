# Cockpit display and MCP binding

The aircraft bridge exposes simulator state as Model attributes so cockpit presentation scripts do not need direct access to server simulation objects.

## Physical displays

Tag the aircraft Model with `FlightSimAircraft` and set `FlightSimAircraftId` to the runtime aircraft id.

Optional BasePart names recognized by `FlightSimClient.client.lua`:

- PFD: `PFDDisplay`, `CaptainPFD`, `LeftPFD`
- ND: `NDDisplay`, `CaptainND`, `LeftND`
- EICAS: `EICASDisplay`, `CenterEICAS`, `EngineDisplay`

The client creates a `SurfaceGui` and `TextLabel` only when a matching part exists.

## MCP attributes

The aircraft Model receives:

- `FlightSimMCPHeading`
- `FlightSimMCPAltitude`
- `FlightSimMCPSpeed`
- `FlightSimMCPVerticalSpeed`
- `FlightSimMCPHeadingMode`
- `FlightSimMCPAltitudeMode`
- `FlightSimMCPVerticalSpeedMode`
- `FlightSimMCPFlightDirector`

Cockpit interaction can use the command attributes documented in `CockpitControlSetup.md`: `MCPHeading`, `MCPAltitude`, `MCPSpeed`, `MCPVerticalSpeed`, `MCPMode`, `AutoThrottle`, and `GoAround`.

## Motor6D animation

Optional mechanical animations use the documented Motor6D names in `AircraftModelBinder.lua`. The animation is presentation-only; the simulation state remains authoritative.

