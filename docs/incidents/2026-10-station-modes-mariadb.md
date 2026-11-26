# Antecedente: instancia de pruebas station-modes-mariadb (octubre de 2026)

**Estado documental:** parcial. **No se localizó un informe de incidencia preexistente en la rama principal de `engineering-standards`.** Este registro conserva la referencia histórica identificada en conversaciones de gestión de El Tizón sin presentarla como un diagnóstico completo.

## Hechos recuperados

- La instancia de pruebas `work/station-modes-mariadb` utilizaba MariaDB 10.4.32, con configuración `my.ini` y puerto 3338.
- Registros examinados alrededor del 23–24 de octubre indicaban una diferencia entre la secuencia del tablespace InnoDB y los archivos redo en un arranque anterior.
- Existían rastros de fallo `Klozknf.err` y `mysqld.dmp`.
- Los archivos se habían mencionado en la conversación de gestión de El Tizón del 20 de noviembre de 2026.

## Diferencia con el caso del 19 de octubre

En Tizón ya se localizó un [procedimiento original asociado a una incidencia del 19-10-2026](2026-10-19-mariadb-system-tables.md) sobre las tablas internas `proxies_priv` y `columns_priv` de XAMPP. Esta ficha describe otra evidencia: una instancia de pruebas en el puerto 3338 y una divergencia InnoDB/redo alrededor de los días 23–24. **No está demostrado que sean el mismo episodio**. Los dos antecedentes permanecen separados mientras no exista una fuente que establezca su identidad.

## Lo que no se puede afirmar

No se recuperaron el documento original supuestamente ya elaborado, la transcripción íntegra de errores, los comandos de recuperación, un resultado de reparación demostrado ni una causa raíz confirmada. Tampoco está probado que este episodio causara o estuviera relacionado con la corrupción del MariaDB principal del 25 de noviembre.

**Pendiente documental:** identificar el archivo o registro original de esta incidencia y sustituir o ampliar esta ficha con evidencias verificables. No repetir pruebas técnicas únicamente para llenar el histórico.
