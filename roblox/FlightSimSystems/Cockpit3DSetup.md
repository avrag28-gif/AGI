# 737-800 3D Cockpit Integration Contract

The simulator treats the aircraft Model as the presentation layer. Tag the aircraft with `FlightSimAircraft` and set `FlightSimAircraftId` to the runtime aircraft id.

## Physical displays

Optional BaseParts are discovered by name:

- PFD: `PFDDisplay`, `CaptainPFD`, `LeftPFD`
- ND: `NDDisplay`, `CaptainND`, `LeftND`
- EICAS: `EICASDisplay`, `CenterEICAS`, `EngineDisplay`
- MCP annunciator: `MCPDisplay`, `MCPAnnunciator`, `AutopilotDisplay`

The client creates SurfaceGui/TextLabel only when the corresponding part exists. SurfaceGui renders GUI objects on a BasePart face, so the cockpit mesh remains optional and model-specific. 

## MCP physical controls

Existing `CockpitInteraction.client.lua` can drive the authoritative CommandRouter by adding attributes to clickable parts:

| Part purpose | Command | A |
|---|---|---|
| MCP speed selector | `MCPSpeed` | numeric speed |
| MCP heading selector | `MCPHeading` | numeric heading |
| MCP altitude selector | `MCPAltitude` | numeric altitude |
| MCP VS selector | `MCPVerticalSpeed` | numeric fpm |
| MCP mode button | `MCPMode` | `HDG`, `LNAV`, `VNAV`, `APP`, `ALT_HOLD`, `LCHG`, `VS`, `OFF` |
| AP engage/disconnect | `AP` | boolean |
| A/T arm | `AutoThrottle` | boolean |
| TO/GA | `GoAround` | true |

For increment/decrement knobs, use two physical parts with different A values rather than client-side state mutation.

## Optional mechanical animation

The aircraft binder recognizes Motor6D names for:

- ailerons: `LeftAileronMotor`, `RightAileronMotor`
- elevator: `ElevatorMotor`
- rudder: `RudderMotor`
- flaps: `FlapMotor`
- speedbrake: `SpeedbrakeMotor`
- landing gear: `NoseGearMotor`, `LeftGearMotor`, `RightGearMotor`
- engine fans: `Engine1FanMotor`, `Engine2FanMotor`

The bridge uses Motor6D.Transform for presentation animation; Roblox documents Motor6D as suitable for non-avatar mechanical rigs.

## Authoritative cockpit state

The server binder exposes `FlightSim*` Attributes on the aircraft Model for display/animation scripts. Examples include MCP targets, AP/A/T state, hydraulic pressures, gear locks, engine N1/N2/EGT, and primary control-surface positions.

Do not make a visual cockpit script authoritative. Physical controls should send commands through the existing server command path so ownership and command-rate validation remain centralized.

## Validation checklist

1. Aircraft tag and id resolve.
2. PFD/ND/EICAS parts appear only when physically present.
3. MCP display follows simulator targets.
4. Physical MCP inputs reach CommandRouter.
5. AP/A/T annunciators follow authoritative state.
6. Control-surface Motor6Ds move in the expected direction.
7. Missing cockpit parts do not generate errors.
8. No cockpit presentation code directly changes authoritative flight state.
