# Lecciones aprendidas

Hallazgos, incidencias e imponderables del proyecto que no se deducen del código ni del historial de
git. Cada ficha describe un **patrón**, no un incidente concreto, para que siga siendo útil cuando
el mismo problema reaparezca con otro servicio o en otro módulo.

Para añadir una, ver la skill
[lecciones-aprendidas](../../.claude/skills/lecciones-aprendidas/SKILL.md). Resumen: se proponen
solo al cerrar trabajo grande, nunca a mitad, y siempre previa confirmación.

## Índice

| Fecha | Ficha | Categoría | Sev. | Lección |
|---|---|---|---|---|
| 2026-08-02 | [Fusionar en local produce el mismo árbol, pero destruye el punto de revisión](merge-local-se-salta-el-pr.md) | proceso | media | Dos caminos con el mismo estado final no son equivalentes si uno deja un registro que el otro no |
| 2026-08-02 | [Un health check en verde no prueba que el servicio haga su trabajo](salud-aparente-vs-real.md) | infraestructura | alta | Para saber si A usa B, preguntar a B por sus clientes — no a A por su estado |
| 2026-08-02 | [Nombres de esquema copiados de la documentación, nunca verificados](nombres-de-esquema-sin-verificar.md) | datos | alta | Un nombre de tabla copiado es una suposición hasta que se contrasta contra el esquema real |
| 2026-08-02 | [La misma sintaxis significa cosas distintas según quién lea el fichero](os-environ-fuera-de-config-yaml.md) | herramientas | media | Una cadena con aspecto de plantilla es texto literal para todo intérprete que no la conozca |

## Cómo leer esta tabla

La última columna es lo que da unidad al conjunto: permite recorrer todo el aprendizaje del proyecto
sin abrir un solo fichero. Si una lección no cabe ahí en una línea, probablemente la ficha esté
describiendo un incidente en lugar de un patrón.

`Sev.` indica el alcance del fallo, no su dificultad: **alta** significa que llegó, o habría
llegado, a producción.
