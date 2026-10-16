# Continuation handover

## Latest named setup test — Setup 3 at 200 Mbit/s (2026-10-16)

Test Setup 3: "EM.VNIR_EM.Harness_ FM.PDH.03.200M_SOM1_0Ω", attempt-002,
completed with exit 0. Local nominal TX rate was explicitly reset and verified:
divider 1, control 0x010C, configured 400 MHz core clock. Observation 120.542 s:
eight Run=1 readings, no falling-Run capture, 1251 TX FIFO acceptances including
one EOP, RX zero, and zero error/Run-reentry deltas. Local checks passed; remote
delivery, integrity, wire speed and sustained throughput remain unverified.
Payload generation is off (0x010C). Cable 210299BFE26A, PULLNONE bitstream
SHA-256 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.
Evidence:
reports/2026-10-16/test-setup-3-em-vnir-em-harness-fm-pdh03-200m-som1-0ohm/attempt-002/README.md.
The original 100 Mbit/s attempt-001 was interrupted for the user's rate correction
and retained separately, without final counters or a completed verdict.
Setup 1 and 2 records were preserved. Setup 3 raw evidence hashes were verified before archival.


## Latest named setup test (2026-10-16)

Test Setup 2: "EM.VNIR_EM.Harness_ FM.PDH.03_SOM2_10Ω", attempt-001, used
JTAG cable 210299BFE26A and the same PULLNONE bitstream/procedure as Setup 1.
The finite 10Kbit script completed with exit 0: 120.681 s, eight Run=1 status
readings, no falling-Run capture, 1251 TX FIFO acceptances including one EOP,
RX zero, and zero error/Run-reentry counter deltas. Local checks passed;
remote receipt, payload integrity and throughput remain unverified. Packet
generation is off (0x010C). Evidence:
reports/2026-10-16/test-setup-2-em-vnir-em-harness-fm-pdh03-som2-10ohm/attempt-001/README.md.
SOM2 is a user-provided setup label; the JTAG serial identifies the cable.
Setup 1 and other board records were preserved.

## Named setup 1 (2026-10-16)

Test Setup 1: "EM.VNIR_EM.Harness_ FM.PDH.03_SOM1_10Ω", attempt-002, used
JTAG cable 210299BFE26A and the PULLNONE bitstream. The finite 10Kbit test
completed with exit 0: 120.844 s, eight Run=1 status readings, no falling-Run
capture, TX FIFO acceptances 1251 including one EOP, RX zero, and zero error
or Run-reentry counter deltas. This is a local-submission/link observation
pass; remote receipt/integrity and throughput remain unverified. Payload
generation is off (0x010C). Portable evidence and metadata are under
reports/2026-10-16/test-setup-1-em-vnir-em-harness-fm-pdh03-som1-10ohm/attempt-002/README.md.
Attempt-001 and its original runtime files were explicitly deleted at the user's
request. Attempt-002 is a fresh run under the final name. Other board records
were preserved. Use a new attempt number for further repeats.

## Latest local hardware state (2026-10-15)

PORTABLE EVIDENCE: reports/2026-10-15/replacement-xu8-210299BBA502/README.md links the latest attempt's original logs, CSV captures, executed Tcl scripts and checksum manifest. Use this archive when continuing on another machine; the V: paths below are workstation-local.

LATEST BOARD IS A REPLACEMENT: active JTAG cable is now 210299BBA502 (old board used 210299BFE26A). User confirmed same XU8 model/carrier/pinout/voltages and peer on/connected. PULLNONE bitstream loaded, but this link is unstable: polling missed brief Run periods; diagnostic counters showed repeated reentries, parity and credit errors. Falling-Run ILA captured status 0004 -> 0024 -> 0000 at samples 510/511/512, proving a Run drop immediately after parity-error assertion. TX remains zero; the finite 10Kbit test did not enable payload because its initial Run polling gate failed. Local reset did not resolve instability. Control remains 010C (start/autostart, payload off). See docs/validation.md and V:/spacewire-10kbit/reports/replacement_210299BBA502/run_falling_edge.csv. Earlier passing results below belong to the previous XU8, not this replacement. Physical root cause is unconfirmed.

LATEST PULLNONE RETEST: regenerated finite-test bitstream with BITSTREAM.CONFIG.UNUSEDPIN=PULLNONE is now loaded on XU8. The corrected test_10kbit.tcl completed successfully (exit 0): 121.762 seconds, all interval reads Run=1, no falling-edge disconnect capture, TX FIFO acceptances 1251 including one EOP, RX zero, all errors/reentries zero. Payload enable is off (0x010C). Remote receipt/integrity and throughput remain unverified. Evidence: V:/spacewire-pullnone-board-test.log and V:/spacewire-10kbit/reports/pullnone_board_test_summary.json. Previous capture evidence is preserved in reports/before-pullnone-board-test. See docs/validation.md for bitstream hash and scope.

CURRENT RESULT: finite 10,000-payload-bit mode implemented as TEST_PACKET_BYTES=1250 / TEST_ONE_SHOT=true, selected by SPW_TEST_10KBIT=1. All ten GHDL scenarios passed (logs V:/ghdl-10kbit-regression). V:/spacewire-10kbit was routed (setup +0.269 ns, hold +0.010 ns), exported and programmed successfully. Physical test: TX characters 1251 including one EOP, RX zero, no falling Run trigger for 120.841 seconds, and zero error/reentry counters. This confirms exact local submission, not remote delivery or throughput. Test payload is now disabled (VIO 0x010C). The peer's echo setting is unknown. The readout script's invalid stop_hw_ila call was removed; final counters were recovered without retransmitting. A newly connected debug session reported ILA IDLE, so do not assume trigger arming persists across close/reconnect. See docs/validation.md for evidence and the export-process shutdown crash.

LATEST RETRY: user confirmed a power cycle/reset. Reprogramming succeeded and all twenty initial status samples were 0x0004 (Run=1), with control 0x010C. Physical link initialization is now observed. Test payload is still off; packet delivery and throughput remain untested. Monitor/capture log: V:/spacewire-retry-monitor.log. The disconnected-peer state below is historical.

The user stopped UART application work and requested SpaceWire-only startup.
Vivado 2025.2 built and routed the standalone variant in `V:/spacewire-only`
with ENABLE_UART_TELEMETRY=false and ENABLE_DCI_STARTUP=true. The Digilent JTAG
cable and XCZU7 target were detected, a bitstream was loaded into volatile PL
configuration, and ILA/VIO cores are accessible. VIO control is 0x010C (link
start/autostart on, Run divider 1 / nominal 200 Mbit/s, test payload off).
Observed status alternates 0x0000/0x0001; Run was not observed. The user confirmed
that the remote endpoint is disconnected or powered off. Do not treat this as
an established physical link or tested packet exchange. Routing passed with
setup +0.239 ns and hold +0.003 ns; see docs/validation.md. Boot media was not
modified. UART ELF work remains incomplete and is outside the current request.

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
