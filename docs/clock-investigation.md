# XU8 R3 clock investigation (2026-10-14)

## Standalone SpaceWire implementation decision (2026-10-15)

The standalone runtime constraints now adopt the manufacturer's clock input
configuration directly: Enclustra reference commit
`10271e532b01b0304ce2f3a051721485dc38a47a`, lines 282-284, assigns
DIFF_SSTL12_DCI to the onboard clock on AH6/AJ6. DIFF_TERM_ADV is not assigned
to these pins because that property is unsupported for this standard.
Bank-66 SpaceWire LVDS input termination remains TERM_100.

AMD UG571 requires DCIRESET for bank-65 multifunction pins using DCI.
The runtime enables STARTUPE3/CFGMCLK-based startup reset sequencing, independent
of the bank-65 oscillator: wait for synchronized EOS, hold reset for another
127 configuration-clock cycles, release DCIRESET, wait for DCI LOCKED, then
release Clock Wizard reset. The endpoint remains reset until PLL lock and
synchronized reset release. CFGMCLK startup logic is conservatively constrained
at 200 MHz; this is a timing bound, not a claim about its physical frequency.

The original candidate project remains available with its disabled XDC. The
standalone build uses `xu8_spacewire_runtime.xdc` and disables PS/UART telemetry.
Historical uncertainty notes below predate this manufacturer-reference-based
implementation. Hardware link evidence is recorded separately in validation.md.

Source: [AMD UG571, DCIRESET and special DCI requirements](https://docs.amd.com/api/khub/documents/kFbaUC5HGcXyGNauhgU6Gw/content).

## Clock-source clarification (2026-10-15)

The SOM already contains the clock sources; no external carrier oscillator is
required for the current design. Enclustra's public V08 manual, section 2.12
(page 32), identifies the 33.33 MHz PS oscillator and the 100 MHz LVDS PL
oscillator on CLK100_P/AH6 and CLK100_N/AJ6, with an external 100-ohm resistor
on the module. The project already uses this onboard 100 MHz input and requests
400 MHz from Clock Wizard. The outstanding R3 question concerns the FPGA input
IOSTANDARD, not the existence or frequency of the oscillator. V08 independently
confirms the clock topology but does not establish R3 electrical compatibility.

Source: [Enclustra Mercury+ XU8 User Manual V08, section 2.12](https://www.enclustra.com.cn/index.php/cms/index/download/id/375.html#page=32).

## Evidence

The Enclustra-authored Mercury+ XU8 User Manual, D-0000-454-001,
version 10 (10-Nov-2025), covers revision 3.0 modules. Table 9 specifies
bank 65 as HP, supplied internally at 1.2 V. Section 3.11 and Table 22
specify a 100 MHz LVDS oscillator, CLK100_P on AH6 and CLK100_N on AJ6,
with a parallel 100-ohm resistor close to the FPGA. The oscillator part
number and detailed coupling/bias circuit are not provided in that manual.

Sources: [Enclustra product/document portal](https://www.enclustra.com/en/products/system-on-chip-modules/mercury-xu8/)
and [public reproduction of Enclustra manual V10](https://manualzz.com/doc/87537445/enclustra-mercury-xu8-user-manual).
The older [V08 on Enclustra's China site](https://www.enclustra.com.cn/index.php/cms/index/download/id/375.html)
independently agrees on the bank voltage, clock pins, frequency and termination,
but predates R3 and is not used to establish revision coverage.

The [official reference Tcl](https://github.com/enclustra/Mercury_XU8_PE3_Reference_Design/blob/10271e532b01b0304ce2f3a051721485dc38a47a/src/Mercury_XU8_PE3.tcl),
lines 282-284, selects DIFF_SSTL12_DCI for those clock pins in its DDR design.
That selection is not proof that the oscillator itself produces SSTL levels.

## Electrical interpretation and remaining gate

[AMD UG571, Table 1-77 note 1](https://www.amd.com/content/dam/xilinx/support/documents/user_guides/ug571-ultrascale-selectio.pdf)
allows input-only LVDS in an HP bank at a different VCCO when internal
differential termination is disabled and the input electrical limits are met.
Thus bank 65 at 1.2 V does not by itself prohibit LVDS input. Do not add an
internal 100-ohm termination in parallel with the module's external resistor.

However, the [DS925 recommended VIN limit](https://docs.amd.com/r/en-US/ds925-zynq-ultrascale-plus/Recommended-Operating-Conditions)
is VCCO + 0.2 V, and the [LVDS common-mode and differential limits](https://docs.amd.com/r/en-US/ds925-zynq-ultrascale-plus/LVDS-DC-Specifications-LVDS)
also apply. The word LVDS alone does not establish worst-case pin voltages
at a 1.2 V bank. The exact R3 oscillator output/coupling circuit or explicit
Enclustra guidance for a clock-wizard-only design is still needed to choose
between the reference's DIFF_SSTL12_DCI and LVDS/TERM_NONE with confidence.
The candidate XDC therefore remains disabled and its clock standard unset.
No electrical waiver or NSTD suppression has been introduced.

Bank 66 remains independently user-confirmed at 1.8 V; its SpaceWire input
termination is unrelated to this oscillator termination. No DDR primitive
or memory controller is needed merely to use the oscillator as a PL clock.
