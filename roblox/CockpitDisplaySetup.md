# Cockpit Display & MCP Setup

The aircraft bridge exposes simulator state as FlightSim* Model attributes and the client creates optional 3D cockpit displays with SurfaceGui.

## Required aircraft tag

Tag the aircraft Model with FlightSimAircraft and set FlightSimAircraftId = P_<Player.UserId>. FlightSimKinematic defaults to true.

## Optional 3D displays

| Display | Accepted names |
|---|---|
| Captain PFD | PFDDisplay, CaptainPFD, LeftPFD |
| Captain ND | NDDisplay, CaptainND, LeftND |
| EICAS | EICASDisplay, CenterEICAS, EngineDisplay |
| MCP display | MCPDisplay, MCPAnnunciator, AutopilotDisplay |

The client creates a SurfaceGui and TextLabel on matching parts. SurfaceGui is Roblox's in-world UI container for UI objects such as TextLabel.

## MCP controls

Optional physical button parts: APButton/AutopilotButton/MCPAPButton; ATButton/AutoThrottleButton/MCPATButton; HDGButton/HeadingButton/MCPHeadingButton; LNAVButton; VNAVButton; APPButton; VORButton; VSButton; ALTHLDButton; LVLCHGButton.

A ClickDetector or ProximityPrompt can be attached. The client assigns the appropriate Command/A attributes when a named part is found.

## MCP knobs

For a rotary MCP knob set Interaction = MCP_KNOB and Command to MCPHeading, MCPAltitude, MCPSpeed, or MCPVerticalSpeed. Optional attributes: Step, Min, Max, Wrap, Direction, ValueAttribute. A DragDetector enables continuous rotation.

The cockpit interaction layer reads FlightSimMCPHeading, FlightSimMCPAltitude, FlightSimMCPSpeed, and FlightSimMCPVerticalSpeed.

## State exposed to cockpit

The bridge also exposes AP/A/T, hydraulics, electrical, gear, flaps, trim, steering, engine N1/N2/EGT/running, reverse thrust, warnings/cautions, and annunciation messages as FlightSim* attributes.

This is an integration contract; it does not claim the 3D model geometry or display symbology is certified Boeing artwork.