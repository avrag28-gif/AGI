# FlightSim simulation units and coordinate contract v0.1

This contract defines the units exchanged between simulation systems. It is a game-simulation convention, not certified Boeing engineering data.

## Scalar units

| Field | Unit | Convention |
|---|---|---|
| `Airspeed` | knots | True simulation airspeed value used by current flight model. |
| `Altitude` | ft | Mean/airport-relative simulation altitude. Ground contact clamps it to 0 in the current model. |
| `VerticalSpeed` | ft/min | Positive climb, negative descent. |
| `Heading` | degrees | 0..360, clockwise from simulation north (+Z). |
| `Pitch` | degrees | Positive nose-up. |
| `Roll` | degrees | Positive right bank according to the current attitude convention. |
| `YawRate`, `PitchRate`, `RollRate` | degrees/s | Body attitude rates used by the game flight model. |
| `Throttle` | 0..1 | Normalized lever command. |
| `Hydraulic.A/B` | psi-equivalent | Game-simulation pressure; `HydraulicMax` is the configured upper bound. |
| `Fuel.Total` | game mass units | Internal game mass proxy; do not interpret as kilograms without an explicit conversion layer. |
| `Temperature` | °C | Atmospheric/environmental temperature where used. |
| `Pressure` | hPa | Atmospheric pressure where used. |
| `WindU/WindV/WindW` | knots | Horizontal wind components and gust component. |
| `VisibilityKm` | km | Horizontal visibility. |
| `RangeM`, `Distance` | m | Navigation/traffic geometric distance unless a field explicitly says NM. |
| `RangeNm` | NM | Nautical-mile display/traffic value. |
| `RolloutDistance` | m | Ground rollout distance. |
| `Speed constraints` | knots | FMC/procedure speed constraints. |
| `Altitude constraints` | ft | FMC/procedure altitude constraints. |

## Vector coordinate contract

Simulation `Position` and `Velocity` use **game-space meters** as their logical unit. Roblox `Vector3` itself is dimensionless, so the eventual world adapter must establish a single mapping between logical simulation meters and Roblox studs.

Current world convention:

- +X = east/right in the horizontal simulation plane.
- +Z = simulation north/forward reference.
- +Y = vertical.
- Heading 0° points toward +Z.
- Heading 90° points toward +X.
- Heading is measured clockwise from +Z.
- Horizontal navigation distance uses X/Z only.

## Required boundary conversions

- knots → m/s: `kt * 0.514444`
- ft/min → m/s: `fpm * 0.3048 / 60`
- ft → m: `ft * 0.3048`
- m → NM: `m / 1852`
- NM → m: `nm * 1852`

No module should silently treat ft as m, ft/min as m/s, or NM as meters.

## Ownership rules

- Physics owns integration of position, velocity, altitude and vertical speed.
- Navigation owns geometric bearing/distance/cross-track guidance.
- Approach owns raw ILS candidate signals.
- NAVReceiver owns radio-source selection.
- LandingModel owns phase/flare state.
- LandingDynamics owns wheel contact/touchdown event/quality and rollout-distance metric.
- LandingGear owns actual gear actuation/lock state.
- Brakes owns brake pressure generation.
- Hydraulic owns hydraulic pressure generation from actuator demand.

## World adapter requirement

Airport/runway/aircraft 3D assets must not introduce their own scale convention. A future world adapter should expose explicit functions equivalent to:

`SimMetersToStuds(m)` and `StudsToSimMeters(studs)`.

Until that adapter exists, simulation positions should remain in logical game-space meters and asset placement should consume the same contract.
