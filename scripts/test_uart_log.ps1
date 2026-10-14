param([string]$Compiler = 'gcc')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$build=Join-Path $root 'build/host'
New-Item -ItemType Directory -Force $build | Out-Null
$exe=Join-Path $build 'test_log.exe'
& $Compiler -std=c99 -Wall -Wextra -Werror (Join-Path $root 'software/uart_monitor/spw_log.c') (Join-Path $root 'software/uart_monitor/test_log.c') -o $exe
if ($LASTEXITCODE -ne 0) { throw 'Host compilation failed' }
$result=& $exe
$result | Write-Host
if ($LASTEXITCODE -ne 0 -or ($result -join "`n") -notmatch 'TEST_PASS') { throw 'Host test failed' }
