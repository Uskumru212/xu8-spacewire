# Validation status

Date: 2026-10-14. No physical FPGA was programmed.

| Check | Outcome |
| --- | --- |
| Installed tool version | Vivado 2026.1, SW build 6511674 |
| Device database / pin probe | Blocked before Tcl execution by missing Vivado license |
| RTL compile with xvlog | Passed for spw_ds_tx, power_enables, and tb_spw_ds_tx |
| Static elaboration with xelab | Passed; simulation snapshot generated |
| Simulation execution with xsim | Blocked by missing Simulator license |
| Vivado .xpr generation | Not executed successfully; license blocks project access |
| Synthesis / implementation / timing | Not run |
| Hardware link or packet test | Not run |

Vivado reported: `Vivado Design Suite cannot be launched because a valid license was not found.`

XSim reported: `Could not obtain the necessary license for Simulator.`

The simulation runner correctly reported failure because no TEST_PASS marker was generated. Compilation and elaboration alone do not verify behavior.

## Testbench coverage planned for execution

- Every 8-bit pattern serialized least-significant bit first, at modeled 10 and 200 Mbit/s.
- Exactly one Data/Strobe transition for each accepted bit and correct data value.
- Exact sustained bit rate and minimum spacing across live divider changes.
- No output changes during source stalls.
- Disable, restart, synchronous reset, and defined zero-divider behavior.
- Both external power-enable outputs high.

These checks cover the initial bit encoder only. They do not verify SpaceWire framing, link establishment, asynchronous receive sampling, flow control, error recovery, electrical compatibility, or hardware timing.
