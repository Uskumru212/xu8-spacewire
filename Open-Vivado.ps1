$ErrorActionPreference = 'Stop'
$repoPath = $PSScriptRoot
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
if (-not (Test-Path -LiteralPath $vivadoPath)) { throw "Vivado 2025.2 not found: $vivadoPath" }
$mapping = @(subst) | Where-Object { $_ -match '^X:\\:' }
if ($mapping) {
    $mappedPath = ($mapping -split '=>', 2)[1].Trim()
    if ($mappedPath.TrimEnd('\') -ne $repoPath.TrimEnd('\')) {
        throw "X: is already mapped to $mappedPath. No mapping was changed."
    }
} elseif (Test-Path 'X:\') {
    throw 'X: is already in use. No mapping was changed.'
} else {
    subst X: $repoPath
    if ($LASTEXITCODE -ne 0) { throw 'Could not map the project to X:.' }
}
$localBuildRoot = 'C:\Users\ErdemErbil\.codex\visualizations\2026\10\15\01a13e86-fcf8-7bf2-9388-11702a845d81\xu8-build'
$buildMapping = @(subst) | Where-Object { $_ -match '^V:\\:' }
if ($buildMapping) {
    $mappedBuildPath = ($buildMapping -split '=>', 2)[1].Trim()
    if ($mappedBuildPath.TrimEnd('\') -ne $localBuildRoot.TrimEnd('\')) {
        throw "V: is already mapped to $mappedBuildPath. No mapping was changed."
    }
} elseif (Test-Path 'V:\') {
    throw 'V: is already in use. No mapping was changed.'
} else {
    subst V: $localBuildRoot
    if ($LASTEXITCODE -ne 0) { throw 'Could not map the local build to V:.' }
}
$projectPath = 'V:\spacewire-only\xu8_spacewire.xpr'
if (-not (Test-Path -LiteralPath $projectPath)) { throw "Generated project not found: $projectPath" }
Start-Process -FilePath $vivadoPath -ArgumentList @('-mode', 'gui', $projectPath) -WorkingDirectory 'V:\' -WindowStyle Hidden
