# XU8 SpaceWire

Single-port SpaceWire FPGA project for an Enclustra Mercury+ XU8 module, targeting a 200 Mbit/s link to an external SpaceWire device.

## Current status

Development has started. The repository contains a single-edge Data/Strobe bit encoder, active-high power-enable outputs, a self-checking testbench, and reproducible Vivado project/simulation scripts. RTL compilation and elaboration succeeded with Vivado Simulator 2026.1. Simulation execution and Vivado project creation are blocked by missing licenses. No complete SpaceWire link, timing closure, or hardware-tested bitstream is available. See [validation status](docs/validation.md).

## Target hardware

- Module: ME-XU8-7EV-2I-D12E, revision R3 (user supplied).
- FPGA: XCZU7EV-2FBVB900I, according to the Enclustra product selection table.
- Toolchain: Vivado 2026.1, found at `C:\AMDDesignTools\2026.1\Vivado`; required licenses are not active.
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

See [hardware notes](docs/hardware.md), [pin candidates](constraints/pin_candidates.csv), and [handover](HANDOVER.md). Pin assignments are not yet validated against the R3 module pinout and Vivado device database. No executable board XDC is provided until that validation is complete.

## Development commands

From PowerShell in the repository root, after activating the required licenses:

```powershell
& 'C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat' -mode batch -source scripts/check_device.tcl
& 'C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat' -mode batch -source scripts/create_project.tcl
.\scripts\run_sim.ps1
```

The generated project will be `build/vivado/xu8_spacewire.xpr`. Its current synthesis top is the bit-layer unit `spw_ds_tx`, not a board top. No programming or bitstream generation is performed. The encoder accepts already-framed bits using a valid/ready handshake. It does not yet generate SpaceWire characters or NULL/FCT traffic, and pauses if its bit source stalls. A complete link must continuously supply the required idle traffic.

At a modeled 200 MHz input clock, `cycles_per_bit=20` represents 10 Mbit/s and `cycles_per_bit=1` represents 200 Mbit/s. This is a functional model, not a claim of achieved device timing. The power-enable module is separate and will be instantiated in the future board top.

## References

- [Enclustra Mercury+ XU8](https://www.enclustra.com/en/products/system-on-chip-modules/mercury-xu8/)
- [Analog Devices ADN4622](https://www.analog.com/en/products/adn4622.html)
- [SpaceWire link initialization](https://www.star-dundee.com/spacewire/spacewire-users-guide/spacewire-links/exchange-level/link-initialisation/)

All repository documentation, source comments, and commit messages are to be written in English.
