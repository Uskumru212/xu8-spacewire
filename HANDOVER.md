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

## Continuation workstation results (2026-10-14)

The original Vivado 2026.1 license blocker remains an accurate historical note for the originating workstation. On a continuation workstation, Vivado 2025.2 validated the PS/SmartConnect/telemetry block design, generated IP, exported a software-only XSA and passed board-top structural synthesis with the candidate XDC disabled. Vivado rejected the former 0x80000000 HPM0 address, so the telemetry aperture is now 0xA0000000. The reset integration check also found and fixed auxiliary reset polarity. No implementation, timing closure, bitstream or hardware test has succeeded. The Vitis standalone BSP build did not complete because its Java/gRPC process failed to initialize a Windows loopback selector. See `docs/validation.md`.

1. Resolve bank-65 clock IOSTANDARD using exact R3 electrical information. Pin AH6/AJ6 and 100 MHz are known; electrical configuration remains open.
2. Bank 66 is user-confirmed at 1.8 V, matching AMD's HP-bank LVDS VCCO requirement for outputs and internally terminated inputs. The supplied SOM schematic crop confirms all four D/S differential pair mappings. Check the isolator-side swing/common-mode limits, termination population and board assembly before enabling candidate XDC.
3. Review CDC and constrain input timing, then close 400 MHz timing before device implementation and bitstream generation.
4. Build the standalone UART app with a working Vitis/standalone BSP, ensuring the linker map is OCM-only.
5. Perform the physical procedure in `docs/bringup.md`, including UART logs, ILA capture and remote receive evidence.

## Preserve these hardware facts

On 2026-10-15 the user confirmed VCC_CFG_MIO is 3.3 V on the custom carrier.
PS banks 501/503 default to LVCMOS33 in the telemetry recipe. Banks 500/502
remain LVCMOS18. This resolves the MIO supply question, not the bank-65 PL clock standard.
The SOM supplies the onboard 100 MHz PL clock at AH6/AJ6; no external carrier
oscillator is required. The existing Clock Wizard requests 400 MHz from it.
The remaining clock issue is the R3 input IOSTANDARD, not clock availability.

Bank66 is user-confirmed 1.8 V. Isolator is ADN4622BRNZ. RX termination R3026/R3027 are DNP; candidate uses internal TERM_100. Both power enables are active high; their bank48 supply is user-confirmed 3.3 V. Do not replace custom-carrier settings with PE3 carrier settings. Programmer was described as Digilent FTAG-HS3, likely JTAG-HS3, not yet detected. All pin mappings and source links are in `docs/hardware.md`.

## Local paths in the originating environment

Repository: `C:\Users\eerde\Documents\Codex\2026-10-14\and-then\outputs\xu8-spacewire`.

Vivado: `C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat`.

Portable GHDL used for the recorded tests: `C:\Users\eerde\Documents\Codex\2026-10-14\and-then\work\tools\ghdl\bin\ghdl.exe`. This binary is outside the repo; use `scripts/get_ghdl.ps1` on a new machine.

Legacy standalone SV files are not the integrated endpoint. Do not confuse their previous compile-only results with the passing VHDL protocol regression. Do not claim the hardware link works until physical evidence exists.

## SOM UART addition

The user requested full process logging through SOM UART and explicitly chose an independent bare-metal application (no existing OS/application to preserve). UART0 RX is MIO38 / connector105 / TP615; TX is MIO39 / connector107 / TP616. APU_UART on MIO48/49 is separate. The candidate board includes a PS + dual-clock AXI bridge to a snapshot register bank and 64-event FIFO, with a standalone A53/OCM UART monitor source. See docs/uart.md. FPGA telemetry and portable C log tests passed. On the continuation workstation, Vivado 2025.2 validated the PS/SmartConnect/telemetry block design, generated IP, exported a software-only XSA and passed board-top structural synthesis with the candidate XDC disabled. The target standalone BSP/ELF build remains incomplete; on-hardware PS initialization, physical UART output, implementation and timing closure remain unverified. See docs/validation.md for the reported results and limits. ILA is instantiated in source; no external analyzer was attached and no hardware capture exists.
