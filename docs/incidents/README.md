# Registro de incidencias técnicas — Vts!

Este directorio conserva diagnósticos y recuperaciones útiles para más de un proyecto. No reemplaza la documentación operativa particular de cada aplicación.

## Incidencias

| Fecha | Incidencia | Estado |
| --- | --- | --- |
| 2026-11-25 | [Corrupción de metadatos de replicación y tablas del sistema en MariaDB/XAMPP](2026-11-25-mariadb-corruption.md) | Recuperada; causa original no determinada |
| 2026-10-19 | [Daño de tablas internas de MariaDB en XAMPP — proxies_priv / columns_priv](2026-10-19-mariadb-system-tables.md) | Procedimiento original localizado en Tizón; ejecución y causa no verificadas |
| 2026-10-23/24 (fecha aproximada del evento) | [Fallo previo de la instancia de pruebas station-modes-mariadb](2026-10-station-modes-mariadb.md) | Antecedente documentado parcialmente; falta localizar el informe original |

## Convenciones

- Registrar síntoma, entorno, impacto, evidencias, diagnóstico, acciones, resultado, causa confirmada o desconocida, medidas preventivas y límites de la reconstrucción.
- Separar **comprobado**, **reportado por el operador**, **hipótesis** y **comando reconstruido**. No atribuir comandos no conservados a una ejecución histórica.
- Omitir secretos, credenciales, datos personales y volcados de producción.
- No convertir una correlación temporal en causa raíz.
- Preferir vincular la incidencia original antes que copiarla; si no aparece, marcar el registro como parcial.
- Las medidas transversales aprobadas deben vivir en las [políticas canónicas](../../policies/effort-validation.md), no sólo en la narración de un incidente.
