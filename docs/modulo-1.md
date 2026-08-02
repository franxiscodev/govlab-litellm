# Módulo 1 — Despliegue de la infraestructura base

Levantar la pasarela de gobernanza: **LiteLLM Proxy + PostgreSQL 16 + Redis 7** sobre Docker Compose.

Al terminar tendrás un proxy operativo en `http://localhost:4000`, con la base de datos de auditoría
inicializada y el control de frecuencia listo. **Este módulo no realiza llamadas reales a
proveedores** — la conectividad con OpenAI y Anthropic es el Módulo 2, así que no consume créditos.

---

## 1. Por qué estos tres servicios

| Servicio | Rol en la gobernanza |
|---|---|
| **LiteLLM Proxy** | Punto de entrada único. Todo el tráfico de IA de la organización pasa por aquí: es lo que convierte el Shadow AI en algo medible. |
| **PostgreSQL** | Persiste virtual keys, presupuestos y el log de cada transacción. Es la base de la trazabilidad que exige el EU AI Act (Art. 12), con retención mínima de 6 meses. |
| **Redis** | Rate limiting por RPM/TPM, caché y estado compartido del router. Sin él los límites no sobreviven a un reinicio ni se sincronizan entre réplicas. |

Postgres y Redis se publican **solo en `127.0.0.1`**: puedes conectarte con DBeaver o pgAdmin para
las consultas de auditoría, pero no quedan expuestos a la red local.

---

## 2. Requisitos

- Docker Desktop **en ejecución** (no basta con tenerlo instalado: el daemon debe estar activo).
- Puertos `4000`, `5432` y `6379` libres.

```bash
docker compose version      # debe responder sin error
```

---

## 3. Despliegue

```bash
cd govlab-litellm
cp .env.example .env
```

Edita `.env` y sustituye los valores `cambia-esta-*` por secretos propios. Las claves de OpenAI y
Anthropic pueden quedarse como están: el Módulo 1 no las usa.

> **`LITELLM_SALT_KEY` es estática.** Cifra las API keys de proveedores que se guardan en
> PostgreSQL. Si la cambias después del primer arranque, esas credenciales quedan ilegibles de forma
> irreversible. Decídela ahora y no la toques.

```bash
docker compose up -d
```

El primer arranque descarga las imágenes y ejecuta las migraciones Prisma sobre PostgreSQL: puede
tardar **más de un minuto** hasta que el proxy aparezca como `healthy`. Es normal.

---

## 4. Verificación

```bash
./scripts/verify.sh
```

El script comprueba los siete puntos de aceptación. Equivalentes manuales:

```bash
# 1-3. Los tres contenedores en estado healthy
docker compose ps

# 4. El proxy está vivo
curl http://localhost:4000/health/liveliness

# 5. El proxy alcanza base de datos y caché
curl http://localhost:4000/health/readiness

# 6. LiteLLM ha creado su esquema de auditoría
docker exec govlab-postgres psql -U litellm_admin -d litellm_db -c "\dt"

# 7. Redis responde
docker exec govlab-redis redis-cli ping
```

En el punto 6 deben aparecer, entre otras, `LiteLLM_SpendTable` (log de gasto por transacción) y
`LiteLLM_VerificationToken` (virtual keys y presupuestos). Son las tablas sobre las que se
construyen los informes de los Módulos 4 y 5.

### Persistencia

La trazabilidad no sirve de nada si se pierde al reiniciar. Compruébalo:

```bash
docker compose down      # para los contenedores, conserva los volúmenes
docker compose up -d
./scripts/verify.sh      # las tablas siguen ahí
```

Solo `docker compose down -v` borra los volúmenes. Ese comando destruye el histórico de auditoría.

---

## 5. Interfaz de administración

`http://localhost:4000/ui` — autenticación con el valor de `LITELLM_MASTER_KEY` de tu `.env`.
En el Módulo 1 estará prácticamente vacía; se llena al crear virtual keys y equipos en el Módulo 4.

---

## 6. Problemas frecuentes

| Síntoma | Causa y solución |
|---|---|
| `failed to connect to the docker API ... dockerDesktopLinuxEngine` | Docker Desktop no está arrancado. Ábrelo y espera a que el icono deje de animarse. |
| `variable is not set` al hacer `up` | Falta `.env` o le falta alguna clave. Compara con `.env.example`. |
| `port is already allocated` | Otro Postgres o Redis local ocupa el puerto. Párralo o cambia el mapeo en `docker-compose.yml`. |
| `govlab-proxy` en `starting` mucho rato | Migraciones en curso. Espera al `start_period` de 90 s; si persiste: `docker compose logs litellm`. |
| El proxy reinicia con error de conexión a la BD | La contraseña de `.env` cambió pero el volumen conserva la antigua. Recrea con `docker compose down -v` (destruye datos). |
| `\r: command not found` al ejecutar `verify.sh` | El fichero se clonó con finales CRLF. Lo evita `.gitattributes`; si ya ocurrió: `dos2unix scripts/verify.sh`. |

---

## 7. Resultado

Infraestructura base operativa y verificada. El **Módulo 2** conecta proveedores reales
(OpenAI, Anthropic y Ollama en local) y empieza a registrar costes en `LiteLLM_SpendTable`.

Estado del repositorio al cerrar este módulo: tag `v1-infra`.
