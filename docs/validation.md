# Validation report

The initial sections record 2026-10-14 results. The latest hardware results follow; earlier limitations describe the state at their respective dates.

## Standalone SpaceWire hardware startup (2026-10-15)

Latest retry: the user confirmed an intervening power cycle/reset. After reprogramming, all twenty initial VIO samples and six subsequent samples at five-second intervals reported status 0x0004 (Run=1), control 0x010C. An ILA capture was saved to V:/spacewire-only/reports/physical_retry.csv. This establishes observed physical link initialization; test payload remains disabled, and packet delivery/throughput is not yet tested. See V:/spacewire-retry-monitor.log. The disconnected-peer observations below describe the earlier attempts.

At the user's request, UART/PS telemetry is disabled. Vivado 2025.2 built the standalone variant for xczu7ev-fbvb900-2-i with ENABLE_UART_TELEMETRY=false and ENABLE_DCI_STARTUP=true. The runtime XDC uses Enclustra's reference DIFF_SSTL12_DCI clock standard, STARTUPE3/DCIRESET calibration sequencing, and the confirmed carrier pin/voltage assignments. See clock-investigation.md for the clock decision.

Routed implementation passed: setup slack +0.239 ns, hold slack +0.003 ns, pulse-width slack +0.708 ns, and a 400 MHz core clock. There are zero no-clock pins and zero unconstrained internal endpoints. Only the asynchronous receiver first-stage D pins are false-pathed; later synchronizer stages are timed and ASYNC_REG is verified. DRC has no errors or critical warnings; four warnings remain inside generated debug IP. CDC has informational synchronizers and four clock-enable warnings inside the generated debug-hub FIFO. Bus-skew constraints passed. The two asynchronous encoded TX outputs have no external output-delay constraint; these results do not certify external signal skew or analog operation.

Artifacts are V:/spacewire-only/spacewire.bit and spacewire.ltx, with reports under V:/spacewire-only/reports. scripts/build_spacewire.tcl performs synthesis/routing, scripts/finish_spacewire.tcl checks the implementation and exports artifacts, and scripts/start_spacewire.tcl programs the explicitly selected JTAG serial and enables VIO control 0x010C. Open-Vivado.cmd now selects this standalone project.

The XCZU7 target on Digilent cable 210299BFE26A was programmed successfully, and ILA/VIO cores were discovered. Twenty VIO samples showed control 0x010C and status 0x0000/0x0001 (idle/started), without Run. Start and autostart are enabled, the configured Run target is 200 Mbit/s, and test payload generation is off. The user confirmed that the remote endpoint is disconnected or powered off. Physical link establishment, packet exchange and sustained 200 Mbit/s operation remain unverified.

Programming is volatile JTAG configuration; boot media was not modified. A later read-only ILA capture attempt found DONE=0 and no debug cores, so no capture was obtained from that attempt. The startup script was rerun successfully: startup status HIGH, ILA/VIO detected, and twenty more status samples confirmed idle/started with control 0x010C. The reason for the intervening configuration loss was not established. Do not infer that the design survives power cycling.

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

## Custom-carrier MIO confirmation (2026-10-15)

The user confirmed VCC_CFG_MIO = 3.3 V. The telemetry recipe now defaults PS
banks 501/503 to LVCMOS33 while banks 500/502 remain LVCMOS18. On this workstation,
Vivado 2025.2 regenerated the board project in `V:/vivado-mio33`, asserted the
MIO settings, force-validated the block design, regenerated its output products
and exported an updated software-only XSA without a stale-design warning.
`Open-Vivado.cmd` selects this updated project. The prior successful structural
synthesis in `V:/vivado` predates the MIO setting change; synthesis was not
repeated for this configuration-only update. No implementation, bitstream or
hardware test was performed. The bank-65 PL clock standard remains unresolved.
