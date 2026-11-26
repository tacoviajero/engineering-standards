# Política obligatoria de idioma y nomenclatura técnica

Acordada el 26/11/2026. Aplica a los proyectos de software de TacoViajero.

## Convención

El idioma de implementación es inglés; el idioma de la interfaz se ajusta al público del producto (español en El Tizón). Separar identificadores y valores técnicos de etiquetas, mensajes y traducciones visibles.

| Elemento | Convención |
| --- | --- |
| Clases PHP y tipos equivalentes | Inglés, PascalCase |
| Métodos y variables PHP/JavaScript | Inglés, camelCase |
| Tablas y columnas SQL | Inglés, snake_case |
| Valores ENUM y otros códigos internos de dominio | Inglés, snake_case |
| Constantes | Inglés, UPPER_SNAKE_CASE |
| Selectores CSS y rutas propias | Inglés, kebab-case |
| Etiquetas y mensajes al usuario | Idioma del público |
| Documentación y comentarios internos | Español permitido |

En otros lenguajes respetar sus convenciones idiomáticas y contratos externos. No traducir nombres propios, datos del usuario, protocolos o identificadores impuestos por dependencias.

## Aplicación

- Aplicar a código nuevo y a cambios de nomenclatura expresamente autorizados. No introducir nuevas cadenas técnicas en español ni duplicar códigos de dominio para representar etiquetas visibles.
- Centralizar vocabularios de dominio repetidos mediante tipos, enumeraciones o constantes compatibles con el entorno cuando corresponda. No depender de posiciones ordinales de ENUM de base de datos como identificadores estables.
- Mantener compatibilidad con contratos existentes mientras no se autorice su migración. No introducir simultáneamente equivalentes en ambos idiomas sin una estrategia de transición.
- La política no autoriza renombrados masivos, modificaciones de esquema, cambios de API ni refactorizaciones fuera de alcance. Registrar inconsistencias preexistentes y programar su normalización por proyecto.
- Las migraciones de valores persistidos deben preservar datos, significado, integridad, permisos, consumidores y registros históricos; conservar migraciones históricas y validar proporcionalmente según la [política de esfuerzo](effort-validation.md).

## Adopción

Consultar esta fuente canónica y aplicar el [procedimiento de mantenimiento](../docs/policy-maintenance.md). Incorporar obligaciones esenciales en las instrucciones locales de los proyectos consumidores mediante cambios coordinados; no asumir sincronización automática.