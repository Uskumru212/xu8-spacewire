# Handover

## Goal

Establish a stable SpaceWire link between an Enclustra XU8 and another SpaceWire device, targeting 200 Mbit/s with no DDR I/O operation. Provide observable status and meaningful traffic/error checks. Keep all repository content in English.

## Completed

- Collected module identity, major signal assignments, power-enable polarity, bank supply information, isolator identity, and receive termination assembly corrections.
- Created the initial repository documentation and ignore rules.

## Not completed

- No RTL or testbench has been implemented.
- No Vivado project, executable constraints, or bitstream has been generated.
- No simulation, synthesis, implementation, timing analysis, or hardware link test has passed.

## Next steps

1. Confirm Vivado installation and availability of the exact FPGA part.
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
