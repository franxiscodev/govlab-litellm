# BASE DE CONOCIMIENTO TÉCNICO Y ESTRATÉGICO: GOVLAB LITELLM (2026)

---

## 1. ARQUITECTURA TÉCNICA DE LITELLM PROXY & DEVOPS

### 1.1. Infraestructura de Contenedores (Docker Compose)
LiteLLM en un laboratorio de gobernanza o entorno de producción requiere tres servicios interconectados:
1. **LiteLLM Proxy Container:** El punto de entrada y pasarela unificada (Puerto `4000`).
2. **PostgreSQL Database:** Persistencia de Virtual Keys, auditoría de peticiones, logs de consumo y presupuestos por equipo/usuario.
3. **Redis Store:** Control de frecuencia (*rate limiting* por RPM/TPM), caché distribuida y sincronización de estado del enrutador.

#### Docker Compose de Referencia:
```yaml
version: '3.8'

services:
  db:
    image: postgres:16-alpine
    container_name: govlab-postgres
    environment:
      POSTGRES_USER: litellm_admin
      POSTGRES_PASSWORD: litellm_secure_password
      POSTGRES_DB: litellm_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U litellm_admin -d litellm_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: govlab-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: govlab-proxy
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml
    environment:
      DATABASE_URL: "postgresql://litellm_admin:litellm_secure_password@db:5432/litellm_db"
      REDIS_URL: "redis://redis:6379"
      LITELLM_MASTER_KEY: "sk-govlab-master-key-2026"
      LITELLM_SALT_KEY: "sk-govlab-encryption-salt-must-be-long-and-static"
      # Valor real inyectado desde .env. La sintaxis os.environ/… pertenece
      # solo a config.yaml: aquí asignaría ese texto literal como credencial.
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
    command: ["--config", "/app/config.yaml", "--port", "4000", "--detailed_debug"]
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

volumes:
  postgres_data:
  redis_data:
```
### 1.2. Variables de Entorno Críticas
LITELLM_MASTER_KEY: Llave maestra de administración (necesaria para autenticarse en la interfaz gráfica /ui y en endpoints administrativos /key/generate).

LITELLM_SALT_KEY: Clave estática obligatoria para cifrar en PostgreSQL las API keys de proveedores introducidas desde la interfaz gráfica. Nunca se debe modificar tras iniciar el servidor.

DATABASE_URL: URL de conexión PostgreSQL para la tabla de consumo, logs de auditoría y claves virtuales.

REDIS_URL: Conexión Redis para límites de tasa (RPM/TPM) y caché.

2. ENRUTAMIENTO, CONFIGURACIÓN Y MODELOS (config.yaml)
2.1. Estructura Completa de Configuración
LiteLLM permite definir modelos, estrategias de balanceo de carga, fallbacks y reglas globales mediante su archivo config.yaml:

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY
      rpm: 1000
      tpm: 80000

  - model_name: claude-3-5-sonnet
    litellm_params:
      model: anthropic/claude-3-5-sonnet-20241022
      api_key: os.environ/ANTHROPIC_API_KEY
      rpm: 500

  - model_name: llama3-local
    litellm_params:
      model: ollama_chat/llama3.3
      api_base: http://host.docker.internal:11434
      rpm: 200

router_settings:
  routing_strategy: latency-based-routing
  num_retries: 3
  cooldown_time: 30
  fallbacks:
    - gpt-4o: [claude-3-5-sonnet, llama3-local]
    - claude-3-5-sonnet: [gpt-4o, llama3-local]

litellm_settings:
  drop_params: true
  set_verbose: false
  json_logs: true
```

---

#### 📄 Parte 2 de 2: `knowledge.md`

```markdown
### 2.2. Endpoints Administrativos de la API REST
- `POST /key/generate`: Genera una *Virtual Key* asociada a un presupuesto (`max_budget`), duración (`budget_duration`), límite de tasa (`rpm`/`tpm`) y asignada a un `team_id` o `user_id`.
- `GET /key/info`: Consulta el presupuesto restante y métricas de uso de una llave.
- `POST /team/new`: Crea un equipo corporativo con límite de gasto agregado.
- `POST /user/new`: Registra un usuario en la plataforma de gobernanza.
- `GET /spend/keys`: Devuelve el reporte detallado de gasto de todas las llaves en formato JSON.

---

## 3. MARCO DE GOBERNANZA, EU AI ACT Y PRIVACIDAD EN PYMES

### 3.1. Alineación con el EU AI Act
1. **Transparencia y Trazabilidad (Art. 12 & 50):** Toda consulta y respuesta registrada en la tabla `LiteLLM_SpendTable` de PostgreSQL garantiza auditoría por el tiempo legal requerido (mínimo 6 meses).
2. **Control Humano y Prevención de Riesgos:** Revocación instantánea de Virtual Keys ante usos anómalos.
3. **Clasificación del Enrutamiento:**
   - **Datos Confidenciales / Sensibles:** Enrutamiento forzoso a modelos locales (Ollama) para cumplimiento de RGPD y secreto comercial.
   - **Procesamiento General:** Enrutamiento a modelos cloud previa aplicación de políticas de privacidad.

### 3.2. Modelo de Gobernanza de Costes
- **Prevención de Shadow AI:** Reemplazo de tarjetas personales por Virtual Keys departamentales con límites fijos.
- **Hard Limits vs Soft Limits:**
  - *Hard Limit:* Bloqueo HTTP 400 inmediato al alcanzar el presupuesto (`max_budget`).
  - *Soft Limit:* Alerta por Webhook/Email al alcanzar el 80% del gasto fijado.

---

## 4. DISEÑO INSTRUCCIONAL & RECURSOS MULTIMODALES CON IA

### 4.1. Formato de Ingesta para NotebookLM
Redacción en bloques tipo **Knowledge Base (KB)** para maximizar la calidad de los "Audio Overviews":
- Afirmaciones fácticas directas y estructuradas en listas o tablas.
- Relaciones explícitas de causa-efecto.
- Preguntas y Respuestas (Q&A) frecuentes de auditoría, técnica y negocio.

### 4.2. Prompts para Generación Visual (Marp, Gamma AI, Napkin AI)
- **Diagramas en Mermaid.js:** Esquemas de flujo o arquitectura directamente en Markdown.
- **Diapositivas en Gamma.app / Marp:** Declaraciones cortas separadas por marcas de diapositiva.
- **Infografías en Napkin.ai:** Listas conceptuales etiquetadas para mapeo automático de íconos.

---

## 5. PROTOCOLO DE INTERACCIÓN CON CLAUDE CODE (TERMINAL EXECUTOR)

### 5.1. Reglas de Entrega de Prompts CLI
1. **Contexto del Directorio:** Ruta exacta del proyecto (ej. `./govlab-litellm/modulo1`).
2. **Archivos a Crear/Modificar:** Contenido completo y sin elisiones (`...`).
3. **Comandos de Verificación:** `docker compose up -d`, `curl http://localhost:4000/health/readiness` y validación de métricas en Postgres.