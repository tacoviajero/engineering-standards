# 2026-10-19 — Daño de tablas internas de MariaDB en XAMPP (Tizón)

**Fecha indicada por la documentación original:** 19 de octubre de 2026.  
**Estado:** antecedente respaldado por archivos de recuperación en Tizón; **no se dispone de evidencia de ejecución exitosa del script ni de causa raíz**.  
**Entorno documentado:** XAMPP en Windows, esquema interno `mysql` de MariaDB. La documentación presupone `C:\xampp` y puerto 3306.

## Fuentes originales

Los archivos originales están versionados en `tacoviajero/tizon`, rama `main`:

- [INSTRUCCIONES.txt](https://github.com/tacoviajero/tizon/blob/main/v1.0/docs/recovery/windows-xampp/INSTRUCCIONES.txt)
- [recuperar_mysql_xampp.ps1](https://github.com/tacoviajero/tizon/blob/main/v1.0/docs/recovery/windows-xampp/recuperar_mysql_xampp.ps1)
- [Commit que los incorporó al repositorio (22-11-2026)](https://github.com/tacoviajero/tizon/commit/92b86f6b4f4b15e88eef2faa36df94d0ab0a09eb)

La fecha del incidente procede del texto de instrucciones, **no** de la fecha del commit. No hay en los archivos una bitácora del incidente que confirme exactamente cuándo se ejecutó un procedimiento de recuperación.

## Síntomas y alcance de lo documentado

El texto original indica que la instancia de XAMPP podía cerrarse inmediatamente y que `mysqld.exe --console` informaba que `mysql.proxies_priv` o `mysql.columns_priv` presentaban formato/checksum incorrecto o estaban marcadas como `crashed`. Identifica **ambas tablas como las afectadas el 19 de octubre de 2026**.

**No hay mensajes de error literales con timestamp** en estos dos archivos; los términos anteriores son una descripción de los errores, no una transcripción completa del log.

El mecanismo propuesto afecta al **esquema interno `mysql`**, no a la base de negocio `tizon_mvp`. Sin embargo, reconstruir tablas de privilegios puede eliminar permisos específicos almacenados en ellas.

## Procedimiento conservado (implementación existente, no ejecución verificada)

El manual documenta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\recuperar_mysql_xampp.ps1
```

Y la selección explícita de otras tablas:

```powershell
.\recuperar_mysql_xampp.ps1 -Tables @('nombre_de_tabla')
```

El script PowerShell, con valores predeterminados `proxies_priv` y `columns_priv`, implementa el siguiente flujo:

1. Verifica rutas de XAMPP y que no haya procesos `mysqld`.
2. Copia `C:\xampp\mysql\data\mysql` a un respaldo con marca temporal y crea un directorio de cuarentena.
3. Mueve a cuarentena los archivos `.frm`, `.MAD` y `.MAI` de las tablas seleccionadas.
4. Inicia temporalmente `mysqld` con `--skip-grant-tables` y `--bind-address=127.0.0.1`, espera respuesta de `mysqladmin ping`, ejecuta `mysql_upgrade --force --upgrade-system-tables` y solicita el apagado.
5. Conserva respaldo y cuarentena para revisión posterior; intenta apagar la instancia temporal cuando hay un fallo en el bloque de recuperación.

**Advertencia de seguridad:** el script usa `--skip-grant-tables` (desactiva controles de privilegios durante la recuperación); además, usa `127.0.0.1:3306` de forma fija para las llamadas administrativas. Se conserva como evidencia histórica, **no como receta aprobada para ejecutar sin revisión**. Debe evaluarse el aislamiento de la instancia, compatibilidad de versión, respaldo recuperable, usuarios y permisos antes de reutilizarlo. Evitar ejecutar este script sobre un servidor operativo sin una evaluación específica.

## Hechos, incertidumbres y aprendizaje

- **Documentado:** Tizón contiene un procedimiento para atender daños de `proxies_priv`/`columns_priv` y el texto lo vincula al 19-10-2026.
- **No verificado:** si el script llegó a ejecutarse durante esa incidencia, si resolvió efectivamente el fallo y cuáles fueron los mensajes exactos o la causa primaria.
- **Hipótesis no demostradas:** apagado brusco, corrupción física o lógica previa, fallos del almacenamiento o efectos de pruebas. No se atribuye la causa a ninguna de ellas.

**Lecciones:** mantener guías de recuperación versionadas, diferenciar instrucciones de evidencia de ejecución, preservar una copia antes de tocar tablas del sistema, revisar privilegios cuando se restauren/recreen tablas y evitar reutilizar procedimientos que deshabilitan autorizaciones sin controles específicos.

## Relación con otras incidencias

- [23–24 de octubre: instancia de pruebas `station-modes-mariadb`](2026-10-station-modes-mariadb.md): se documentó un posible problema de secuencia InnoDB/redo en una instancia de pruebas que usaba puerto 3338. **No hay evidencia para identificarlo con el incidente del 19 de octubre**.
- [25 de noviembre: corrupción de metadatos de replicación y otras tablas internas](2026-11-25-mariadb-corruption.md): recuperación mediante restauración selectiva desde respaldo XAMPP, **no** mediante el script anterior. No se ha demostrado causa compartida.
