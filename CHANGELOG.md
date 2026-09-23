## 0.1.1

* Document the public API.

## 0.1.0

* Add `TeethNumberingSystem` with `universal` (default) and `european` (FDI /
  ISO 3950) options via `DentalTeethSelector.numberingSystem`.
* Selection ids and chart labels follow the chosen numbering system.
* Add `convertToothId` / `convertToothIds` helpers to map between systems.
* Add fallen / missing teeth support: `showFallenTeeth`, `fallenTeeth`,
  `selectingFallenTeeth`, `onFallenChanged`, and `fallenColor` (default red).
* Assertions: `fallenTeeth` / `selectingFallenTeeth` require
  `showFallenTeeth: true`; fallen ids must not overlap `initiallySelected`.
* Fallen teeth cannot be selected in normal mode; enable
  `selectingFallenTeeth` to mark / unmark them. Tapping an already
  selected tooth while marking fallen does nothing.
* Example app: Universal / European / Fallen teeth tabs, with a mark/select
  switch on the Fallen teeth tab.

## 0.0.1

* Initial `DentalTeethSelector` with Universal Numbering System chart.
* Supports selection callback, initial selection, background / selected /
  border / number colors, and width / height.
