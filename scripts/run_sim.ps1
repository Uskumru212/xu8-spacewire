param([string]$VivadoBin = 'C:\AMDDesignTools\2026.1\Vivado\bin')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$simulationDir = Join-Path $projectRoot 'build/sim'
New-Item -ItemType Directory -Force -Path $simulationDir | Out-Null
Push-Location $simulationDir
try {
    & (Join-Path $VivadoBin 'xvlog.bat') --sv (Join-Path $projectRoot 'rtl/spw_ds_tx.sv') (Join-Path $projectRoot 'rtl/power_enables.sv') (Join-Path $projectRoot 'sim/tb_spw_ds_tx.sv')
    if ($LASTEXITCODE -ne 0) { throw 'RTL compilation failed.' }
    & (Join-Path $VivadoBin 'xelab.bat') tb_spw_ds_tx -s tb_spw_ds_tx_snapshot
    if ($LASTEXITCODE -ne 0) { throw 'Simulation elaboration failed.' }
    & (Join-Path $VivadoBin 'xsim.bat') tb_spw_ds_tx_snapshot -runall -log test.log
    if ($LASTEXITCODE -ne 0) { throw 'Simulation execution failed.' }
    if (!(Select-String -LiteralPath test.log -Pattern 'TEST_PASS:' -Quiet)) {
        throw 'Simulation did not reach its pass marker.'
    }
} finally { Pop-Location }
