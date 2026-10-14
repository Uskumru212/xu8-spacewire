param([string]$GhdlPath = 'ghdl')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$build = Join-Path $root 'build/ghdl'
New-Item -ItemType Directory -Force $build | Out-Null
$GhdlPath = (Get-Command $GhdlPath -ErrorAction Stop).Source
function Invoke-Ghdl([string[]]$Arguments, [string]$LogName) {
    $output = & $GhdlPath @Arguments 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content (Join-Path $build $LogName)
    if ($code -ne 0) { throw "GHDL failed ($code): $($Arguments -join ' ')`n$($output -join "`n")" }
    return ($output -join "`n")
}
Push-Location $build
try {
    # Recreate the work library to avoid stale compiled units.
    Remove-Item -LiteralPath (Join-Path $build 'work-obj08.cf') -ErrorAction SilentlyContinue
    $files = @('spwpkg','spwlink','spwrecv','spwxmit','spwrecvfront_generic','spwram','spwstream') |
        ForEach-Object { Join-Path $root "vendor/spacewire_light/rtl/$_.vhd" }
    $files += @('rtl/spw_endpoint.vhd','rtl/spw_test_source.vhd','rtl/xu8_spacewire_top.vhd',
        'vendor/spacewire_light/bench/spwlink_tb.vhd','sim/tb_protocol_200.vhd',
        'sim/tb_endpoint.vhd','sim/tb_test_source.vhd') | ForEach-Object { Join-Path $root $_ }
    $null = Invoke-Ghdl (@('-a','--std=08') + $files) 'analysis.log'
    foreach ($test in @('spwlink_tb','tb_protocol_200','tb_test_source')) {
        $result = Invoke-Ghdl @('-r','--std=08',$test,'--assert-level=error','--ieee-asserts=disable-at-0','--stop-time=2ms') "$test.log"
        $marker = if ($test -eq 'tb_test_source') { 'TEST_PASS' } else { 'Done\.' }
        $expected = if ($test -eq 'tb_protocol_200') { 2 } else { 1 }
        if ([regex]::Matches($result,$marker).Count -ne $expected) { throw "Missing completion markers: $test" }
        Write-Host "PASS $test"
    }
    foreach ($case in @(@(0,0),@(700,200),@(1700,500),@(2300,800))) {
        $name = "endpoint_phase$($case[0])_skew$($case[1])"
        $result = Invoke-Ghdl @('-r','--std=08','tb_endpoint',"-gPHASE_PS=$($case[0])", "-gSKEW_PS=$($case[1])",'--assert-level=error','--ieee-asserts=disable-at-0','--stop-time=2ms') "$name.log"
        if ($result -notmatch 'TEST_PASS') { throw "Missing completion marker: $name" }
        Write-Host "PASS $name"
    }
    Write-Host 'REGRESSION_PASS: 8 completed scenarios; board top analyzed, not implemented.'
} finally { Pop-Location }
