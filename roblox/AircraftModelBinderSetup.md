# Aircraft model bridge setup

The server runtime now bridges the authoritative 737-800 simulation State into a Roblox aircraft Model.

## Required Studio setup

1. Put the playable aircraft Model in Workspace.
2. Add the CollectionService tag `FlightSimAircraft` to that Model.
3. Set the Model attribute `FlightSimAircraftId` to the runtime aircraft id:
   - `P_<Player.UserId>`
   - Example: `P_123456789`
4. Optional: set the Model attribute `FlightSimKinematic` to `true` (default is `true`).

## What the bridge drives

The bridge maps the authoritative simulation state to the model:
- Position (simulation meters -> Roblox studs)
- Heading
- Pitch
- Roll
- Altitude
- Airspeed
- Ground contact
- Flap position
- Nose/left/right gear position
- Engine throttle commands

It also writes the latest flight values as Model Attributes prefixed with `FlightSim...`, so cockpit/animation scripts can consume them without reading the internal State module.

## Architecture choice

`FlightSimKinematic=true` means the aircraft model is a visual/interactive representation moved by the server-authoritative simulator. Its BaseParts are anchored so Roblox rigid-body physics cannot fight the flight model.

This bridge does not claim certified 737 dynamics; the aerodynamic coefficients remain explicit game-simulation approximations in `Physics.lua`.

If a future aircraft implementation uses a physically simulated Roblox assembly instead, keep the binder disabled for that model and implement the force/constraint layer separately rather than mixing two independent motion authorities.

## Optional control-surface animation

The binder also supports optional `Motor6D` animation. If the aircraft model contains these Motor6D names, their `Transform` is driven from the authoritative surface state: `LeftAileronMotor`, `RightAileronMotor`, `ElevatorMotor`, `RudderMotor`, `FlapMotor`, `SpeedbrakeMotor`, `NoseGearMotor`, `LeftGearMotor`, and `RightGearMotor`. Missing motors are ignored. `GearAnimationAngle` can override the default 90-degree gear animation angle.

For mechanical aircraft rigs, Motor6D is suitable for non-character mechanical joints and its `Transform` is intended for custom animation. citeturn0search0
