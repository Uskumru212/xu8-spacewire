# Interrupted Setup 3 attempt-001 — 100 Mbit/s

The original setup label was EM.VNIR_EM.Harness_ FM.PDH.03.100M_SOM1_0Ω.
The user corrected the requested speed to 200 Mbit/s during observation.
This attempt was stopped and superseded by the separately recorded 200 Mbit/s
attempt-002. It is neither a completed pass nor a completed failure.

The script verified divider 3 and control 0x030C after endpoint reset, enabled
the finite payload, and recorded seven Run=1 readings through 105.689 seconds.
There was no final counter snapshot, so completed transmission counts and
remote delivery cannot be determined. Do not use this partial evidence as
a 200 Mbit/s result.

The first inventory found no FPGA; the retry enumerated xczu7 using cable
210299BFE26A. Both inventory logs are retained. The [result summary](result_summary.json),
[metadata](setup_metadata.json), raw scripts/logs and available baseline snapshot
are preserved. [SHA256SUMS](SHA256SUMS) records their copied evidence hashes.
