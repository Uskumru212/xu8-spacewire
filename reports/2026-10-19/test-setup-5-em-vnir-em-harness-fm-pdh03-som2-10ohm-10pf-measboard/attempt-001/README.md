# Test Setup 5 — EM.VNIR_EM.Harness_ FM.PDH.03_SOM2_10Ω+10pF_Measboard

Attempt-001, 2026-10-19. **Local checks passed. Remote receipt and payload
integrity remain unverified.**

| Measurement | Result |
| --- | --- |
| Local nominal TX rate | 200 Mbit/s, divider 1 from configured 400 MHz clock |
| Control verified after endpoint reset | 0x010C; payload enabled using 0x011C |
| Observation duration | 121.147 s |
| JTAG cable / programmed FPGA | 210299BFE26A / xczu7 |
| Periodic status readings | 8, all 0x0004 (Run=1) |
| Falling-Run capture | None; ILA remained waiting for trigger |
| Local TX FIFO acceptance increase | 1,251 characters: 1,250 data bytes and EOP |
| Payload size | 10,000 bits, one finite packet |
| TX packet-marker increase | 1 |
| RX character / packet increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The same PULLNONE standalone PL bitstream used in earlier named tests was
programmed, with UART disabled. Endpoint reset control 0x010F was applied
for 100 ms, then 0x010C was read back. The startup check allowed 600 polls
at 100 ms plus debug-access overhead (nominal 60 seconds). Run was observed
before enabling the source once. All baseline counters were zero.

The ILA used 1,024 samples, configured 400 MHz sample clock and trigger position
512. The expression eq16'bXXXXXXXXXXXXXFXX triggers on falling Run at bit 2,
ignoring other bits. Baseline/final immediate snapshots are separate from the
falling-edge event monitor. Continued monitoring after closing the debug
session is not assumed.

Packet generation is off at completion (control 0x010C). Link start/autostart
remain enabled, so SpaceWire link-control traffic can continue.

TX counters measure local FIFO acceptance, not remote acknowledgement. No echo
or receiver payload comparison was obtained. Physical wire speed, sustained
throughput and peer TX rate were not independently measured. Payload bytes
increment modulo 256, followed by EOP; wire encoding adds overhead.

SOM2, 10 ohm, 10 pF and Measboard are user-provided setup labels. Their placement,
values and board identities were not independently verified; JTAG identifies
the cable. Earlier setup records were preserved.

Bitstream SHA-256:
741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.

Evidence:

- [Setup metadata](setup_metadata.json) and [counter summary](result_summary.json).
- [Original Vivado log](vivado_test.log) and [journal](vivado_test.jou).
- [Baseline](payload_start.csv) and [final](payload_end.csv), each 1,024 samples.
- [Executed test script](run_test.tcl).
- [SHA-256 manifest](SHA256SUMS) covering seven runtime evidence files.

Logs retain host paths and timestamps; metadata uses Europe/Berlin timestamps.
Replaying the script programs the target specified by SPW_JTAG_SERIAL, using
SPW_BUILD_DIR and SPW_TEST_REPORT_DIR. Use a new directory for any repeat.
