# XU8 SpaceWire

Single-port SpaceWire FPGA project for an Enclustra Mercury+ XU8 module, targeting a 200 Mbit/s link to an external SpaceWire device.

## Current status

Initial project scaffold and hardware requirements only. No SpaceWire RTL, simulation results, timing closure, or hardware-tested bitstream is available yet. Do not treat this repository as a working SpaceWire implementation.

## Target hardware

- Module: ME-XU8-7EV-2I-D12E, revision R3 (user supplied).
- FPGA: XCZU7EV-2FBVB900I, according to the Enclustra product selection table.
- Toolchain: Vivado 2026.1; installation completion has not been confirmed.
- SpaceWire isolation: ADN4622BRNZ, shown in the supplied schematic.
- Bank 66 supply: 1.8 V (user supplied).
- Programmer: Digilent, reported as "FTAG-HS3"; likely JTAG-HS3, exact model label pending confirmation.
- External SpaceWire device: model unknown.

The requested implementation must avoid DDR I/O operation. The interpretation used so far is to avoid IDDR/ODDR-based data transfer, not merely to avoid external DDR memory. The receiver architecture and attainable speed remain subject to implementation and timing verification.

## Planned implementation

- Differential Data/Strobe transmit and receive paths.
- Link initialization at 10 Mbit/s, followed by a configured 200 Mbit/s transmit rate after reaching Run.
- NULL/FCT handling, credit accounting, data characters, EOP/EEP, parity checking, error recovery, and time-code handling.
- TX/RX FIFOs, configurable test traffic, and receive checking where the remote device supports a known test pattern.
- ILA observation and VIO control, with link-state, traffic, error, and reconnect counters.
- Reproducible Vivado project creation script and simulation tests.

Run state alone does not demonstrate successful application-level packet processing. Remote acknowledgement or remote receive evidence is needed for that claim. The two directions have independently configured transmit rates.

## Hardware information

See [hardware notes](docs/hardware.md) and [handover](HANDOVER.md). Pin assignments are schematic transcriptions, not yet validated against the R3 module pinout and Vivado device database. No executable XDC is provided until that validation is complete.

## References

- [Enclustra Mercury+ XU8](https://www.enclustra.com/en/products/system-on-chip-modules/mercury-xu8/)
- [Analog Devices ADN4622](https://www.analog.com/en/products/adn4622.html)
- [SpaceWire link initialization](https://www.star-dundee.com/spacewire/spacewire-users-guide/spacewire-links/exchange-level/link-initialisation/)

All repository documentation, source comments, and commit messages are to be written in English.
