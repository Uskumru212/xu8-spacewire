# Test Setup 7 — FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF

Attempt-002, 2026-10-19. **Run was not observed during the startup gate.
No payload was enabled; the two-minute stability test did not start.**

This fresh repeat used cable 210299BBA502 and enumerated xczu7_0 (PART=xczu7).
Programming succeeded. Nominal 200 Mbit/s (divider 1, configured 400 MHz clock)
was verified by reading control 0x010C after the 100 ms endpoint reset.
The startup gate made 600 polls, each with a 100 ms wait plus debug overhead.
It exited with code 1 before the baseline ILA snapshot or payload enable.

Brief Run episodes between polls cannot be excluded. No final counters,
falling-Run capture, payload receipt or throughput measurements were obtained.
This is an incomplete payload/stability test, not a confirmed physical cause.
The result matches attempt-001, whose evidence remains unchanged.

Control remains 0x010C: payload off, link start/autostart enabled.
Link-control traffic may continue. SOM2, 10 ohm and 10 pF are user-provided
labels; component placement/value and board identity were not measured.

Same standalone PL bitstream as attempt-001: UART off, UNUSEDPIN PULLNONE.
SHA-256: 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.
The script configures a 10,000-bit payload and 1,024-sample falling-Run trigger
eq16'bXXXXXXXXXXXXXFXX if the startup gate succeeds.

Evidence:

- [Metadata](setup_metadata.json) and [result summary](result_summary.json).
- [Original Vivado log](vivado_test.log) and [journal](vivado_test.jou).
- [Executed script](run_test.tcl).
- [SHA-256 manifest](SHA256SUMS) for five runtime evidence files.

No CSV captures were created. Logs preserve original host paths/timestamps;
metadata uses Europe/Berlin. Use a new attempt directory for a repeat.
