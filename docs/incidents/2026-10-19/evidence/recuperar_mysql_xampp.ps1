[CmdletBinding()]
param(
    [string]$XamppRoot = 'C:\xampp',
    [string[]]$Tables = @('proxies_priv', 'columns_priv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$mysqlRoot = Join-Path $XamppRoot 'mysql'
$dataRoot = Join-Path $mysqlRoot 'data'
$systemDatabase = Join-Path $dataRoot 'mysql'
$serverExecutable = Join-Path $mysqlRoot 'bin\mysqld.exe'
$adminExecutable = Join-Path $mysqlRoot 'bin\mysqladmin.exe'
$upgradeExecutable = Join-Path $mysqlRoot 'bin\mysql_upgrade.exe'
$configurationFile = Join-Path $mysqlRoot 'bin\my.ini'

foreach ($requiredPath in @(
    $systemDatabase,
    $serverExecutable,
    $adminExecutable,
    $upgradeExecutable,
    $configurationFile
)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "No se encontró: $requiredPath"
    }
}

$runningServers = @(Get-Process -Name 'mysqld' -ErrorAction SilentlyContinue)
if ($runningServers.Count -gt 0) {
    $runningIds = ($runningServers | Select-Object -ExpandProperty Id) -join ', '
    throw "MySQL debe estar detenido antes de ejecutar la recuperación. Procesos activos: $runningIds"
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupPath = Join-Path $dataRoot "respaldo_mysql_sistema_$timestamp"
$quarantinePath = Join-Path $dataRoot "tablas_mysql_danadas_$timestamp"

Write-Host "Creando respaldo completo de la base interna mysql en: $backupPath"
Copy-Item -LiteralPath $systemDatabase -Destination $backupPath -Recurse
New-Item -ItemType Directory -Path $quarantinePath | Out-Null

$movedFiles = 0
foreach ($table in $Tables) {
    if ($table -notmatch '^[A-Za-z0-9_]+$') {
        throw "Nombre de tabla no válido: $table"
    }

    foreach ($extension in @('frm', 'MAD', 'MAI')) {
        $sourcePath = Join-Path $systemDatabase "$table.$extension"
        if (Test-Path -LiteralPath $sourcePath) {
            Move-Item -LiteralPath $sourcePath -Destination $quarantinePath
            $movedFiles++
        }
    }
}

if ($movedFiles -eq 0) {
    throw 'No se encontró ninguno de los archivos de las tablas indicadas.'
}

Write-Host "Archivos dañados apartados en: $quarantinePath"
Write-Host 'Iniciando MariaDB temporalmente para reconstruir las tablas internas...'

$serverArguments = @(
    "--defaults-file=$configurationFile",
    '--skip-grant-tables',
    '--bind-address=127.0.0.1',
    '--console'
)

$temporaryServer = Start-Process `
    -FilePath $serverExecutable `
    -ArgumentList $serverArguments `
    -PassThru `
    -WindowStyle Hidden

try {
    $serverReady = $false
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        Start-Sleep -Seconds 1

        if ($temporaryServer.HasExited) {
            break
        }

        $null = & $adminExecutable `
            '--host=127.0.0.1' `
            '--port=3306' `
            '--user=root' `
            'ping' 2>&1

        if ($LASTEXITCODE -eq 0) {
            $serverReady = $true
            break
        }
    }

    if (-not $serverReady) {
        throw "MariaDB no quedó listo. Revisa: $(Join-Path $dataRoot 'mysql_error.log')"
    }

    & $upgradeExecutable `
        '--host=127.0.0.1' `
        '--port=3306' `
        '--user=root' `
        '--force' `
        '--upgrade-system-tables'

    if ($LASTEXITCODE -ne 0) {
        throw "mysql_upgrade terminó con código $LASTEXITCODE. El respaldo y la cuarentena se conservaron."
    }

    & $adminExecutable `
        '--host=127.0.0.1' `
        '--port=3306' `
        '--user=root' `
        'shutdown'

    if ($LASTEXITCODE -ne 0) {
        throw 'La actualización terminó, pero MariaDB no pudo cerrarse automáticamente.'
    }

    $temporaryServer.WaitForExit(15000) | Out-Null
    if (-not $temporaryServer.HasExited) {
        throw 'La actualización terminó, pero el proceso temporal de MariaDB sigue activo.'
    }

    Write-Host 'RECUPERACIÓN COMPLETADA.'
    Write-Host 'Inicia MySQL normalmente desde el panel de XAMPP.'
    Write-Host "Respaldo: $backupPath"
    Write-Host "Cuarentena: $quarantinePath"
}
catch {
    if (-not $temporaryServer.HasExited) {
        $null = & $adminExecutable `
            '--host=127.0.0.1' `
            '--port=3306' `
            '--user=root' `
            'shutdown' 2>&1
    }

    throw
}
