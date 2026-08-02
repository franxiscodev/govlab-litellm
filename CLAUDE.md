# GovLab LiteLLM

Laboratorio de gobernanza de IA: una pasarela corporativa real (LiteLLM Proxy + PostgreSQL + Redis)
que sirve a la vez como **infraestructura de consultoría para PYMEs** (prevención de Shadow AI,
control de costes, cumplimiento EU AI Act / RGPD) y como **material docente** en 6 módulos.

Rol al trabajar en este repo: **Ingeniero Senior de Infraestructura & DevOps**.

## Arquitectura

| Servicio | Imagen | Puerto | Función |
|---|---|---|---|
| `govlab-proxy` | `ghcr.io/berriai/litellm:main-latest` | `4000` | Pasarela unificada, enrutamiento, virtual keys |
| `govlab-postgres` | `postgres:16-alpine` | `127.0.0.1:5432` | Virtual keys, auditoría de costes, logs de transacciones |
| `govlab-redis` | `redis:7-alpine` | `127.0.0.1:6379` | Rate limiting (RPM/TPM), caché, estado del router |

El stack vive en [govlab-litellm/](govlab-litellm/). Postgres y Redis se publican solo en
loopback: accesibles desde DBeaver/pgAdmin para las consultas de auditoría, no expuestos a la red.

## Roadmap de módulos

1. **M1** — Despliegue de infraestructura base (Docker Compose, Postgres, Redis, Proxy).
2. **M2** — Conectividad multiproveedor (OpenAI + Anthropic + Ollama) y gestión de costes.
3. **M3** — Routing inteligente, balanceo de carga y fallbacks dinámicos.
4. **M4** — Gobernanza corporativa: Virtual Keys, rate limits y presupuestos por equipo.
5. **M5** — Auditoría, trazabilidad de prompts, guardrails de PII, EU AI Act / RGPD.
6. **M6** — Empaquetado de servicios de consultoría para PYMEs.

Fuente de verdad de contenidos: [bases/](bases/) (`plan_maestro.md`, `knowledge.md`,
`knowledge_advanced.md`). Si un módulo contradice a `bases/`, corregir `bases/` en un commit aparte.

## Estructura del repositorio

Un **stack único que evoluciona**, no una carpeta por módulo. Cada módulo se cierra con un tag git
(`v1-infra`, `v2-multiproveedor`, …), de modo que `git diff v1-infra v2-multiproveedor` muestra
exactamente qué aporta el módulo — el historial *es* el material docente.

Los servicios que aparecen a mitad del roadmap (Ollama en M2, Presidio en M5) se declaran con
`profiles:` de Docker Compose, no duplicando ficheros.

## Reglas de operación

**Configuración**
- Entregar siempre bloques **completos y funcionales**. Prohibido `# código aquí`, `...` o elisiones.
- Tras cualquier cambio en el stack, verificar de verdad: `docker compose ps` y
  `curl http://localhost:4000/health/readiness`. No dar por bueno un arranque parcial —
  si algo falla, reportar la salida real y el diagnóstico.

**Secretos**
- Todo secreto vive en `govlab-litellm/.env`, que está en `.gitignore`. Nunca hardcodear
  credenciales en `docker-compose.yml`, `config.yaml` ni en la documentación.
- Al añadir una variable, añadirla también a `.env.example` con un placeholder.
- `LITELLM_SALT_KEY` **no se puede cambiar** tras el primer arranque: cifra las API keys
  almacenadas en Postgres y modificarla las inutiliza.

**Sintaxis `os.environ/` — error frecuente**
- En `config.yaml` (lo lee LiteLLM): `api_key: os.environ/OPENAI_API_KEY` ✅
- En `docker-compose.yml` (lo lee Docker): `OPENAI_API_KEY: ${OPENAI_API_KEY}` ✅

  Poner `os.environ/…` en la sección `environment:` de Docker asigna ese texto *literal*
  como valor de la variable, y LiteLLM acaba enviándolo como credencial → 401 engañoso.

**Python**
- Gestor de paquetes: **UV** (`uv run`, `uv add`, `uv sync`). No usar pip, poetry ni pipenv.

**Lecciones aprendidas**
- Los hallazgos no obvios se registran en [docs/lecciones-aprendidas/](docs/lecciones-aprendidas/),
  siguiendo la skill [lecciones-aprendidas](.claude/skills/lecciones-aprendidas/SKILL.md).
- **Solo se proponen al cerrar trabajo grande** — un módulo, una feature con varios commits, una
  sesión larga de depuración. Nunca a mitad de una tarea, y como mucho una propuesta por tarea.
- **Nunca escribir una ficha sin confirmación explícita.** Se presenta la lista de candidatas y se
  espera respuesta.
- La skill está en pruebas: si un criterio falla en la práctica, decirlo y proponer la mejora en
  lugar de forzar la plantilla.

**Git**
- Ver la skill [git-conventional-commits](.claude/skills/git-conventional-commits/SKILL.md).
- Rama `feature/*` por módulo, Conventional Commits, commits atómicos, tag al cerrar el módulo.
- Nunca hacer `push` sin avisar antes.
- Los ficheros montados en contenedores Linux usan LF — ver `.gitattributes`.

## Comandos habituales

```bash
cd govlab-litellm

docker compose up -d          # levantar el stack
docker compose ps             # estado y salud de los 3 servicios
docker compose logs -f litellm
docker compose down           # parar (los volúmenes persisten)

./scripts/verify.sh           # comprobación completa de salud
```
