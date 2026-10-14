# Handover

## Goal

Establish a stable SpaceWire link between an Enclustra XU8 and another SpaceWire device, targeting 200 Mbit/s with no DDR I/O operation. Provide observable status and meaningful traffic/error checks. Keep all repository content in English.

## Completed

- Collected module identity, major signal assignments, power-enable polarity, bank supply information, isolator identity, and receive termination assembly corrections.
- Created the initial repository documentation and ignore rules.
- Located Vivado 2026.1 and read its version successfully.
- Added `spw_ds_tx.sv`, `power_enables.sv`, a self-checking testbench, a device probe, project creation script, and simulation runner.
- Compiled RTL with xvlog and elaborated the testbench with xelab successfully.
- Found AH6/AJ6 as the onboard PL clock pins in the official Enclustra PE3 reference; electrical configuration still requires R3 verification.

## Not completed

- No complete protocol transmitter, receiver, link state machine, or packet path has been implemented.
- The Vivado project creation script is ready, but no .xpr could be generated because Vivado refuses to start without a valid license.
- No executable board constraints or bitstream have been generated.
- No simulation, synthesis, implementation, timing analysis, or hardware link test has passed.
- XSim also refused to execute due to a missing simulator license; compilation/elaboration must not be reported as a simulation pass.

## Next steps

1. Activate the required Vivado/Simulator license and run `scripts/check_device.tcl` to verify exact part availability and package pins. Retry `scripts/run_sim.ps1`; inspect actual test results.
2. Retrieve Enclustra R3 pinout/reference constraints and verify clock, SpaceWire, and power-enable pins.
3. Check AMD bank standards, differential termination, and voltage compatibility with the ADN4622 interface.
4. Select and document a single-edge receiver architecture for asynchronous Data/Strobe signals. Evaluate speed and CDC behavior before promising 200 Mbit/s timing closure.
5. Implement and simulate link initialization, character coding, flow control, recovery, and packet paths against an independent peer model.
6. Add a reproducible project script and ILA/VIO instrumentation; run synthesis, implementation, DRC, CDC analysis, and timing checks.
7. Verify the Digilent programmer model and connection. Start hardware link tests at initialization speed, then test the configured 200 Mbit/s operation.

## Test evidence to preserve

Record tool versions, source commit, constraints, clock configuration, simulation outcomes, implementation reports, and hardware observations separately. Do not describe proposed behavior as tested behavior. Remote packet delivery needs remote evidence or a defined response protocol.

## Continue in another account

Provide this repository to the next assistant and ask it to read README.md, HANDOVER.md, and docs/hardware.md before editing. Account/session credentials and licenses must not be committed. Access to this private repository must be separately available to that environment.
