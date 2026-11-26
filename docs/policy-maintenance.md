# Mantenimiento del estándar global

## Fuente canónica y alcance

Las políticas obligatorias se mantienen **una sola vez** en la rama `main` de este repositorio:

- [`policies/effort-validation.md`](../policies/effort-validation.md): esfuerzo y validación proporcional.
- [`policies/code-language-conventions.md`](../policies/code-language-conventions.md): idioma y nomenclatura técnica.

Los cinco repositorios consumidores son:

- `tacoviajero/cheeky-van-app`
- `tacoviajero/tizon`
- `tacoviajero/liga-maestra`
- `tacoviajero/taco-viajero`
- `tacoviajero/360tours-studio`

Cada proyecto conserva `AGENTS.md` para sus instrucciones operativas, `PROJECT.md` para el estado y `docs/validation.md` para las comprobaciones propias de su arquitectura. **No copiar íntegramente la política global en los proyectos**: enlazarla y mantener sólo las obligaciones esenciales necesarias cuando el agente no pueda consultarla.

Una referencia desde `AGENTS.md` a una URL **no significa que Codex la descargue automáticamente**. Al iniciar una tarea, el agente debe aplicar las reglas disponibles en su contexto y, cuando la política canónica sea accesible, consultar su versión actual. Si no es accesible y la regla requerida no está disponible localmente, debe informar la limitación en lugar de suponer contenido.

## Procedimiento para actualizar la política

1. Proponer el cambio en una PR de **este repositorio**. Distinguir una aclaración editorial de una modificación de obligaciones.
2. Revisar el cambio respecto de la política anterior. Si es editorial y no modifica el significado de las instrucciones locales, **no abrir cinco PR por costumbre**.
3. Si cambia una obligación resumida en `AGENTS.md`, preparar sólo las PR puntuales necesarias en los proyectos afectados; preservar todas sus reglas específicas. No hacer merges en repositorios consumidores sin aprobación.
4. Si el cambio exige nuevos comandos de prueba o criterios técnicos, actualizar sólo los `docs/validation.md` de los proyectos relevantes.
5. Verificar que la política canónica y los enlaces siguen accesibles y que no hay contradicciones materiales. Registrar qué repositorios requieren actualización y cuáles no.
6. No asumir que un workspace local se sincronizó tras un merge remoto. Auditarlo aparte sin sobrescribir cambios locales.

Este procedimiento evita mantener cinco copias completas. **No es sincronización automática de código**: las instrucciones locales de respaldo siguen requiriendo revisión cuando cambia su significado.

## Auditoría de workspaces locales (Windows)

El script [`scripts/audit-local-workspaces.ps1`](../scripts/audit-local-workspaces.ps1) encuentra repositorios Git a una profundidad limitada y reporta: ruta, repositorio remoto, rama, SHA local, SHA de `main` remoto, cantidad de cambios locales y presencia de la referencia a la política en `AGENTS.md`.

Ejemplo desde un clon local de `engineering-standards`:

```powershell
.\scripts\audit-local-workspaces.ps1 -RootDirectory 'C:\Users\KLozk\Documents\TacoViajero\Code'
```

Sólo consulta Git: no ejecuta `fetch`, `pull`, `reset`, `stash` ni cambia archivos. Usa `git ls-remote` para consultar GitHub sin alterar referencias locales. Requiere `git` instalado y acceso autenticado a los remotos privados; un error de acceso se reporta como remoto no verificable. La comparación de SHAs no demuestra por sí sola si una rama está adelantada o atrasada: se informa únicamente si corresponde al mismo commit remoto.

Si hay cambios locales, se deben preservar y reconciliar en el chat de control de versiones de ese proyecto; no sincronizar a la fuerza.

## Criterio de cierre

Un proyecto tiene el estándar **publicado** cuando sus tres documentos existen en `main` y `AGENTS.md` remite al documento canónico con instrucciones operativas suficientes. Tiene el estándar **disponible localmente** sólo cuando el workspace que usará Codex fue verificado por separado. El cumplimiento durante una tarea real requiere evidencia de ejecución; no se infiere de un enlace.
