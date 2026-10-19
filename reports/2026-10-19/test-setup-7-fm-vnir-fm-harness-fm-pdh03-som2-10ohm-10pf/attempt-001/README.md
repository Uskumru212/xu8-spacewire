# Test Setup 7 — FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF

Attempt-001, 2026-10-19. **Startup Run gate not satisfied. The 10,000-bit
payload test and two-minute falling-Run observation did not start.**

| Check | Result |
| --- | --- |
| JTAG target | 210299BBA502, the only enumerated cable |
| FPGA | xczu7_0, PART=xczu7 |
| Programming | Succeeded; ILA and VIO present |
| Nominal local TX rate | 200 Mbit/s, divider 1, configured 400 MHz core clock |
| Verified control after endpoint reset | 0x010C |
| Startup polling | 600 polls with 100 ms waits plus debug overhead |
| Run observed during startup polling | No |
| Payload enabled | No |
| Falling-Run monitor armed | No; startup gate exited first |
| Final counter capture | Not available |
| Script exit code | 1 |
| Physical link/payload test verdict | Not completed |

The bitstream and startup procedure match Setup 5/6. Endpoint reset control
0x010F was applied for 100 ms, followed by verified 0x010C. The nominal
60-second startup gate did not observe Run. Brief Run episodes between polls
cannot be excluded; this does not prove that Run never occurred. No falling-Run
waveform, final error counters or completed payload counts were obtained.
No two-minute stability or successful transmission claim can be made.

Control remains 0x010C: test payload disabled, start/autostart enabled.
Link-control traffic may continue. This attempt did not measure throughput,
remote reception, payload integrity or the cause of the startup failure.

FM.VNIR, FM.Harness, SOM2, 10 ohm and 10 pF are user-provided setup labels.
Board identities, component values and locations were not independently
measured. JTAG identifies the cable. No Measboard label was supplied.

Standalone PL bitstream: UART disabled, UNUSEDPIN PULLNONE. SHA-256:
741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.

Evidence:

- [Metadata](setup_metadata.json) and [result summary](result_summary.json).
- [Vivado test log](vivado_test.log) and [journal](vivado_test.jou).
- [Executed test script](run_test.tcl), configured to use 1,024 ILA samples
  and eq16'bXXXXXXXXXXXXXFXX for falling Run if the startup gate succeeds.
- [Target inventory log](inventory.log), [journal](inventory.jou) and
  [executed inventory script](inventory.tcl).
- [SHA-256 manifest](SHA256SUMS), covering eight runtime evidence files.

No CSV captures were created because execution stopped before the baseline
snapshot. Logs preserve host paths/timestamps; metadata uses Europe/Berlin.
Use a new attempt directory for a repeat. Earlier setup records are preserved.
