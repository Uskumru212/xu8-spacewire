# Test Setup 1 — EM.VNIR_EM.Harness_ FM.PDH.03_SOM1_10Ω

Attempt-002, 2026-10-16. Fresh hardware run; attempt-001 and its original runtime
files were deleted at the user's request. Other board records were retained.

**Local checks passed. Remote delivery and payload correctness are unverified.**

| Measurement | Result |
| --- | --- |
| JTAG cable / enumerated FPGA | 210299BFE26A / xczu7 |
| Observation duration | 120.844 s |
| Periodic Run readings | 8, all Run=1 (`0x0004`) |
| Falling-Run event capture | None; ILA remained waiting for trigger |
| TX FIFO character increase | 1,251, including one EOP |
| Payload accepted into local TX FIFO | 1,250 bytes = 10,000 payload bits |
| TX packet-marker increase | 1 |
| RX character / packet-marker increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The source was enabled once after Run was observed and the falling-edge trigger
was armed. Baseline counters were all zero. Test payload generation was disabled
after observation, leaving control `0x010C` (start/autostart enabled). The TX
counters measure local FIFO acceptance, not remote acknowledgement. No echo or
receiver payload check was obtained, and physical throughput was not measured.

Configuration: standalone PL, UART off, `UNUSEDPIN PULLNONE`, nominal 200 Mbit/s
Run target. Bitstream SHA-256:
`741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97`.
The one-shot emits incrementing bytes modulo 256 and one EOP. Wire coding/control
bits are additional. The ILA uses 1,024 samples at a configured 400 MHz clock,
trigger position 512, and `eq16'bXXXXXXXXXXXXXFXX` (falling Run on bit 2).
Monitoring after the debug session closes is not assumed.

The setup name and 10 ohm value were provided by the user. Resistor location and
electrical values were not independently measured. Raw logs keep original host
timestamps; metadata includes Europe/Berlin timestamps.

Evidence:

- [Setup metadata](setup_metadata.json) and [result summary](result_summary.json).
- [JTAG inventory](jtag_inventory.log).
- [Vivado log](vivado_test.log) and [command journal](vivado_test.jou).
- [Baseline](payload_start.csv) and [final](payload_end.csv) ILA snapshots,
  each containing 1,024 data rows. These immediate counter snapshots are separate
  from the falling-Run event trigger used during the observation interval.
- [Executed test script](run_test.tcl) and [inventory script](inventory.tcl).
- [SHA-256 checksums](SHA256SUMS) for all nine original runtime evidence files.

Replaying run_test.tcl programs the FPGA selected by SPW_JTAG_SERIAL, using
SPW_BUILD_DIR for the build and SPW_TEST_REPORT_DIR for outputs. Preserve this
record by selecting a new output directory for another run.
