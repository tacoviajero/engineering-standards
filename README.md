# Engineering Standards — TacoViajero

Estándares compartidos de ingeniería para los proyectos de software de TacoViajero.

## Política global vigente

- [Política obligatoria de esfuerzo y validación proporcional](policies/effort-validation.md): documento canónico para ajustar el esfuerzo y las comprobaciones al riesgo real de cada tarea.

## Documentación de cada proyecto

Cada repositorio de producto mantiene su documentación propia:

- `AGENTS.md`: instrucciones operativas que Codex debe tener disponibles al ejecutar tareas.
- `PROJECT.md`: descripción del producto, arquitectura, decisiones y estado vigente.
- `docs/validation.md`: verificaciones y comandos específicos de ese proyecto.

La política global establece principios comunes. Las instrucciones locales detallan su aplicación a cada arquitectura y pueden imponer controles más estrictos, pero no omitir validaciones obligatorias del repositorio o de CI.

## Aplicación y sincronización

Publicar una política en este repositorio **no hace que Codex la lea automáticamente**. Cada proyecto debe incorporar sus obligaciones operativas en instrucciones que el agente realmente cargue, o disponer de un mecanismo verificable para consultar el documento antes de actuar.

Cuando cambie la política global, revisar el impacto e incorporar explícitamente la actualización en cada proyecto. No asumir sincronización automática. Ante contradicciones con instrucciones superiores, requisitos de seguridad o validaciones obligatorias, respetar estos últimos y señalar el conflicto.

## Mejora continua

Las lecciones reutilizables procedentes de proyectos concretos pueden proponerse como cambios a este estándar. No trasladar automáticamente detalles o restricciones específicas de un producto al resto.
