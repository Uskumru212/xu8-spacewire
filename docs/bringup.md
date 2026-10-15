# Board bring-up and diagnostics

The standalone SpaceWire variant was routed and loaded through JTAG on 2026-10-15. With VIO start/autostart enabled, Run=1 remained asserted throughout a 30-second observation and an ILA capture was saved. Packet delivery and throughput remain unverified. See [validation.md](validation.md) for current results. The checklist below also applies to future rebuilds.

## Before implementation

1. Activate an appropriate Vivado license and verify the target device installation.
2. Resolve the exact R3 clock-bank electrical configuration in `docs/hardware.md`.
3. Create the candidate board project in a fresh `build/vivado` directory. Generate/check the clock, VIO and ILA IP interfaces against `xu8_spacewire_top.vhd`.
4. Review and enable the candidate XDC only after electrical settings are complete. Review receiver first-stage asynchronous constraints and synchronizer placement.
5. Synthesize, implement and inspect DRC, CDC, clock interaction, unconstrained paths, setup/hold timing, utilization and the 400 MHz clock. No false-path shortcuts around the protocol datapath. If 400 MHz fails, revise architecture/pipelining and rerun behavioral tests.
6. Generate a bitstream only after those checks pass. Connect the verified Digilent cable and confirm the exact target before programming.

## VIO control word

`spw_vio.probe_out0` is 16 bits. Initial value in the IP recipe is `0x010C`.

| Bits | Meaning |
| --- | --- |
| 0 | Synchronous endpoint reset; also clears counters |
| 1 | Link disable |
| 2 | Link start |
| 3 | Auto start |
| 4 | Test packet source enable, initially 0 |
| 7:5 | Reserved, keep 0 |
| 15:8 | Transmit divider, initially 1 |

At 400 MHz the Run-state bit rate is `400 / (divider + 1)` Mbit/s. Use divider 1 for 200, 3 for 100, or 39 for 10 Mbit/s. Initialization uses 10 Mbit/s regardless of the Run divider. Do not use divider 0 for this 200 Mbit/s receiver configuration. A rate change is latched while not in Run, so disable the link, set the divider, then re-enable it. It does not configure the remote device's transmitter.

`0x010C`: link enabled, start and auto-start high, 200 Mbit/s target, test traffic off.

`0x011C`: same, test packets enabled. Use only when the remote endpoint can accept the defined payload. Disabling the generator lets its current packet finish; link loss/reset aborts that packet and the next one starts at byte 0.

Rail enables remain high during endpoint reset or link disable. The top offers no software rail-off control or sequencing.

## ILA probes

| Probe | Width | Layout |
| --- | --- | --- |
| 0 | 16 | Status word below |
| 1 | 320 | Ten unsigned saturating 32-bit counters, index 0 in bits 31:0 |
| 2 | 20 | 19 RX-valid, 18 RX-flag, 17:10 RX-data, 9 TX-valid, 8 TX-flag, 7:0 TX-data |
| 3 | 4 | 3 Data-in, 2 Strobe-in, 1 Data-out, 0 Strobe-out |

Probe 3's inputs are asynchronous observations; ILA does not replace an oscilloscope or provide analog skew measurement. TX-valid without TX-ready is not a completed transfer. Use FIFO acceptance counters for TX progress; probe 2 intentionally omits ready.

| Status bit | Meaning |
| --- | --- |
| 0 | Started |
| 1 | Connecting |
| 2 | Running |
| 3 | RX valid |
| 4 | Disconnect error |
| 5 | Parity error |
| 6 | Escape error |
| 7 | Credit error |
| 8 | TX FIFO half full |
| 9 | RX FIFO half full |
| 10 | Received time-code pulse |
| 15:11 | Reserved zero |

| Counter index | Meaning |
| --- | --- |
| 0 | TX characters accepted into FIFO, including packet markers |
| 1 | TX EOP/EEP markers accepted into FIFO |
| 2 | RX characters consumed, including packet markers |
| 3 | RX EOP/EEP consumed |
| 4 | RX EEP consumed |
| 5 | Parity-error events |
| 6 | Disconnect-error events |
| 7 | Escape-error events |
| 8 | Credit-error events |
| 9 | Reentries to Run, excluding the first successful connection after reset |

Counters saturate at 0xFFFFFFFF. Error events count rising assertions. The endpoint exposes time-code data/control on its streaming wrapper, but the board ILA only observes the pulse. Board RX-ready is always high.

## Physical test sequence

For a finite 10,000-payload-bit test, use a separate build directory and set SPW_TEST_10KBIT=1 when running scripts/build_spacewire.tcl, then run scripts/finish_spacewire.tcl. The resulting source emits exactly 1,250 incrementing bytes (modulo 256) followed by one EOP for each explicit enable request. scripts/test_10kbit.tcl verifies the build generics, loads the bitstream, waits for Run, takes a baseline counter snapshot, arms falling Run with 512 pre-trigger samples, and enables one packet. It observes for two minutes, saves any disconnect waveform, disables new packet requests, takes final counters and rearms the falling-edge trigger. No UART or boot-media changes are needed. TX character counters include EOP and count FIFO acceptance, not remote delivery: expect 1,251 TX characters and one TX packet for a completed local submission. A receiver capture or echo with payload checking is needed for delivery verification. Wire coding and control symbols are additional to the 10,000 payload bits.

For intermittent link drops, scripts/monitor_disconnect.tcl arms the existing ILA on the falling edge of status bit 2 (Run), with trigger position 512 in the 1,024-sample buffer. This preserves about 1.28 us of pre-trigger history at 400 MHz. It monitors for two minutes and leaves the hardware armed if no event occurs. A completed event is exported to reports/run_falling_edge.csv. This is an event-triggered capture, not a continuous two-minute waveform; rearming or reprogramming discards the pending capture.

Start with traffic disabled, confirm rail voltages and oscillator, then observe initialization and stable Run at both endpoints. Record error counters. Enable a compatible test payload, check that the remote device actually receives complete expected packets and that return packets arrive. A local Run flag or TX FIFO count alone does not prove remote delivery. Capture disconnect/reconnect behavior and sustained error counts under the intended operating conditions. Record cable, device settings, payload, duration and measured rate in a new validation report.

## SOM UART log

The optional board variant includes PS UART0 telemetry and a standalone OCM application. See [UART setup and limits](uart.md). UART is disabled in the current standalone SpaceWire build; the UART target application has not been run. JTAG VIO access has been verified.
