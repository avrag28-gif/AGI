# Boeing 737-800 NG realism coverage

This document is the engineering audit baseline for the simulator. The goal is not to claim certification or literal 1:1 replication; the goal is to make every modeled aircraft behavior traceable to an identified aircraft system and to keep approximation boundaries explicit.

## Aircraft baseline

- Aircraft: Boeing 737-800 Next Generation
- Baseline engine: CFM56-7B26
- Engine count: 2
- Engine takeoff static thrust baseline: 26,300 lbf per engine
- Engine maximum continuous static thrust baseline: 25,900 lbf per engine
- VMO/MMO baseline: 340 KCAS / Mach 0.82
- Main hydraulic nominal pressure baseline: 3,000 psi

## Source hierarchy

1. FAA Type Certificate Data Sheet A16WE for certification-level aircraft/model/engine/limit facts.
2. Boeing 737NG Airplane Characteristics for Airport Planning D6-58325-7 for aircraft characteristics and geometry relevant to airport/ground modeling.
3. FAA technical/accident/FOIA material for publicly documented system architecture and safety behavior.
4. CFM International public technical material for CFM56-7B family architecture and published engine characteristics.
5. Operator-specific procedures/data are not assumed to be universal; they must be represented as configurable operator profiles.

## Current implemented layers

- Authoritative server aircraft state
- Electrical, APU, engine, fuel, fire protection, bleed air, pressurization, anti-ice
- Hydraulic, flight controls, landing gear, brakes, ground steering
- Avionics, radio, transponder, navigation, VOR, NAV receiver, ILS/approach
- FMC, MCP, VNAV, autopilot, autothrottle
- Weather/environment/weather radar
- ATC clearance/readback, runway sequencing, traffic separation, decision layer, TCAS/traffic display
- Landing model/dynamics
- Failure declaration and subsystem-owned failure propagation
- Fixed-step server runtime
- State-integrity monitoring

## Known realism gaps that must NOT be hidden

The following are still engineering work, not completed claims:

- High-fidelity 6-DOF aerodynamic model with aircraft-specific stability/control derivatives
- Engine thermodynamic/FADEC/EEC model and altitude/Mach/temperature thrust maps
- Full IRS/ADIRU alignment, drift and inertial navigation behavior
- Full FMC/CDU database/procedure model including ARINC-424-style procedure data
- Complete electrical distribution and bus-transfer logic at aircraft-system level
- Full hydraulic A/B/standby architecture and exact actuator consumers
- Full pneumatic/bleed/pack/anti-ice architecture and temperature control
- Oxygen, emergency equipment and passenger/crew systems
- Complete fire detection/extinguishing logic and bottle/agent behavior
- Full flight-control PCU/feel/centering/manual-reversion behavior
- Spoilers/speedbrake, yaw damper and detailed augmentation logic
- Autobrake and brake-temperature/wheel-speed/anti-skid model
- Detailed landing gear doors, uplocks/downlocks, alternate extension and gear warning logic
- Complete EICAS/annunciation/warning hierarchy and cockpit indications
- Full PFD/ND/EFIS instrument behavior
- Complete MCP/AFDS mode logic and mode annunciation
- Complete weather radar attenuation/tilt/gain/returns model
- TCAS logic to the appropriate published collision-avoidance behavior
- Full airport/runway/taxiway/STAR/SID/approach data and terrain database
- Full cockpit 3D geometry, controls, displays, lighting, sounds and switch detents
- Operator configuration, weight-and-balance, performance initialization and dispatch model
- Comprehensive automated regression tests running in Roblox Studio/CI

## Rule

A subsystem is not considered complete merely because a Lua module exists. It is complete only when its state, controls, indications, failure behavior, dependencies, tests and cockpit representation agree with the aircraft-specific reference set.
