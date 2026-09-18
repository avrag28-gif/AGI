# Cockpit display integration

The aircraft model bridge exposes FlightSim* Model attributes. A client display script can render these attributes onto physical cockpit display Parts with SurfaceGui.

## Optional display Parts
- PFD: PFDDisplay, CaptainPFD, LeftPFD
- ND: NDDisplay, CaptainND, LeftND
- EICAS: EICASDisplay, CenterEICAS, EngineDisplay

The client creates a SurfaceGui only when one of these Parts exists. No cockpit geometry is required by the simulator.

Roblox documents SurfaceGui as an in-world UI container that renders on a Part face; TextLabel can be used inside it for text-based instrument output.

## MCP / AFDS attributes
- FlightSimMCPHeading
- FlightSimMCPAltitude
- FlightSimMCPSpeed
- FlightSimMCPVerticalSpeed
- FlightSimMCPMode
- FlightSimMCPFlightDirector
- FlightSimAPEnabled
- FlightSimAPMode
- FlightSimAPTargetAltitude
- FlightSimATEnabled
- FlightSimATMode
- FlightSimATProtection

These are presentation attributes. Command authority remains on the server through the existing command router.

## Physical control interaction

Use the existing CockpitInteraction.client.lua contract: Command, A, B, and optional Toggle.
Examples include MCPHeading, MCPAltitude, MCPSpeed, MCPVerticalSpeed, MCPMode, AP, AutoThrottle, and GoAround.

## Orientation

SurfaceGui.Face defaults to Front. If a physical display faces another direction, set the SurfaceGui face or adapt the display binder to the model orientation. AlwaysOnTop is kept false so the display behaves like a physical surface and can be occluded by cockpit geometry.

The display system is a simulator presentation layer, not a certified Boeing avionics implementation.