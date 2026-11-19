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

function Invoke-GitReadOnlyQuery {
    param([string]$Directory, [string[]]$Arguments)
    # Windows PowerShell 5.1 convierte stderr nativo en errores de PowerShell.
    $ErrorActionPreference = 'Continue'
    $output = @(& git --no-optional-locks -C $Directory @Arguments 2>$null)
    [pscustomobject]@{ Output = $output; ExitCode = $LASTEXITCODE }
}

$roots = @(Find-GitRoots -Directory (Resolve-Path -LiteralPath $RootDirectory).Path -Depth 0)
$results = @()
foreach ($directory in $roots) {
    $localQuery = Invoke-GitReadOnlyQuery -Directory $directory -Arguments @('rev-parse', 'HEAD')
    if ($localQuery.ExitCode -ne 0) {
        Write-Warning "Repositorio local no verificable: $directory (HEAD o metadatos Git no disponibles)."
        continue
    }
    $originQuery = Invoke-GitReadOnlyQuery -Directory $directory -Arguments @('remote', 'get-url', 'origin')
    $origin = ($originQuery.Output -join '').Trim()
    $project = Split-Path -Path $directory -Leaf
    $remoteState = 'No verificable'
    if ($originQuery.ExitCode -eq 0 -and $origin) {
        if ($origin -notmatch 'github\.com[:/]tacoviajero/([a-zA-Z0-9._-]+?)(?:\.git)?$') { continue }
        $project = $Matches[1]
        if ($expected -notcontains $project) { continue }
    } else {
        $remotesQuery = Invoke-GitReadOnlyQuery -Directory $directory -Arguments @('remote')
        if ($remotesQuery.ExitCode -eq 0 -and $remotesQuery.Output -notcontains 'origin') {
            $remoteState = 'Ausente (sin origin)'
        }
    }

    $localSha = ($localQuery.Output -join '').Trim()
    $branch = ((& git -C $directory symbolic-ref --quiet --short HEAD 2>$null) -join '').Trim()
    if (-not $branch) { $branch = '(HEAD separado)' }
    $changes = @(& git --no-optional-locks -C $directory status --porcelain=v1 2>$null)

    $remoteSha = ''
    if ($originQuery.ExitCode -eq 0 -and $origin) {
        $remoteQuery = Invoke-GitReadOnlyQuery -Directory $directory -Arguments @('ls-remote', 'origin', 'refs/heads/main')
        if ($remoteQuery.ExitCode -ne 0) {
            $remoteState = 'Inaccesible (consulta fallida)'
        } elseif ($remoteQuery.Output.Count -eq 0) {
            $remoteState = 'No verificable (sin main)'
        } elseif ($remoteQuery.Output[0] -match '^([0-9a-fA-F]{40}|[0-9a-fA-F]{64})\s+refs/heads/main$') {
            $remoteSha = $Matches[1]
            $remoteState = 'Verificado'
        }
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
        EstadoRemoto = $remoteState
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
    $results | Sort-Object Proyecto, Carpeta | Format-Table Proyecto, Rama, EstadoRemoto, Revision, CambiosLocales, ReferenciaPolitica, Carpeta -AutoSize
    Write-Output ''
    Write-Output 'Nota: distintos commits no indican por si solos cual rama esta adelantada.'
}
