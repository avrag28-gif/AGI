# ATC Foundation

The simulator now has a server-authoritative per-aircraft ATC state machine foundation.

## Commands

- `ATCCallsign(callsign)` assigns a validated callsign.
- `ATCPhase(phase)` sets the simulated controller phase.
- `ATCRequest("DEPARTURE"|"TAXI"|"APPROACH")` requests a clearance.
- `ATCReadback(table)` validates the structured pilot readback.

## Departure flow

`COLD → departure request → structured clearance → readback → squawk/frequency synchronization → later ground/tower/departure phases`.

The current module deliberately does not pretend to implement real-world ATC separation or phraseology exhaustively. The data model is designed so airport-specific procedures, runway assignment, taxi routing, SID/STAR, controller handoff, traffic sequencing, emergency priority and multiplayer conflict detection can be added without coupling ATC to the cockpit UI.

## Weather foundation

`Environment.lua` provides server-side wind, atmospheric temperature/pressure, visibility, precipitation, turbulence, icing and thunderstorm state. It currently exposes those values to telemetry; aerodynamic coupling should be introduced as a controlled next physics pass rather than silently changing the existing flight model.
