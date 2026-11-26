# 2026-11-25 — Corrupción de MariaDB 10.4.32 en XAMPP

**Estado:** servicio recuperado; causa inicial desconocida.  
**Entorno:** Windows, XAMPP, MariaDB 10.4.32, `C:\xampp\mysql`, puerto 3306.  
**Impacto:** El Tizón y Liga Maestra no podían utilizar normalmente la instancia compartida.  
**Fuentes:** conversación de gestión de El Tizón (25-11-2026), salida `mysqld --console`, listado y verificación `aria_chk` proporcionados durante el diagnóstico. Los comandos finales de copia no aparecen en las transcripciones recuperadas.

## Hechos comprobados y síntomas

1. Se observó que el puerto 3306 se abría, pero el servicio no finalizaba una inicialización funcional estable. Que un puerto acepte conexiones o aparezca `ready for connections` **no prueba** que el servicio haya terminado de inicializarse.
2. El archivo `multi-master.info` contenía contenido propio de un registro de errores, interpretado erróneamente como entradas de replicación. Se observaban nombres `master-...` derivados de líneas con timestamps, `[Warning]`, `Version: '10.4.32-MariaDB'` y `ready for connections`.
3. Las tablas internas `mysql.global_priv`, `mysql.db`, `mysql.proxies_priv` y `mysql.roles_mapping` presentaban problemas. La verificación del 25-11 mostró para `global_priv` **0 registros** (aunque `aria_chk` finalizó con código 0: una tabla estructuralmente legible puede estar vacía). `db.MAI` produjo error de formato; `proxies_priv` y `roles_mapping` presentaron tamaños inesperados.
4. La reparación intentada de `global_priv` **no recuperó ningún usuario**.
5. **Resultado reportado y verificado funcionalmente en la sesión:** restauración selectiva de las cuatro tablas desde el respaldo original incluido en XAMPP; Tizón y Liga Maestra volvieron a funcionar.
6. Se eliminaron **31 bases residuales de pruebas** y se corrigió el mecanismo de limpieza de las bases temporales de Tizón. No se ha demostrado que esos residuos fueran la causa de la corrupción.

## Mensajes de error conservados

Salida observada al ejecutar `mysqld.exe --defaults-file=... --console` el 25-11-2026 a las 18:06:44:

```text
[ERROR] ... Slave I/O: Fatal error: Invalid (empty) username when attempting to connect to the master server. Connection attempt terminated. Internal MariaDB error code: 1593
[ERROR] Failed to create a new master info file (..., errno 38)
[Warning] Reading of some Master_info entries failed
[ERROR] Failed to initialize multi master structures
[ERROR] Aborting
```

La misma salida indicaba `InnoDB: 10.4.32 started` y `Server socket created on IP: '::'`. Eran hitos parciales, no evidencia de que la inicialización completa hubiera terminado.

Verificación de tablas Aria, realizada **con MariaDB detenido**:

```text
db.MAI: aria_chk.exe: error: 'C:\xampp\mysql\data\mysql\db.MAI' is not a Aria table
global_priv.MAI: Data records: 0 / Resultado: 0
proxies_priv.MAI: Size of indexfile is: 229376 Expected: 24576
roles_mapping.MAI: Size of datafile is: 8658 Expected: 8192
```

## Diagnóstico y comandos conservados

Estas instrucciones aparecen en las transcripciones de PowerShell de la investigación:

```powershell
& "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --console
```

```powershell
$base = "C:\xampp\mysql"
if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    throw "MariaDB sigue activo. No continuar."
}
Get-ChildItem "$base\backup\mysql" -File | Select-Object Name, Length
Get-ChildItem "$base\data\mysql" -File | Select-Object Name, Length
Get-ChildItem "$base\data\mysql" -Filter "*.MAI" | ForEach-Object {
    & "$base\bin\aria_chk.exe" --datadir="$base\data" --check $_.FullName
    Write-Host "Resultado: $LASTEXITCODE"
}
```

**Interpretación:** las tablas afectadas son metadatos del esquema interno `mysql`. Los errores de replicación espuria reflejaban una lectura de metadatos incorrectos; no demostraban que se hubiera configurado deliberadamente una réplica real.

## Recuperación exitosa

**Acción efectivamente reportada:** se detuvo MariaDB y se restauraron **selectivamente** los archivos de `global_priv`, `db`, `proxies_priv` y `roles_mapping` desde `C:\xampp\mysql\backup\mysql` hacia `C:\xampp\mysql\data\mysql`. El respaldo original contenía archivos `.frm`, `.MAD`, `.MAI` de esas cuatro tablas. Después se comprobó la operación de ambas aplicaciones.

**Comando de recuperación — reconstrucción orientativa, NO transcripción del comando histórico:**

```powershell
$base = 'C:\xampp\mysql'
if (Get-Process mysqld -ErrorAction SilentlyContinue) {
    throw 'Detener MariaDB antes de copiar archivos.'
}
# Antes de modificar: hacer respaldo íntegro, fuera de data, de la instalación afectada.
$tables = 'global_priv','db','proxies_priv','roles_mapping'
foreach ($table in $tables) {
    foreach ($ext in 'frm','MAD','MAI') {
        $source = Join-Path $base "backup\mysql\$table.$ext"
        $target = Join-Path $base "data\mysql\$table.$ext"
        if (!(Test-Path -LiteralPath $source)) { throw "No existe: $source" }
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
}
```

**Advertencias:** sólo reproduce la selección de archivos y rutas reportada; no ejecutar automáticamente en otra instalación. Sustituye las tablas de privilegios por su estado del respaldo, lo cual puede **perder cuentas, roles o concesiones personalizadas**. Requiere verificar compatibilidad de versión, respaldar el estado completo y reconciliar cuentas/permisos. No copiar indiscriminadamente `mysql`, `data` ni `ibdata1` sobre datos en uso. La restauración no es una prueba de la causa de la corrupción.

## Limpieza posterior

- **Resultado reportado:** eliminación de 31 bases de datos residuales de pruebas.
- **Resultado reportado:** corrección en Tizón para limpiar recursos de bases temporales, incluso en rutas de fallo.
- Esta corrección es un cambio específico de Tizón; la obligación transversal se formaliza en [la política global](../../policies/effort-validation.md).

## Causa raíz: no determinada

**Comprobado:** metadatos de replicación contenían líneas de log; tablas internas estaban dañadas o inconsistentes; el restablecimiento de sus archivos desde el respaldo permitió recuperar el servicio.

**Hipótesis no demostradas:** escritura accidental de logs en `multi-master.info`, cierre abrupto, corrupción del sistema de archivos, intervención manual, pruebas automatizadas o interacción de varios procesos. No hay evidencia suficiente para atribuir el origen a una hipótesis específica. La coexistencia de 31 bases residuales **no prueba causalidad**.

## Lecciones aplicables

1. Un puerto abierto y mensajes de inicio parciales no sustituyen pruebas de conexión y consultas reales.
2. Evitar reparaciones repetidas sobre tablas que están lógicamente vacías: una verificación `aria_chk` exitosa no recupera usuarios.
3. Inspeccionar `multi-master.info` y los mensajes de replicación sólo con respaldo y sin alterar evidencias innecesariamente.
4. Recuperar selectivamente, con MariaDB detenido, tras verificar archivos y preservar una copia íntegra.
5. Toda prueba que cree bases, archivos, procesos u otros recursos temporales debe retirarlos al terminar **también cuando falle**; conservar evidencias sólo en ubicaciones explícitas y controladas.
6. Documentar qué se ejecutó de verdad y qué se propone sólo como procedimiento reproducible.
