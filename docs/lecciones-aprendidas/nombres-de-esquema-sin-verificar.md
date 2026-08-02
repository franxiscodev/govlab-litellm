---
fecha: 2026-08-02
contexto: Módulo 1 — despliegue de la infraestructura base
categoria: datos
severidad: alta
estado: resuelto
---

# Nombres de esquema copiados de la documentación, nunca verificados

## Síntoma

Ninguno. Ese es el problema de esta ficha: **no hubo síntoma**.

La base de conocimiento del proyecto y buena parte de la documentación de terceros hablan de la
tabla `LiteLLM_SpendTable` como el lugar donde se registran las transacciones. Sobre ese nombre
estaban escritas las tres consultas SQL de auditoría de `bases/knowledge_advanced.md` §8, previstas
para el Módulo 5.

El fallo habría aparecido meses después, al ejecutar el primer informe de gasto:

```text
ERROR:  relation "LiteLLM_SpendTable" does not exist
```

## Causa raíz

`LiteLLM_SpendTable` **no existe**. La tabla real se llama `LiteLLM_SpendLogs`.

El nombre incorrecto circula por documentación de terceros, blogs y respuestas generadas, y se
propagó a la base de conocimiento del proyecto sin que nadie lo contrastara contra un esquema real.
Como el Módulo 1 no ejecuta consultas de auditoría, nada lo habría revelado hasta el Módulo 5.

Un segundo detalle del mismo tipo: las columnas `startTime` y `endTime` están en camelCase. En
PostgreSQL, un identificador sin entrecomillar se pliega a minúsculas, así que `WHERE startTime >= …`
falla aunque el nombre de la tabla sea correcto. Hay que escribir `"startTime"`.

## Cómo se detectó

Al documentar el Módulo 1 escribí que aparecerían las tablas `LiteLLM_SpendTable` y
`LiteLLM_VerificationToken`. Antes de dar la documentación por buena, comprobé la afirmación contra
la base de datos en lugar de confiar en la fuente:

```bash
docker exec govlab-postgres psql -U litellm_admin -d litellm_db -tAc \
  "SELECT to_regclass('\"LiteLLM_SpendTable\"');"
```

Devolvió vacío. El listado completo mostró unas 70 tablas `LiteLLM_*`, entre ellas `LiteLLM_SpendLogs`
y ninguna `SpendTable`. Después verifiqué también las columnas contra `information_schema`: esas sí
eran correctas — `request_id`, `spend`, `prompt_tokens`, `completion_tokens`, `team_id`, `model`.

**La técnica generalizable**: `to_regclass()` en PostgreSQL devuelve `NULL` en lugar de lanzar un
error, lo que la hace ideal para comprobar la existencia de una tabla dentro de un script.

## Resolución

Commit `a80112a`. Corregido el nombre en `bases/knowledge.md`, en las tres consultas de
`bases/knowledge_advanced.md` §8 y en `docs/modulo-1.md`, con una nota que advierte del error
extendido y del entrecomillado obligatorio de los identificadores camelCase.

## Guardarraíl

`tabla_spendlogs()` en [`verify.sh`](../../govlab-litellm/scripts/verify.sh), añadido en `0ab8d7e`.
Comprueba con `to_regclass` que la tabla de auditoría existe con su nombre real, de modo que una
futura versión de la imagen que la renombre se detecte al desplegar y no cinco módulos después.

## Lección transferible

Un nombre de esquema copiado de la documentación es una suposición, no un hecho, hasta que se
contrasta contra el sistema real. Y las suposiciones sobre datos tienen una latencia peligrosa: no
fallan al escribirlas, fallan cuando alguien ejecuta el informe, que suele ser el peor momento.

La regla barata: cuando escribas el nombre de una tabla, columna o campo que no has visto con tus
ojos en el esquema, verifícalo en ese momento. Cuesta un comando y evita un fallo diferido.
