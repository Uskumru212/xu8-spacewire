param([string]$Destination = (Join-Path (Split-Path $PSScriptRoot -Parent) 'build/tools/ghdl'))
$ErrorActionPreference = 'Stop'
$Destination = [IO.Path]::GetFullPath($Destination)
if (Test-Path $Destination) { throw "Destination already exists: $Destination" }
$archive = "$Destination.zip"
New-Item -ItemType Directory -Force (Split-Path $Destination -Parent) | Out-Null
Invoke-WebRequest -Uri 'https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-mingw64.zip' -OutFile $archive
$expected = 'C1562B2A4767E34D33159B536B5E36A8A38EBDB6E7672AA9969A4F4AC2CADFFE'
if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $expected) { throw 'Archive checksum mismatch' }
Expand-Archive -LiteralPath $archive -DestinationPath $Destination
Write-Host "GHDL installed locally: $Destination/bin/ghdl.exe"
