# Setup 7 attempt-003 — startup debug failure

2026-10-21. FM.VNIR_FM.Harness_ FM.PDH.03_SOM2_10Ω+10pF.
Cable 210299BBA502 / xczu7. Programming and nominal 200 Mbit/s control readback
succeeded (0x010C). During startup, refresh_hw_vio stalled for 4m41s, then
Xicom 50-38 and hw_server failure terminated the process (exit 1).

No payload-enable marker, baseline/final captures or falling-Run monitor.
The two-minute payload/stability test did not start. A SpaceWire link drop
cannot be inferred from a JTAG/debug failure. The nominal 60-second polling
budget does not bound a stalled hardware API. Physical cause is unknown.
Control was last verified as 0x010C: payload off, start/autostart on; final
hardware state was not recovered.

Evidence: [test log](vivado_test.log), [journal](vivado_test.jou),
[script](run_test.tcl), [target inventory](inventory.log),
[inventory script](inventory.tcl), [inventory journal](inventory.jou),
[metadata](setup_metadata.json), [summary](result_summary.json),
[checksums](SHA256SUMS). Eight runtime evidence files copied byte-for-byte.
No receiver receipt, payload correctness or throughput verification.
