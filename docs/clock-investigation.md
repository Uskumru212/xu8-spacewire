# XU8 R3 clock investigation (2026-10-14)

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
