# Features — Priority Tiers (Essential / Recommended / Optional)

## ESSENTIAL (core)
- Movement and basic world bounds
- Patient state transitions (susceptible → infected → contagious → recovered)
- Facility objects with capacity and queue system
- Controlled spawn system for testing
- Scoreboard: recovered, infections, facility overload
- Scaling functions so world fits different screens
- Use engine-safe visuals (no unsupported APIs)

## RECOMMENDED (important improvements)
- Infection timers & severity levels
- Facility fallback: seek next facility if full
- Facility UI indicators (queue count, overload)
- Lightweight audio cues
- CSV logging of runs
- Toggleable debug/metric panels

## OPTIONAL (nice to have)
- Ambulance/mobile units
- Themes / cosmetic polish
- Scenario editor (seasonal spikes)
- Analytics panel (plots/time series)
