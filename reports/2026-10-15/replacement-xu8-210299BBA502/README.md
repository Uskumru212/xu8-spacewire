# Replacement XU8 hardware test - 2026-10-15

**Result: unstable SpaceWire link. The 10,000-bit payload was not enabled.**

This evidence belongs to the replacement XU8 on Digilent JTAG cable
`210299BBA502`. Earlier passing tests used cable `210299BFE26A`; they must not
be attributed to this replacement.

## Configuration

- User-confirmed module: ME-XU8-7EV-2I-D12E, same carrier, pinout and supply voltages.
- User confirmed that the remote SpaceWire device was powered and connected.
- JTAG enumerated `xczu7_0` (`PART=xczu7`) and `arm_dap_1`.
- Vivado 2025.2; JTAG 5 MHz; standalone PL build with UART disabled.
- Regenerated bitstream uses `BITSTREAM.CONFIG.UNUSEDPIN PULLNONE`.
- Bitstream SHA-256: `741C3A356BBFBB95B15EDEFD026CAB8DF4213BF69C3CE18C8A032F80C07EEA97`.
- VIO control `0x010C`: link start/autostart on, nominal 200 Mbit/s Run target,
  packet generator off. Physical throughput was not measured.
- ILA: 1,024 samples, configured 400 MHz sampling clock, trigger position 512.
- Trigger: `eq16'bXXXXXXXXXXXXXFXX`, falling edge of `running` (status bit 2).
  All other bits are ignored. `F` is a binary edge symbol, not hexadecimal 0xF.

## Test sequence and results

1. [JTAG inventory](logs/spacewire-new-board-inventory.log) identified the replacement target.
2. [Finite-payload test attempt](logs/spacewire-replacement-210299BBA502.log)
   successfully programmed the FPGA and accessed ILA/VIO. Its initial ten-second
   polling gate did not observe Run, so it exited before enabling the packet source.
   This is not evidence that Run never occurred between polls.
3. [Diagnostic polling and captures](logs/spacewire-replacement-diagnostic.log)
   sampled idle/started states for about 30 seconds and saved four ILA windows.
   RX D/S transitions were present. The first diagnostic window's counters were:

   | Counter | Value |
   | --- | ---: |
   | TX characters / packet markers | 0 / 0 |
   | RX characters / packet markers / EEP | 18 / 8 / 8 |
   | Parity errors | 90 |
   | Credit errors | 2,545 |
   | Disconnect / escape errors | 0 / 0 |
   | Run reentries | 93 |

   Run reentries show that short Run episodes were missed by status polling.
   Nonzero RX counters do not establish valid payload reception.
4. [Local endpoint reset retry](logs/spacewire-replacement-link-retry.log)
   asserted VIO endpoint reset (`0x010D`) for 100 ms, then restored `0x010C`.
   It took 30 status readings at 100 ms intervals without observing stable Run.
   This reset clears counters, so later counts are not cumulative with step 3.
5. [Falling-Run monitor](logs/spacewire-replacement-falling-run.log) captured a
   real failure after 2.346 seconds. The [waveform CSV](captures/run_falling_edge.csv)
   contains:

   | Sample in buffer | TRIGGER | Status | Run | Parity error |
   | --- | ---: | --- | ---: | ---: |
   | 510 | 0 | `0x0004` | 1 | 0 |
   | 511 | 0 | `0x0024` | 1 | 1 |
   | 512 | 1 | `0x0000` | 0 | 0 |

   Across this window, the parity counter increases 47 to 48 and Run reentries
   increase 46 to 47. Credit errors remain 1,581. TX characters and packet markers
   remain zero. The timeout-specific disconnect counter is zero, but the captured
   Run falling edge directly demonstrates a link drop following a parity error.

## Evidence and interpretation

- [Machine-readable summary](test_summary.json).
- [Four diagnostic windows](captures/) and the falling-edge waveform, each with
  1,024 data samples plus CSV header/radix rows.
- [Exact Tcl scripts used](scripts/), retained as executed, including their
  machine-local paths. Build artifacts are not included. Scripts use
  `SPW_BUILD_DIR` and `SPW_JTAG_SERIAL`; replaying the finite-test script programs
  the selected FPGA, and the retry script resets its endpoint.
- [SHA-256 checksums](SHA256SUMS) cover the 16 original log, CSV, Tcl and JSON
  evidence files. They were copied byte-for-byte. Local Git attributes preserve
  their line endings. Logs retain original host timestamps and paths.

The waveform proves a parity-error assertion immediately before Run drops.
It does not identify the physical cause. Module/carrier hardware, wiring,
remote configuration and signal integrity have not been isolated from one another.
No test payload was transmitted, and remote receipt, payload correctness and
throughput were not verified. Start/autostart were left enabled, with packet
generation disabled. Monitoring after closing the debug session is not assumed.
