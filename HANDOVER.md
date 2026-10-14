# Continuation handover

## Goal and communication

Build and validate a 200 Mbit/s SpaceWire link on Enclustra Mercury+ XU8 ME-XU8-7EV-2I-D12E R3, with no DDR I/O, connected to an unspecified external SpaceWire device. Communicate with the user in Turkish; keep all repository files/comments/commits in English.

Repository: https://github.com/Uskumru212/xu8-spacewire (private). Another ChatGPT account does not automatically inherit chat history or GitHub access. Clone this repository using an authorized GitHub account and supply this file as context. Do not copy tokens or license files into the repository.

## Implemented

- Vendored non-GRLIB generic SpaceWire Light subset, pinned and attributed, with timer widths extended for 400 MHz and synchronizer metadata.
- Rising-edge-only streaming endpoint with link initialization, credit flow control, packet/time-code handling, configurable Run divider, FIFOs and ten diagnostic counters.
- Optional deterministic test packet source.
- Candidate board top with LVDS buffers, static active-high power enables, clock/debug IP interfaces.
- GHDL test runner and pinned portable-tool download script.
- Protocol and candidate-board Vivado project recipes. Candidate board XDC is disabled by default.

## Verified on 2026-10-14

Nine license-free behavioral scenarios passed: three upstream wire-level bench configurations, four endpoint phase/skew cases, one packet-source test and one telemetry AXI/FIFO test. Native C logger tests also passed. Generic GHDL endpoint synthesis passed. AMD package pin identities and bank types were checked. Read `docs/validation.md` for actual scope and limits.

## Not verified / next work

Vivado 2026.1 is installed but fails license checks before project Tcl runs. XSim execution also fails licensing. No Vivado project generation, generated IP binding, FPGA implementation, timing closure or hardware link test has succeeded. No bitstream exists.

1. Run `scripts/run_ghdl.ps1` to reproduce the regression; use GHDL rather than blocked XSim.
2. Obtain/activate the appropriate official AMD license when available; no license file has been generated here.
3. Resolve bank-65 clock IOSTANDARD using exact R3 electrical information. Pin AH6/AJ6 and 100 MHz are known; electrical configuration remains open.
4. Execute candidate Vivado recipe, validate IP ports/properties and XDC, inspect CDC and close 400 MHz timing before generating/programming a bitstream.
5. Perform the physical procedure in `docs/bringup.md`, including remote receive evidence.

## Preserve these hardware facts

Bank66 is user-confirmed 1.8 V. Isolator is ADN4622BRNZ. RX termination R3026/R3027 are DNP; candidate uses internal TERM_100. Both power enables are active high; their bank48 supply is user-confirmed 3.3 V. Do not replace custom-carrier settings with PE3 carrier settings. Programmer was described as Digilent FTAG-HS3, likely JTAG-HS3, not yet detected. All pin mappings and source links are in `docs/hardware.md`.

## Local paths in the originating environment

Repository: `C:\Users\eerde\Documents\Codex\2026-10-14\and-then\outputs\xu8-spacewire`.

Vivado: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat`.

Portable GHDL used for the recorded tests: `C:\Users\eerde\Documents\Codex\2026-10-14\and-then\work\tools\ghdl\bin\ghdl.exe`. This binary is outside the repo; use `scripts/get_ghdl.ps1` on a new machine.

Legacy standalone SV files are not the integrated endpoint. Do not confuse their previous compile-only results with the passing VHDL protocol regression. Do not claim the hardware link works until physical evidence exists.

## SOM UART addition

The user requested full process logging through SOM UART and explicitly chose an independent bare-metal application (no existing OS/application to preserve). UART0 RX is MIO38 / connector105 / TP615; TX is MIO39 / connector107 / TP616. APU_UART on MIO48/49 is separate. The candidate board includes a PS + dual-clock AXI bridge to a snapshot register bank and 64-event FIFO, with a standalone A53/OCM UART monitor source. See docs/uart.md. FPGA telemetry and portable C log tests passed; target BSP/ELF, generated BD, PS initialization and physical UART are untested. ILA is instantiated in source; no external analyzer was attached and no hardware capture exists.