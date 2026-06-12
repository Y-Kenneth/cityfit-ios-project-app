# CityFit — Design Brainstorm & Open Questions

_A scratchpad for design ideas to explore later (e.g. with an AI designer).
These are questions/opportunities, not decisions. Last updated: 2026-06-12._

---

## Open design questions

- **Onboarding:** is character selection enough, or add a goal/fitness-level step?
- **Home map:** how should AI-generated routes be surfaced — a floating button, a
  card, a "Generate" FAB? Currently a button leading to a sheet.
- **Active mission map:** should distance missions require physically reaching the
  pin (geofence) to complete, vs. just walking the target distance anywhere?
- **Empty states:** no missions, no community, offline backend — none are designed yet.
- **Light mode:** currently dark-only. Worth a light theme, or keep the neon HUD look?
- **Photo mission feedback:** the detection banner is functional but plain — could
  use a more game-like "scanning / locked-on / captured" animation.

## Ideas worth exploring

- **Pokémon-GO feel:** AR camera layer to see missions in the real world (big effort,
  iOS 16 SDK limits AR+Map combos — flag as a later phase).
- **Reward animations:** level-up, EXP gain, mission-complete could use richer
  motion/particle effects (currently a simple overlay).
- **Streak / daily loop:** a visible daily-streak mechanic to drive retention.
- **Community features:** group challenges, shared leaderboards, events on the map.
- **Avatar progression:** unlock outfits/characters as the user levels up.

## Constraints a designer must respect

- **iOS 16 only.** Map is the iOS 16 API; overlays need UIKit bridges. No iOS 17 UI.
- **Dark, neon "cyber-city HUD"** visual language (see `DESIGN_SPEC.md` palette).
- **MVVM:** views are presentation-only; no business logic in screens.
- Numbers use monospaced digits; titles are heavy-weight SF.

## Reference

- Full screen + component breakdown: `DESIGN_SPEC.md`
- What works / what's pending: `PROJECT_STATUS.md`
- AI/ML architecture: `AI_AND_ML.md`
- Original product spec: `../iOS CityFit Project Background.md`
