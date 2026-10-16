# Test Setup 2 — EM.VNIR_EM.Harness_ FM.PDH.03_SOM2_10Ω

Attempt-001, 2026-10-16. **Local checks passed; remote delivery and payload
correctness remain unverified.**

| Measurement | Result |
| --- | --- |
| JTAG cable / enumerated FPGA | 210299BFE26A / xczu7 |
| Observation duration | 120.681 s |
| Periodic status readings | 8, all `0x0004` (Run=1) |
| Falling-Run event capture | None; ILA remained waiting for trigger |
| TX FIFO character increase | 1,251, including one EOP |
| Payload accepted into local TX FIFO | 1,250 bytes = 10,000 payload bits |
| TX packet-marker increase | 1 |
| RX character / packet-marker increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The source was enabled once after Run was observed and the falling-edge trigger
was armed. Baseline counters were all zero. Packet generation was disabled at
the end, leaving VIO control `0x010C` (start/autostart enabled). TX counters
measure local FIFO acceptance, not remote acknowledgement. No echo or receiver
payload comparison was obtained. Physical throughput was not measured.

The test used the same standalone PL bitstream and procedure as Setup 1:
UART off, `UNUSEDPIN PULLNONE`, nominal 200 Mbit/s Run target. Bitstream SHA-256:
`741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97`.
The payload is incrementing bytes modulo 256 followed by EOP; wire coding and
control bits are additional to the requested 10,000 payload bits.

ILA configuration: 1,024 samples, configured 400 MHz clock, trigger position
512, and `eq16'bXXXXXXXXXXXXXFXX` (falling Run, bit 2). The hardware trigger
and error/reentry counters supplement the periodic status readings. Persistent
monitoring after the debug session closes is not assumed.

SOM2 and the 10 ohm value identify the setup specified by the user. JTAG identifies
the cable/FPGA target; it does not independently verify the SOM label. No electrical
measurement of resistor placement, resistance or unused pins was performed.

Evidence:

- [Setup metadata](setup_metadata.json) and [result summary](result_summary.json).
- [JTAG inventory](jtag_inventory.log).
- [Vivado log](vivado_test.log) and [command journal](vivado_test.jou).
- [Baseline](payload_start.csv) and [final](payload_end.csv) ILA snapshots,
  each with 1,024 data samples plus header/radix rows. These immediate snapshots
  are separate from the falling-edge event trigger used during observation.
- [Executed test script](run_test.tcl) and [inventory script](inventory.tcl).
- [SHA-256 checksums](SHA256SUMS) for nine original runtime evidence files.

Logs retain original host timestamps and paths; metadata records Europe/Berlin
timestamps. Replaying run_test.tcl programs the FPGA selected by SPW_JTAG_SERIAL,
using SPW_BUILD_DIR for the build and SPW_TEST_REPORT_DIR for outputs. Use a new
attempt directory for repeats. Setup 1's records were not modified.
