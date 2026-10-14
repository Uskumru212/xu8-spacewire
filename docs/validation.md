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

The eight behavioral scenarios are one default upstream bench, two high-rate upstream bench instances, one packet-source bench and four endpoint configurations. `scripts/run_ghdl.ps1` checks explicit completion markers rather than treating a stop-time as success. Logs are regenerated under `build/ghdl` and excluded from Git.

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
