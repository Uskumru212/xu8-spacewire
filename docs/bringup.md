# Board bring-up and diagnostics

This procedure is prepared for future hardware work. No bitstream or physical test has been completed.

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

Start with traffic disabled, confirm rail voltages and oscillator, then observe initialization and stable Run at both endpoints. Record error counters. Enable a compatible test payload, check that the remote device actually receives complete expected packets and that return packets arrive. A local Run flag or TX FIFO count alone does not prove remote delivery. Capture disconnect/reconnect behavior and sustained error counts under the intended operating conditions. Record cable, device settings, payload, duration and measured rate in a new validation report.

## SOM UART log

The candidate board now includes PS UART0 telemetry and a standalone OCM application. See [UART setup and limits](uart.md). No physical analyzer or UART connection has been made.
