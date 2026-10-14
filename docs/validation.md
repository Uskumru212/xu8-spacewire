# Validation report

Date: 2026-10-14. No physical FPGA was programmed.

## Executed checks

| Check | Result |
| --- | --- |
| GHDL 6.0.0 analysis | Generic protocol subset, endpoint, packet source, candidate board top and testbenches passed |
| Unmodified upstream link bench, 20 MHz / 10 Mbit/s | Completed |
| Upstream wire-level bench, 400 MHz / 200 Mbit/s | Completed |
| Upstream wire-level bench, 400 MHz / 199.6 Mbit/s input | Completed |
| Packet source with stalls and disable mid-packet | Passed pattern, EOP, packet-boundary stop, link-loss restart and reset checks |
| Two endpoints, phases/skews 0/0, 700/200, 1700/500, 2300/800 ps | All four passed |
| GHDL generic synthesis of spw_endpoint | Passed; two 256x9 RAMs inferred |
| AMD official package pin table | All 12 proposed package pins checked, including differential polarity and bank type |
| Earlier standalone SV xvlog/xelab | Compiled/elaborated; XSim execution blocked by license |

The original eight behavioral scenarios are one default upstream bench, two high-rate upstream bench instances, one packet-source bench and four endpoint configurations. `scripts/run_ghdl.ps1` checks explicit completion markers rather than treating a stop-time as success. Logs are regenerated under `build/ghdl` and excluded from Git.

## Endpoint scenario

A uses 400 MHz; B uses approximately 399.680 MHz, with a phase offset. Link delays are 7 ns and 9 ns, with additional strobe skew as listed above. A starts explicitly; B autostarts. A sends 512 checked data bytes plus EOP and EEP; B sends 128 checked data bytes plus EOP. B initially holds receive-ready low for 20 us, forcing credit/backpressure behavior. Every consumed character and packet marker is checked. Queue/receive counters, time-code reception, a frozen-line fault, disconnect-counter reporting, reconnection and counter reset are checked.

The upstream bench supplies wire-level stimuli independently of the wrapper-to-wrapper test. It exercises link initialization, NULL/FCT exchanges, data/time codes, EOP/EEP, timeout, parity, escape and credit error behavior. It is not an exhaustive standards-conformance suite.

## Interpretation and limitations

- Generic GHDL synthesis confirms synthesizable structure; it does not map or time the XCZU7EV.
- The board top was analyzed for VHDL syntax. AMD primitive/IP binding, clock generation, VIO, ILA and board reset behavior have not been simulated or implemented with generated IP.
- GHDL ignores AMD-specific synchronizer placement attributes during generic synthesis; Vivado must validate them.
- Inactive fast-implementation component declarations produce GHDL binding warnings. The selected generic branches do not instantiate those components.
- Discrete phase/skew tests do not prove arbitrary skew tolerance, metastability immunity, analog voltage compatibility or physical 200 Mbit/s operation.
- No board CDC report, placement, route, timing report, device DRC, bitstream, cable detection or remote-device packet acknowledgment exists yet.
- TX counters count entries accepted into the local FIFO, not remote delivery.

## Tool blockers

Vivado 2026.1 reports that no valid license is found before project Tcl executes. XSim also reports that it cannot obtain a Simulator license. This does not block the GHDL workflow. Vivado recipes remain unexecuted until licensing is available. No license workaround is used.

## Reproducibility

GHDL: official 6.0.0 Windows mcode release, archive SHA-256 `C1562B2A4767E34D33159B536B5E36A8A38EBDB6E7672AA9969A4F4AC2CADFFE`.

SpaceWire Light source commit: `d26037ffc408dac1d21bab160e185c4798334681`, with timer-width and synchronizer-attribute adaptations documented in `vendor/spacewire_light/UPSTREAM.md`.

## SOM UART extension (2026-10-14)

The regression now has nine HDL scenarios, adding tb_telemetry. AXI response stability, atomic counter snapshots, independent AW/W ordering, write rejection, event ordering/overflow, empty/invalid reads, control-change events and reset all passed. GHDL generic synthesis of spw_telemetry_axi passed (64x64 event memory inferred). The native C logger tests passed with -std=c99 -Wall -Wextra -Werror: counter mapping, formatting, bounded event draining, timestamp pairing and invalid identity reporting.

The PS/SmartConnect BD recipe and SOM UART0 application were added but have not been generated or run on the target. Native C tests do not compile/link main.c against an actual standalone BSP. No ELF, actual baud-rate measurement, UART session or ILA trace is available. Tcl lexical checks do not validate Vivado API/property behavior.

## Vivado board integration follow-up (2026-10-14)

Vivado 2025.2 was available on the continuation workstation. The official device part and 12 proposed package pins opened successfully. After repairing Windows Tcl path-list handling, the PS/SmartConnect/telemetry block design validated, generated IP, and exported a software-only XSA. The PS configuration selects UART0 MIO38..39 at 115200 baud, disables the PS DDR controller, enables M_AXI_HPM0_FPD, and places the 4 KiB telemetry window at 0xA0000000. Vivado rejected the old 0x80000000 address because it fell outside that master port's aperture. The reset check also exposed and fixed active-low reset polarity propagation and tied-low auxiliary reset polarity.

Vivado board-top synthesis completed with the candidate XDC deliberately disabled. This verifies structural synthesis and generated IP binding only. Report DRC contains the expected NSTD-1 and UCIO-1 critical warnings on all 12 external ports. The timing report has 2,150 no-clock pins, 2,817 unconstrained internal endpoints, and two inputs/outputs without delays. These are not timing-closure results. CDC reports 12 informational synchronized reset/SmartConnect paths between the 100 and 400 MHz domains; asynchronous SpaceWire receiver review still requires the intended clock and input constraints. No placement, routing, implementation, bitstream, or hardware test was run.

Enclustra's R3-capable manual confirms bank 65 at 1.2 V and external 100-ohm termination on the 100 MHz LVDS oscillator. The candidate clock IOSTANDARD is still unset because the manual does not identify the oscillator part/coupling limits and the Enclustra DDR reference selects DIFF_SSTL12_DCI. See `clock-investigation.md`. PS banks 500 and 502 are configured for their fixed 1.8 V supplies. The carrier-supplied VCC_CFG_MIO voltage for banks 501/503 is not known; set `SPW_PS_MIO_STANDARD` only after confirming that rail.

The native UART logger host tests still pass, but the target application has not produced an ELF. Vitis 2025.2's Java/gRPC server failed to initialize a Windows loopback selector in this workstation, so the standalone BSP build did not complete. A software-only XSA alone is not a deployable platform.
