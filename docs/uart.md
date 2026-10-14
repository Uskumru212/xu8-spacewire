# SOM UART process logging

## Physical route

The supplied schematic identifies **SOM_UART_RX = PS MIO38 (connector 105, TP615)** and **SOM_UART_TX = PS MIO39 (connector 107, TP616)**. These are PS UART0 pins; they are not assignable PL UART ports. The separate APU_UART_TX/RX on MIO48/49 is not selected.

The official [Enclustra XU8 reference](https://github.com/enclustra/Mercury_XU8_PE3_Reference_Design/blob/10271e532b01b0304ce2f3a051721485dc38a47a/scripts/Mercury_XU8_PE3_bd.tcl) also selects UART0 MIO38..39. Driver calls follow the [AMD standalone UART driver API](https://xilinx.github.io/embeddedsw.github.io/uartps/doc/html/api/group__uartps.html).

Terminal settings: **115200 baud, 8 data bits, no parity, 1 stop bit, no flow control**. Adapter RX connects to SOM TX; optional adapter TX connects to SOM RX; use a common reference ground. Confirm the actual UART voltage and any carrier level shifter before attaching the adapter. The user-confirmed 3.3 V power-enable bank is a different bank and does not establish UART voltage. The current monitor transmits only; it accepts no UART commands.

## Implemented path

`SpaceWire status/counters -> 400 MHz telemetry registers + event FIFO -> dual-clock AXI SmartConnect -> PS A53 standalone application -> UART0 MIO39`

The candidate board recipe now creates a PS subsystem with UART0 and HPM0 enabled, a 100 MHz PS-side AXI clock and a 400 MHz telemetry-side clock. SmartConnect bridges those clock domains; no unsynchronized multi-bit status bus crosses directly into the PS domain. Clock/reset propagation, address-segment inference and all IP generation remain unverified in Vivado because of the license blocker.

The test application is intentionally OCM-only, with the PS DDR controller disabled in this recipe. A generated standalone BSP/linker script must place code, data, vectors, stack and heap in the available OCM region. Do not accept a DDR linker default. No flash update or Linux image is prepared.

The telemetry block continues through an endpoint/VIO reset so it can record that reset. PS reset or clock-lock loss clears its event history, time base and overflow count. Startup PS initialization can therefore clear events that happened before the PS was initialized. The monitor is not a boot-ROM or pre-configuration recorder.

## What is logged

- Application startup and selected interface settings.
- Initial observed status, then started/connecting/running transitions.
- Disconnect, parity, escape and credit error assertions/deassertions.
- VIO control changes, including link disable, reset, divider and test traffic enable.
- Periodic coherent snapshots of all ten counters, including reconnect and EEP.
- Cumulative event-buffer loss count.

Each event contains the complete 16-bit status, 16-bit control and 32-bit free-running timestamp in **400 MHz cycles**. Timestamp wraps every 10.73741824 seconds. It is a modulo counter, not wall time. The hardware stores 64 events and drops new events when full; a saturating loss counter makes this visible. The software drains up to eight events per iteration and prints a snapshot every 100 iterations with a 10 ms delay each. UART output adds time, so the summary interval is at least one second, not an exact periodic deadline.

The monitor does not stream 200 Mbit/s payload over a 115200 baud UART. RX-valid, FIFO half-full changes and individual time-code pulses do not trigger UART events; use ILA for those. TX counters prove local FIFO acceptance, not remote delivery. Rail-enable assertions are design state, not voltage measurements. Persistent rapid faults can exceed UART capacity; inspect lost_events before interpreting the log as a complete sequence.

## Register map

PS base address in the candidate recipe and application: `0xA0000000`, 4 KiB aperture in M_AXI_HPM0_FPD's low address window. The earlier `0x80000000` address was rejected by Vivado 2025.2 address validation. Access as Device memory. One software reader owns the event pop/timestamp pair. All reads are 32-bit aligned. All writes return SLVERR.

| Offset | Read meaning |
| --- | --- |
| 0x000 | Returns SPW1 (0x53505731) and captures an atomic status/control/counter/time snapshot |
| 0x004 | Snapshot status |
| 0x008 | Snapshot control |
| 0x00C | Snapshot cycle timestamp |
| 0x010 | Register ABI version 0x00010000 |
| 0x020..0x044 | Ten snapshot counters, in the order documented in bringup.md |
| 0x100 | Pop oldest event: control in bits 31:16, status in 15:0; empty returns SLVERR |
| 0x104 | Timestamp latched by the preceding successful pop |
| 0x108 | Current event count |
| 0x10C | Cumulative dropped events since telemetry reset |

Read count before popping. Read 0x104 immediately after each pop. Responses remain stable under AXI backpressure; popping happens once when the read address is accepted, not repeatedly while RVALID is stalled. Invalid/unaligned reads return SLVERR.

## Building and running later

1. Complete the existing clock electrical and FPGA timing/CDC checks; then run `scripts/create_board_project.tcl` in a fresh build directory and validate the PS/SmartConnect/module-reference interfaces. Inspect PS MIO voltage settings for the exact module.
2. Implement the design, export its XSA including the bitstream, and create a Vitis standalone A53-0 application/platform from that XSA. This requires the matching embedded development tools/BSP, which have not been built here.
3. Add only `main.c` and `spw_log.c` from `software/uart_monitor` with `spw_log.h`. Do not include `test_log.c` in the target application. Generate an OCM-only linker script, check the map fits and that no initialized section uses DDR. The non-SDT path assumes the sole enabled UART0 is device ID XPAR_XUARTPS_0_DEVICE_ID; the application checks its base address. The SDT path looks up UART0 by base address.
4. Initialize PS clocks/MIO/power through the generated PS initialization flow, configure the FPGA, and load/start the application in OCM using JTAG. Do not access the telemetry AXI aperture before PL is configured and its clock/reset is ready; a missing PL slave can stall CPU access rather than return a neat error.
5. Open the terminal, observe BOOT/SNAP/COUNT/EVENT lines, and save the session while performing the procedure in bringup.md. Confirm the remote device receives the expected packets separately.

No target ELF, generated BSP/XSA or physical UART output has been validated yet.

## License-free checks

`run_ghdl.ps1` includes `tb_telemetry`: AXI backpressure, independent write-address/data order, read-only write rejection, coherent snapshots, event FIFO order, overflow, invalid/empty reads and reset. Generic telemetry synthesis passes in GHDL; vendor interface attributes are ignored by that generic tool.

The portable C formatting/FIFO-drain logic has a host test:

```powershell
.\scripts\test_uart_log.ps1 -Compiler gcc
```

This checks counter-to-message mapping, event budgets, timestamp pairing and invalid identity handling. It does not run the AMD UART driver or the PS hardware. A native C99 compiler is required; the recorded run used the installed AMD-bundled MinGW GCC.

## Logic analyzer status

The board source instantiates ILA probes for Data-in/Strobe-in after the input buffers and Data-out/Strobe-out before the output buffers, plus status, counters and character streams. The ILA observes internal digital nodes; it cannot measure LVDS voltage, termination, analog eye quality or isolation behavior. No physical external logic analyzer was attached and no ILA capture has been made. An external instrument must support the differential LVDS electrical interface and sufficient bandwidth; a generic single-ended logic probe is not an assumed substitute.
