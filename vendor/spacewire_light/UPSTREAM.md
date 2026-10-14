# Source provenance

SpaceWire Light, copyright 2009-2013 Joris van Rantwijk.

- Upstream project: https://opencores.org/projects/spacewire_light
- Source mirror: https://github.com/freecores/spacewire_light
- Pinned commit: `d26037ffc408dac1d21bab160e185c4798334681`
- Only the non-GRLIB generic RTL subset and its link testbench are included.
- The upstream README permits these non-GRLIB parts under LGPL-2.1-or-later in addition to GPL-2.0-or-later. Both license texts and the original README are retained.
- Fast/DDR and AMBA/GRLIB implementations are not included or selected. Inactive fast component declarations may produce binding warnings; they are not instantiated in the elaborated generic design.

The application wrapper and tests are separate project files. The initial SystemVerilog bit encoder is a standalone experiment and is not inserted in series with this core's transmitter.

## Local changes (2026-10-14)

- `spwlink.vhd`: reset timer width is calculated from reset_time, replacing the fixed 11-bit width that overflowed at 400 MHz (2560 cycles).
- `spwrecv.vhd`: disconnect timer width is calculated from disconnect_time, replacing the fixed 8-bit width; the generic is positive rather than 1..255 (400 MHz needs 340 cycles).
- `spwpkg.vhd`: matching disconnect_time component generic changed to positive.
- `spwrecvfront_generic.vhd`: AMD ASYNC_REG/SHREG_EXTRACT metadata for the two-stage input synchronizers, with no functional behavior changes.

These changes do not establish 400 MHz device timing. The upstream behavioral link bench is retained unchanged to independently exercise protocol behavior.
- Trailing whitespace normalized in selected RTL files; no functional change.
