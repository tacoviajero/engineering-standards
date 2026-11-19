#requires -Version 5.1
<#
.SYNOPSIS
  Auditoria de solo lectura de repositorios locales de TacoViajero.
.DESCRIPTION
  No hace fetch, pull, reset, stash ni modificaciones al arbol de trabajo.
  Git ls-remote requiere acceso a los repositorios privados.
.EXAMPLE
  .\audit-local-workspaces.ps1 -RootDirectory 'C:\Users\KLozk\Documents\TacoViajero\Code'
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$RootDirectory,
    [ValidateRange(0, 4)]
    [int]$MaximumDepth = 2
)

$ErrorActionPreference = 'Stop'
$excluded = @('.git', 'node_modules', 'build', 'dist', '.venv', '.tools', '.next', 'vendor')
$expected = @('cheeky-van-app', 'tizon', 'liga-maestra', 'taco-viajero', '360tours-studio')

if (-not (Test-Path -LiteralPath $RootDirectory -PathType Container)) {
    throw "No existe la carpeta: $RootDirectory"
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'No se encontro git en PATH.'
}

function Find-GitRoots {
    param([string]$Directory, [int]$Depth)
    if (Test-Path -LiteralPath (Join-Path $Directory '.git')) {
        Write-Output $Directory
        return
    }
    if ($Depth -ge $MaximumDepth) { return }
    foreach ($child in (Get-ChildItem -LiteralPath $Directory -Directory -ErrorAction SilentlyContinue)) {
        if ($excluded -contains $child.Name) { continue }
        Find-GitRoots -Directory $child.FullName -Depth ($Depth + 1)
    }
}

$roots = @(Find-GitRoots -Directory (Resolve-Path -LiteralPath $RootDirectory).Path -Depth 0)
$results = @()
foreach ($directory in $roots) {
    $origin = ((& git -C $directory remote get-url origin 2>$null) -join '').Trim()
    if ($LASTEXITCODE -ne 0) { continue }
    if ($origin -notmatch 'github\.com[:/]tacoviajero/([a-zA-Z0-9._-]+?)(?:\.git)?$') { continue }

    $project = $Matches[1]
    if ($expected -notcontains $project) { continue }

    $localSha = ((& git -C $directory rev-parse HEAD 2>$null) -join '').Trim()
    $branch = ((& git -C $directory symbolic-ref --quiet --short HEAD 2>$null) -join '').Trim()
    if (-not $branch) { $branch = '(HEAD separado)' }
    $changes = @(& git -C $directory status --porcelain=v1 2>$null)

    $remoteLines = @(& git -C $directory ls-remote origin refs/heads/main 2>$null)
    $remoteSha = ''
    if ($LASTEXITCODE -eq 0 -and $remoteLines.Count -gt 0) {
        $remoteSha = ($remoteLines[0] -split '\s+')[0]
    }

    $policyReference = $false
    $agentsFile = Join-Path $directory 'AGENTS.md'
    if (Test-Path -LiteralPath $agentsFile -PathType Leaf) {
        $agentsText = Get-Content -LiteralPath $agentsFile -Raw -Encoding UTF8
        $policyReference = ($agentsText -match 'engineering-standards' -and $agentsText -match 'effort-validation\.md')
    }

    $revision = 'No verificable'
    if ($remoteSha) {
        if ($remoteSha -eq $localSha) { $revision = 'Mismo commit que main' }
        else { $revision = 'Commit distinto de main (direccion desconocida)' }
    }

    $results += [pscustomobject]@{
        Proyecto = $project
        Carpeta = $directory
        Rama = $branch
        Revision = $revision
        CambiosLocales = $changes.Count
        ReferenciaPolitica = $policyReference
        SHA_Local = $localSha
        SHA_RemotoMain = $remoteSha
    }
}

if ($results.Count -eq 0) {
    Write-Warning 'No se encontraron repositorios esperados bajo la raiz y profundidad indicadas.'
} else {
    $results | Sort-Object Proyecto, Carpeta | Format-Table Proyecto, Rama, Revision, CambiosLocales, ReferenciaPolitica, Carpeta -AutoSize
    Write-Output ''
    Write-Output 'Nota: distintos commits no indican por si solos cual rama esta adelantada.'
}
