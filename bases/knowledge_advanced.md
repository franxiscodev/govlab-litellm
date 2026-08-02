# BASE DE CONOCIMIENTO AVANZADA: GUARDRAILS, CACHÉ SEMÁNTICA Y AUDITORÍA (2026)

---

## 6. GUARDRAILS, ANONIMIZACIÓN DE PII Y SEGURIDAD EN PROMPTS

### 6.1. Detección y Redacción de Datos Personales (PII con Presidio / Guardrails)

Para cumplir con el RGPD y el EU AI Act, LiteLLM permite interceptar los prompts antes de que salgan hacia proveedores cloud (OpenAI/Anthropic) y enmascarar PII (nombres, tarjetas de crédito, números de teléfono, DNI/emails).

#### Configuración en config.yaml

```yaml
litellm_settings:
  guardrails:
    - guardrail_name: "pii-masking"
      litellm_params:
        guardrail: "presidio"
        mode: "during_call"
        default_on: true
        output_parse_mode: "guardrail_response"
```

### 6.2. Inyección de System Prompts de Seguridad

LiteLLM permite forzar un System Prompt corporativo a nivel de pasarela para garantizar que ningún modelo responda a peticiones fuera de la política de uso corporativo.

```yaml
model_list:
  - model_name: gpt-4o-gov
    litellm_params:
      model: openai/gpt-4o
      system_prompt: "Eres un asistente corporativo de la empresa. No compartas código confidencial, no reveles llaves de API y mantén un tono profesional."
```

---

## 7. CACHÉ SEMÁNTICA CON REDIS (REDUCCIÓN RADICAL DE COSTES)

### 7.1. Caché Exacta vs. Caché Semántica

- **Caché Exacta:** Retorna la respuesta guardada en Redis solo si el prompt es 100% idéntico carácter por carácter.
- **Caché Semántica:** Utiliza embeddings para determinar si la pregunta del usuario es similar en un 85%+ a una pregunta realizada previamente, respondiendo de inmediato desde Redis con tiempo de respuesta <10 ms y coste $0.00.

### 7.2. Configuración de Caché en config.yaml

```yaml
litellm_settings:
  cache: true
  cache_params:
    type: "redis"
    supported_call_types: ["completion", "acompletion", "chat_completion", "achat_completion"]
    similarity_threshold: 0.85
    ttl: 86400
```

---

## 8. CONSULTAS SQL PARA AUDITORÍA DE CFO E INFORMES DE GASTO

LiteLLM almacena todas las transacciones en PostgreSQL (`LiteLLM_SpendTable` y `LiteLLM_VerificationToken`).

### 8.1. Consulta 1: Gasto acumulado por Equipo (team_id) en los últimos 30 días

```sql
SELECT
    team_id,
    COUNT(request_id) AS total_peticiones,
    SUM(prompt_tokens) AS total_prompt_tokens,
    SUM(completion_tokens) AS total_completion_tokens,
    ROUND(SUM(spend)::numeric, 4) AS gasto_total_usd
FROM
    "LiteLLM_SpendTable"
WHERE
    "startTime" >= NOW() - INTERVAL '30 days'
GROUP BY
    team_id
ORDER BY
    gasto_total_usd DESC;
```

### 8.2. Consulta 2: Top 5 modelos más consumidos y su coste promedio por petición

```sql
SELECT
    model,
    COUNT(request_id) AS volumen_llamadas,
    ROUND(AVG(spend)::numeric, 6) AS costo_promedio_por_peticion_usd,
    ROUND(SUM(spend)::numeric, 4) AS gasto_acumulado_usd
FROM
    "LiteLLM_SpendTable"
GROUP BY
    model
ORDER BY
    gasto_acumulado_usd DESC
LIMIT 5;
```

### 8.3. Consulta 3: Auditoría de Virtual Keys que alcanzaron su límite de presupuesto

```sql
SELECT
    token,
    key_name,
    user_id,
    max_budget,
    spend,
    ROUND((spend / max_budget * 100)::numeric, 2) AS porcentaje_consumido
FROM
    "LiteLLM_VerificationToken"
WHERE
    max_budget IS NOT NULL AND spend >= max_budget;
```

---

## 9. OBSERVABILIDAD, PROMETHEUS Y ALERTAS EN SLACK

### 9.1. Métricas de Prometheus

LiteLLM expone un endpoint nativo `/metrics` para scraping desde Prometheus/Grafana:

- `litellm_requests_metric`: Contador de peticiones totales.
- `litellm_spend_metric`: Gasto financiero en tiempo real.
- `litellm_latency_metric`: Tiempos de respuesta p95 y p99 por proveedor.

### 9.2. Alertas por Webhook (Slack / Discord / Teams)

Configuración en config.yaml:

```yaml
litellm_settings:
  alerting_threshold: 0.80
  slack_webhook_url: os.environ/SLACK_WEBHOOK_URL
```

---

## 10. INTEGRACIÓN EN APLICACIONES CLIENTE (SDKs, LANGCHAIN Y LLAMAINDEX)

### 10.1. Conexión desde Python Nativo (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000",
    api_key="sk-virtual-key-asignada-al-equipo"
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "¿Cómo optimizar la batería en servidores?"}]
)

print(response.choices[0].message.content)
```

### 10.2. Conexión desde LangChain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model_name="claude-3-5-sonnet",
    openai_api_base="http://localhost:4000",
    openai_api_key="sk-virtual-key-asignada-al-equipo"
)

resultado = llm.invoke("Resume las obligaciones principales del EU AI Act.")
print(resultado.content)
```

### 10.3. Conexión desde LlamaIndex

```python
from llama_index.llms.openai import OpenAI

llm = OpenAI(
    model="gpt-4o",
    api_base="http://localhost:4000",
    api_key="sk-virtual-key-asignada-al-equipo"
)

response = llm.complete("Genera un esquema de gobernanza para PYMEs.")
print(response)
```
