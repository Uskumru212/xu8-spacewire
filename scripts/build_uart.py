"""Run with Vitis 2025.2: vitis -s scripts/build_uart.py.

Set SPW_XSA and SPW_VITIS_WORKSPACE (a fresh, short directory). This builds
only; it never connects to or initializes hardware. A software-only XSA is
sufficient for a compile/link check, but cannot establish hardware readiness.
"""
import os
from pathlib import Path
import re
import vitis

root = Path(__file__).resolve().parents[1]
xsa = Path(os.environ["SPW_XSA"]).resolve()
workspace = Path(os.environ["SPW_VITIS_WORKSPACE"]).resolve()
if not xsa.is_file():
    raise RuntimeError(f"Missing XSA: {xsa}")
if workspace.exists():
    raise RuntimeError(f"Use a fresh workspace; refusing to overwrite {workspace}")
client = vitis.create_client()
try:
    client.set_workspace(str(workspace))
    platform = client.create_platform_component(
        name="xu8_ocm", hw_design=str(xsa), os="standalone",
        cpu="psu_cortexa53_0", domain_name="standalone_a53_0",
        architecture="64-bit", no_boot_bsp=True)
    print("PLATFORM_BUILD:", platform.build())
    app = client.create_app_component(
        name="uart_monitor", platform=client.find_platform_in_repos("xu8_ocm"),
        domain="standalone_a53_0", template="empty")
    app.import_files(from_loc=str(root / "software" / "uart_monitor"),
                     files=["main.c", "spw_log.c", "spw_log.h"])
    linker = app.get_ld_script()
    regions = linker.get_memory_regions()
    ocm = [r for r in regions if "ocm" in r["name"].lower()]
    if len(ocm) != 1:
        raise RuntimeError(f"Expected one OCM region, found: {ocm}")
    linker.set_stack_size("0x4000")
    linker.set_heap_size("0x2000")
    ld_path = Path(linker.file_path)
    source = ld_path.read_text()
    # Preserve the BSP-generated A53 sections/symbols, replacing only placement.
    source, count = re.subn(r">\s*([A-Za-z_][A-Za-z0-9_]*)",
                            "> " + ocm[0]["name"], source)
    if not count:
        raise RuntimeError("No linker section placements found")
    ld_path.write_text(source)
    print("OCM_LINKER:", ld_path, ocm[0])
    print("APPLICATION_BUILD:", app.build())
    elfs = list((workspace / "uart_monitor").rglob("*.elf"))
    if not elfs:
        raise RuntimeError("No application ELF produced")
    for elf in elfs:
        print("ELF_REQUIRES_LOAD_SEGMENT_REVIEW:", elf)
finally:
    vitis.dispose()
