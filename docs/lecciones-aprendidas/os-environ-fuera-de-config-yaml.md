---
fecha: 2026-08-02
contexto: Módulo 1 — despliegue de la infraestructura base
categoria: herramientas
severidad: media
estado: resuelto
---

# La misma sintaxis significa cosas distintas según quién lea el fichero

## Síntoma

El docker-compose de referencia de `bases/knowledge.md` pasaba las credenciales así:

```yaml
    environment:
      OPENAI_API_KEY: "os.environ/OPENAI_API_KEY"
      ANTHROPIC_API_KEY: "os.environ/ANTHROPIC_API_KEY"
```

Se lee como correcto. Es la misma sintaxis que aparece en `config.yaml` unas líneas más abajo, donde
sí funciona. El stack arranca sin ninguna queja.

El fallo solo aparecería en el Módulo 2, en la primera llamada real a un proveedor, como un
**HTTP 401** cuyo mensaje habla de una clave inválida y no menciona la configuración.

## Causa raíz

`os.environ/VAR` es sintaxis **de LiteLLM**, no de Docker. LiteLLM la resuelve al leer su
`config.yaml`.

Docker Compose no sabe nada de ella. En la sección `environment:` la trata como lo que
sintácticamente es —una cadena de texto— y asigna literalmente `"os.environ/OPENAI_API_KEY"` como
valor de la variable. Después `config.yaml` pide `os.environ/OPENAI_API_KEY`, LiteLLM resuelve la
variable correctamente… y obtiene esa misma cadena, que envía a OpenAI como credencial.

El diagnóstico es lento porque **cada capa hace bien su trabajo**. No hay ningún error de sintaxis,
ningún aviso, ningún log sospechoso. El único indicio es un 401 remoto que apunta al proveedor, no a
la configuración local.

La forma correcta en cada fichero:

| Fichero | Lo lee | Sintaxis correcta |
|---|---|---|
| `config.yaml` | LiteLLM | `api_key: os.environ/OPENAI_API_KEY` |
| `docker-compose.yml` | Docker Compose | `OPENAI_API_KEY: ${OPENAI_API_KEY}` |

## Cómo se detectó

Por lectura, no por ejecución: al adaptar el docker-compose de referencia para externalizar los
secretos a `.env`, la incoherencia saltó a la vista. La misma cadena aparecía en dos ficheros que
lee software distinto, y solo uno de los dos la entiende.

**La técnica generalizable**: ante una expresión que aparece en varios ficheros de configuración,
preguntarse siempre *qué programa parsea este fichero concreto*. Las sintaxis con aspecto de
plantilla —`os.environ/`, `${}`, `{{ }}`, `!ref`— pertenecen a un intérprete específico y son texto
inerte para cualquier otro.

## Resolución

Commit `156fb70`. Corregido en `bases/knowledge.md`, con un comentario que explica la distinción para
que no se vuelva a copiar mal. El `docker-compose.yml` del proyecto nunca llegó a tener el fallo:
usa `${VAR}` desde el principio, con la advertencia escrita al lado en la línea 57.

La regla quedó también en `CLAUDE.md`, en la sección de reglas de operación.

## Guardarraíl

`sin_os_environ_en_compose()` en [`verify.sh`](../../govlab-litellm/scripts/verify.sh), añadido en
`147e9f8`:

```bash
grep -nE '^[^#]*:[[:space:]]*os\.environ/' docker-compose.yml
```

El `^[^#]*` descarta los comentarios, de modo que la nota explicativa que vive en el propio
`docker-compose.yml` no produce falso positivo.

Verificado en ambos sentidos: pasa con el fichero actual, y al reintroducir la línea incorrecta a
propósito falla señalando el número de línea. Es el caso que casi se documenta como
"no automatizable": lo parecía, y resultaron ser tres líneas.

## Lección transferible

Una cadena con aspecto de plantilla solo es una plantilla para el programa que sabe interpretarla.
Para cualquier otro es texto literal — y lo peor es que lo acepta sin protestar, porque como texto
es perfectamente válido.

El patrón a vigilar: **dos ficheros de configuración, dos intérpretes distintos, una sintaxis que
solo uno entiende**. Docker y su herramienta, Terraform y el proveedor, CI y el script que invoca.
Cuando el mismo texto viaja entre capas, hay que preguntarse en cuál se resuelve.
