# XU8 SpaceWire

Single-port SpaceWire endpoint for Enclustra Mercury+ XU8 **ME-XU8-7EV-2I-D12E, revision R3**, targeting **200 Mbit/s without DDR I/O**. All repository content is in English.

## Status

A complete generic SpaceWire Light protocol core is integrated with streaming FIFOs, diagnostics and a deterministic packet source. Nine license-free GHDL simulation scenarios passed on 2026-10-14. Generic endpoint synthesis also passed in GHDL. These are functional checks, not FPGA timing closure or physical link certification.

The board integration includes differential I/O buffers, active-high 3.3 V / 5 V enables, 100-to-400 MHz clock generation, VIO controls, ILA probes and optional PS UART0 telemetry. On 2026-10-15, the standalone SpaceWire variant (PS/UART disabled) completed routing at 400 MHz and was programmed over Digilent JTAG. It uses the Enclustra clock input standard and an independent DCI startup sequence. Setup slack is +0.239 ns and hold slack is +0.003 ns; there are no unconstrained internal endpoints. Hardware ILA/VIO communication works, and link start/autostart is enabled with test payload disabled. **After reloading following a user-confirmed power cycle/reset, Run=1 remained asserted throughout a 30-second observation, and an ILA capture was saved. End-to-end packet delivery and throughput remain untested.** See `docs/validation.md`.

## Architecture

`onboard 100 MHz -> clock IP -> 400 MHz rising-edge logic`

`LVDS D/S inputs -> generic sampled receiver -> SpaceWire link/FIFOs -> streaming interface`

`streaming interface -> SpaceWire transmitter -> LVDS D/S outputs`

Both receive and transmit logic use rising edges only. At 400 MHz, divider 1 gives a modeled 200 Mbit/s transmit rate; initialization uses 10 Mbit/s. Each link direction has its own transmit rate. The 400 MHz core clock and asynchronous input capture margin must be validated on the target FPGA. Simulation does not model metastability or analog isolator behavior.

The protocol supports NULL/FCT, credit flow control, data characters, EOP/EEP, parity/error recovery and time codes. `spw_endpoint` exposes time codes; the current board test top disables time-code transmission. Optional test packets contain bytes 0..255 followed by EOP. Test traffic defaults off; received traffic is drained and counted, not echoed or compared to an unknown remote pattern.

## Run without an AMD license

In PowerShell at the repository root:

```powershell
# Optional portable Windows GHDL 6.0.0 download with SHA-256 verification:
.\scripts\get_ghdl.ps1
.\scripts\run_ghdl.ps1 -GhdlPath .\build\tools\ghdl\bin\ghdl.exe
# Or use an already installed GHDL:
.\scripts\run_ghdl.ps1 -GhdlPath ghdl
```

Logs are written to `build/ghdl`. The runner fails on simulator errors or missing completion markers. Downloading GHDL requires Internet access; simulation itself is local and license-free.

## Vivado workflow after licensing

Target part: `xczu7ev-fbvb900-2-i`. The original workstation had Vivado 2026.1 license trouble; continuation validation used Vivado 2025.2.

```powershell
# Choose ONE, in a fresh build/vivado directory:
& 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat' -mode batch -source scripts/create_project.tcl
# OR: include candidate board top and generated clock/debug IP:
& 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat' -mode batch -source scripts/create_board_project.tcl
```

Both target `build/vivado/xu8_spacewire.xpr`; they do not overwrite an existing project. The first is a protocol development project. The second includes a **disabled candidate XDC**, because the R3 clock input electrical standard and SpaceWire I/O standard sign-off remain pending. `scripts/check_board_integration.tcl` validates integration and structural synthesis; it exports no bitstream and does not launch implementation or programming. See `docs/validation.md` for actual results and limits.

## Files and continuation

- [Validation evidence and limits](docs/validation.md)
- [Hardware facts and open electrical checks](docs/hardware.md)
- [VIO/ILA controls, counters and hardware test procedure](docs/bringup.md)
- [SOM UART process logging and standalone PS application](docs/uart.md)
- [Handover for another account or machine](HANDOVER.md)
- [Third-party provenance and licenses](vendor/spacewire_light/UPSTREAM.md)

The older `spw_ds_tx.sv`, `power_enables.sv`, `tb_spw_ds_tx.sv` and `run_sim.ps1` remain standalone experiments. They are not part of the integrated VHDL endpoint or its passing regression. Do not confuse their 200 MHz bit-encoder clock with the integrated design's 400 MHz clock.

## Licensing

SpaceWire Light is included under its upstream non-GRLIB LGPL-2.1-or-later option; original notices, README, license texts and local changes are retained. This repository does not grant an additional license to project-authored files. No AMD software license, binary tool distribution, credentials or generated FPGA artifacts are committed.
