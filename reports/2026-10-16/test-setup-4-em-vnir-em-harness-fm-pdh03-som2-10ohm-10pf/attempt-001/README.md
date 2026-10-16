# Test Setup 4 — EM.VNIR_EM.Harness_ FM.PDH.03_SOM2_10Ω+10pF

Attempt-001, 2026-10-16. **Local checks passed. Remote receipt and payload
integrity remain unverified.**

| Measurement | Result |
| --- | --- |
| Local nominal TX rate | 200 Mbit/s, divider 1 from configured 400 MHz clock |
| Verified control after endpoint reset | 0x010C; payload enable 0x011C |
| Observation duration | 121.166 s |
| JTAG cable / programmed FPGA | 210299BFE26A / xczu7 |
| Periodic status readings | 8, all 0x0004 (Run=1) |
| Falling-Run event | None; ILA remained waiting for trigger |
| TX FIFO character increase | 1,251, including one EOP |
| Payload accepted into local TX FIFO | 1,250 bytes = 10,000 bits |
| TX packet-marker increase | 1 |
| RX character / packet increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The FPGA was programmed with the standalone PL finite-packet bitstream, UART off
and UNUSEDPIN PULLNONE. Control 0x010F reset the endpoint for 100 ms, then 0x010C
was read back. Run was checked before the falling-edge monitor was armed and
the source enabled once. Baseline counters were zero. Packet generation was
disabled at completion, leaving control 0x010C.

The ILA used 1,024 samples, configured 400 MHz sample clock, trigger position 512,
and eq16'bXXXXXXXXXXXXXFXX: falling Run at bit 2, other bits ignored. Baseline
and final immediate snapshots are separate from the event monitor. Persistent
monitoring after the session closes is not assumed.

TX counters show local FIFO acceptance, not receiver acknowledgement. RX stayed
zero; no receiver payload comparison or echo was obtained. Physical wire speed,
sustained throughput and the peer TX rate were not independently measured.
The source sends incrementing bytes modulo 256 followed by EOP; wire encoding
adds overhead beyond the 10,000 payload bits.

SOM2, 10 ohm and 10 pF are user-provided setup labels. Component placement/value
and SOM identity were not independently measured. The JTAG serial identifies
the cable. Earlier setup evidence was preserved.

Bitstream SHA-256:
741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.

Evidence:

- [Metadata](setup_metadata.json) and [counter summary](result_summary.json).
- [Original Vivado log](vivado_test.log) and [journal](vivado_test.jou).
- [Baseline](payload_start.csv) and [final](payload_end.csv) ILA snapshots,
  each containing 1,024 data samples.
- [Executed test script](run_test.tcl).
- [Inventory helper](inventory.tcl), copied for reproducibility but not executed
  in this attempt; target/programming evidence is in the Vivado test log.
- [SHA-256 manifest](SHA256SUMS), covering eight runtime evidence files.

Logs retain original host paths and timestamps; metadata uses Europe/Berlin.
Replaying the test script programs the target selected by SPW_JTAG_SERIAL,
using SPW_BUILD_DIR and SPW_TEST_REPORT_DIR. Use a new directory for a repeat.
