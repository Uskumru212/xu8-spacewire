# Test Setup 6 — EM.VNIR_EM.Harness_ FM.PDH.ARCBOX_Measboard

Attempt-001, 2026-10-19. **Local checks passed. Remote receipt and payload
integrity remain unverified.**

| Measurement | Result |
| --- | --- |
| Local nominal TX rate | 200 Mbit/s, divider 1 from configured 400 MHz clock |
| Control verified after endpoint reset | 0x010C; payload enabled using 0x011C |
| Observation duration | 121.382 s |
| JTAG cable / programmed FPGA | 210299BFE5B4 / xczu7 |
| Periodic status readings | 8, all 0x0004 (Run=1) |
| Falling-Run capture | None; ILA remained waiting for trigger |
| Local TX FIFO acceptance increase | 1,251 characters: 1,250 data bytes and EOP |
| Payload size | 10,000 bits, one finite packet |
| TX packet-marker increase | 1 |
| RX character / packet increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Completed test process exit code | 0 |

The initial connection attempt selected the previous cable 210299BFE26A, which
was absent; no programming or payload occurred in that process. Read-only
target discovery found exactly one cable, 210299BFE5B4. Device inventory found
xczu7_0 (PART=xczu7) and arm_dap_1. The subsequent test selected that cable,
programmed the FPGA and completed. Original connection and discovery logs
are retained separately from the successful run.

The same standalone PL bitstream as earlier tests was used: UART disabled,
UNUSEDPIN PULLNONE. SHA-256:
741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.

Control 0x010F asserted endpoint reset for 100 ms, then 0x010C was read back.
Startup allowed 600 polls at 100 ms plus debug overhead (nominal 60 seconds).
Run was checked before enabling the source once. Baseline counters were zero.

The ILA used 1,024 samples, configured 400 MHz clock, trigger position 512,
and eq16'bXXXXXXXXXXXXXFXX (falling Run at bit 2, other bits ignored).
Baseline/final immediate snapshots are separate from the event monitor.
Continued monitoring after the debug session closes is not assumed.

The payload increments modulo 256 and ends with EOP. TX counts measure local
FIFO acceptance, not remote acknowledgement. RX remained zero; no echo or
receiver payload comparison was obtained. Wire speed, sustained throughput
and peer TX rate were not independently measured.

ARCBOX and Measboard are user-provided setup labels. SOM identity, resistor
and capacitor values were not specified for this setup and are not inherited
from Setup 5. JTAG identifies the cable, not the board identity.

Packet generation is off at completion (0x010C). Link start/autostart remain
enabled, so link-control traffic can continue.

Evidence:

- [Metadata](setup_metadata.json) and [counter summary](result_summary.json).
- [Completed test log](vivado_retry.log) and [journal](vivado_retry.jou).
- [Initial connection failure](vivado_test.log) and [journal](vivado_test.jou).
- [Target discovery](inventory.log), [journal](inventory.jou), [script](inventory.tcl).
- [Device inventory](inventory_device.log), [journal](inventory_device.jou),
  [script](inventory_device.tcl).
- [Baseline](payload_start.csv) and [final](payload_end.csv), 1,024 samples each.
- [Executed test script](run_test.tcl).
- [SHA-256 manifest](SHA256SUMS), covering 15 runtime evidence files.

Logs retain host paths/timestamps; metadata uses Europe/Berlin.
Replay uses SPW_JTAG_SERIAL, SPW_BUILD_DIR and SPW_TEST_REPORT_DIR and programs
the selected FPGA. Use a new directory for any repeat.
