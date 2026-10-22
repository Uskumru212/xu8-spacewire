# Setup 7 attempt-007 — ILA clock stopped before payload

2026-10-21. FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF.
Cable 210299BBA502 / xczu7. Programming succeeded and nominal 200 Mbit/s
divider/control was verified (0x010C after endpoint reset).

Vivado then reported:
ERROR: [Labtools 27-3428] Ila core [hw_ila_1] clock has stopped. Unable to arm ILA core.

The process exited with code 1 before recording any payload-enable marker or
CSV capture. The two-minute falling-Run test did not start. No stable-Run,
payload delivery, final counter or throughput result can be claimed.
This is a debug-clock error, not a captured SpaceWire link-drop waveform;
its physical cause is unconfirmed. Earlier attempts are preserved.

Last verified control 0x010C: payload off, link start/autostart enabled.
Final hardware state was not recovered after the clock error.

Same standalone PL bitstream: UART off, UNUSEDPIN PULLNONE.
SHA-256: 741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97.
SOM2, 10 ohm and 10 pF are user-provided labels, not independent measurements.

Evidence: [original log](vivado_test.log), [journal](vivado_test.jou),
[executed script](run_test.tcl), [metadata](setup_metadata.json),
[summary](result_summary.json), [checksums](SHA256SUMS).
Five runtime evidence files copied byte-for-byte. No CSV captures.
