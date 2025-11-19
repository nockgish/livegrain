# livegrain

A ready-to-play SuperCollider patch for live granular synthesis. Load `livegrain.scd` inside the SuperCollider IDE, evaluate the file top-to-bottom, choose a sample when prompted, and start shaping grains with the provided helper functions.

## Highlights
- Tempo-aware modulation clock and helper gestures for rapid performance tweaks
- `TGrains`-based SynthDef with spread, jitter, and density controls
- FX bus with a tunable stereo verb
- `~set` helper plus `~gestures` macros for expressive live coding
- Optional `Pdef(\posLFO)` for continual motion in grain position

See inline comments in `livegrain.scd` for a quickstart cheat sheet and live performance tips.
