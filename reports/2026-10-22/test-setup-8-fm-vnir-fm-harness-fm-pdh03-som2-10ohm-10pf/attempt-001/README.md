# Test Setup 8 — FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF

Attempt-001, 2026-10-22. **Local checks passed; remote receipt and payload
integrity remain unverified.**

| Measurement | Result |
| --- | --- |
| Nominal local TX rate | 200 Mbit/s, divider 1, configured 400 MHz core clock |
| Verified control after reset | 0x010C; payload enabled with 0x011C |
| Observation duration | 121.666 s |
| JTAG cable / FPGA | 210299BBA502 / xczu7 |
| Periodic status readings | 8, all 0x0004 (Run=1) |
| Falling-Run capture | None; ILA remained waiting for trigger |
| Local TX FIFO acceptance increase | 1,251 characters: 1,250 data bytes + EOP |
| Payload size | 10,000 bits, one finite packet |
| TX packet-marker increase | 1 |
| RX character / packet increases | 0 / 0 |
| Parity / disconnect / escape / credit error increases | 0 / 0 / 0 / 0 |
| Run reentry increase | 0 |
| Script exit code | 0 |

The previous continuous connection monitor was stopped and released JTAG
before this fresh programming/test. Its status observations are separate
from this result. Setup 8 is a new user-assigned test ID; earlier Setup 7
attempts retain their original startup/debug failure results.

The standalone PL bitstream has UART disabled and UNUSEDPIN PULLNONE.
SHA-256: 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.

Endpoint reset control 0x010F was applied for 100 ms, then 0x010C read back.
The startup gate allowed 600 polls with 100 ms waits plus debug overhead.
Run was observed before arming the event monitor and enabling the source once.
All baseline counters were zero. The payload increments modulo 256 and ends
with EOP; wire encoding adds overhead beyond the requested payload bits.

The ILA used 1,024 samples, configured 400 MHz sample clock, trigger position
512, and eq16'bXXXXXXXXXXXXXFXX: falling Run at bit 2, other bits ignored.
Baseline and final immediate snapshots are separate from this event monitor.
Monitoring after the debug session closes is not assumed.

TX counters measure local FIFO acceptance, not remote acknowledgement.
RX remained zero; no echo or receiver payload comparison was obtained.
Physical wire speed, sustained throughput and peer TX rate were not measured.
FM.VNIR, FM.Harness, SOM2, 10 ohm and 10 pF are user-provided labels;
board identities and component values/placement were not independently measured.

At completion payload generation is off (0x010C), but link start/autostart
remain enabled, so SpaceWire link-control traffic can continue.
The former continuous host monitor is no longer running.

Evidence:

- [Metadata](setup_metadata.json) and [counter summary](result_summary.json).
- [Original Vivado log](vivado_test.log) and [journal](vivado_test.jou).
- [Executed script](run_test.tcl).
- [Baseline](payload_start.csv) and [final](payload_end.csv), each 1,024 samples.
- [SHA-256 manifest](SHA256SUMS), covering seven runtime evidence files.

Original log paths/timestamps preserved; metadata uses Europe/Berlin.
Replaying the script programs the target specified by SPW_JTAG_SERIAL,
using SPW_BUILD_DIR and SPW_TEST_REPORT_DIR. Use a new directory for repeats.
