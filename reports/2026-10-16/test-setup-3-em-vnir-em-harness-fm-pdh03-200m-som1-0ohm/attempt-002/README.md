# Test Setup 3 — EM.VNIR_EM.Harness_ FM.PDH.03.200M_SOM1_0Ω

Attempt-002, 2026-10-16. **Local checks passed. Remote delivery and payload
integrity remain unverified.**

| Measurement | Result |
| --- | --- |
| Local nominal TX rate | 200 Mbit/s, divider 1 from configured 400 MHz core clock |
| Rate setting verified after endpoint reset | Control 0x010C; payload control 0x011C |
| Observation duration | 120.542 s |
| JTAG cable / FPGA | 210299BFE26A / xczu7 |
| Periodic status readings | 8, all 0x0004 (Run=1) |
| Falling-Run capture | None; ILA remained waiting for trigger |
| TX FIFO acceptance increase | 1,251 characters: 1,250 payload bytes plus EOP |
| Payload size | 10,000 bits, one finite packet |
| TX packet-marker increase | 1 |
| RX character / packet increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The bitstream was loaded, control 0x010F applied for 100 ms to reset the endpoint,
and control 0x010C read back before checking Run. The source was enabled once
after the falling-Run trigger was armed. Baseline counters were zero. Packet
generation was disabled at completion, leaving control 0x010C.

The rate is a configured nominal local TX rate; wire speed and sustained
throughput were not measured. TX counters measure local FIFO acceptance,
not receiver acknowledgement. No echo or receiver payload comparison was
obtained. The remote transmitter's rate was not independently verified.

The ILA used 1,024 samples, configured 400 MHz clock, trigger position 512,
and eq16'bXXXXXXXXXXXXXFXX (falling Run at bit 2). Immediate baseline and final
snapshots are separate from the falling-edge event monitor. Monitoring after
the debug session closes is not assumed.

The standalone PL bitstream has UART disabled and UNUSEDPIN PULLNONE.
SHA-256: 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.
The payload increments modulo 256, followed by EOP; wire encoding adds overhead.
SOM1 and 0 ohm are user-provided setup labels; resistor location and value
were not measured. JTAG identifies the cable, not the SOM identity.

The earlier 100 Mbit/s attempt was stopped for the user's rate correction.
Its partial results are not attributed to this completed 200 Mbit/s run.

Evidence:

- [Metadata](setup_metadata.json) and [result summary](result_summary.json).
- [Vivado log](vivado_test.log) and [journal](vivado_test.jou).
- [Baseline](payload_start.csv) and [final](payload_end.csv), each 1,024 samples.
- [Executed test script](run_test.tcl), [inventory script](inventory.tcl)
  and [JTAG inventory](jtag_inventory.log).
- [SHA-256 manifest](SHA256SUMS) for the nine runtime evidence files.

Original logs retain host paths and timestamps. Replaying the test script
programs the FPGA specified by SPW_JTAG_SERIAL, using SPW_BUILD_DIR and
SPW_TEST_REPORT_DIR. Always use a new attempt directory for a repeat.
