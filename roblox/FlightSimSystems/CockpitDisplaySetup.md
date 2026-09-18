# Cockpit Display Contract

The simulator can drive optional physical cockpit displays using Roblox SurfaceGui.

## Supported display part names

- PFD: `PFDDisplay`, `CaptainPFD`, `LeftPFD`
- ND: `NDDisplay`, `CaptainND`, `LeftND`
- EICAS: `EICASDisplay`, `CenterEICAS`, `EngineDisplay`

The client creates a SurfaceGui only when one of these BaseParts exists under the aircraft model/workspace.

## MCP state attributes

The aircraft model exposes:

- `FlightSimMCPHeading`
- `FlightSimMCPAltitude`
- `FlightSimMCPSpeed`
- `FlightSimMCPVerticalSpeed`
- `FlightSimMCPHeadingMode`
- `FlightSimMCPAltitudeMode`
- `FlightSimMCPVerticalSpeedMode`
- `FlightSimMCPFlightDirector`

These are presentation bindings to the authoritative simulator state.

Roblox supports SurfaceGui for UI rendered on a 3D part face and TextLabel for text display. The display remains optional so aircraft models without physical screens continue to work.
