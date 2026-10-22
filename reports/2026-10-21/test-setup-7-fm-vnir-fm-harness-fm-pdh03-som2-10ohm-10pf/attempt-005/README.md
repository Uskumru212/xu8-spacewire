# Setup 7 attempt-005 — startup Run not observed

2026-10-21. FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF.
Fresh retry after attempt-004's startup Run failure. Cable 210299BBA502 / xczu7.

Programming succeeded. Nominal local TX rate 200 Mbit/s (divider 1 from
configured 400 MHz clock) was verified as control 0x010C after endpoint reset.
The startup gate made 600 polls with 100 ms waits plus debug overhead.
Run was not observed; the script exited with code 1 before enabling payload.
The two-minute falling-Run test did not start. No baseline/final CSV captures,
final error counters, payload delivery or throughput results were obtained.
Brief Run episodes between polls cannot be excluded.

Control remains 0x010C: payload off, link start/autostart on.
Link-control traffic may continue. SOM2, 10 ohm and 10 pF are user-provided
labels, not independently measured identities/component values.

Same standalone PL bitstream: UART off, UNUSEDPIN PULLNONE.
SHA-256: 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.
Configured finite payload is 1,250 bytes plus EOP, with a 1,024-sample ILA
falling-Run trigger eq16'bXXXXXXXXXXXXXFXX if the startup gate succeeds.

Evidence: [metadata](setup_metadata.json), [summary](result_summary.json),
[original log](vivado_test.log), [journal](vivado_test.jou),
[executed script](run_test.tcl), [SHA-256 manifest](SHA256SUMS).
Five runtime evidence files copied byte-for-byte. Original host paths and
timestamps preserved. Metadata uses Europe/Berlin. Earlier attempts preserved.
