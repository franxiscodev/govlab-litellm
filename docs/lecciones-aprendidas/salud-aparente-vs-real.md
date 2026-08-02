---
fecha: 2026-08-02
contexto: Módulo 1 — despliegue de la infraestructura base
categoria: infraestructura
severidad: alta
estado: resuelto
---

# Un health check en verde no prueba que el servicio haga su trabajo

## Síntoma

Todo indicaba que el stack estaba correcto. Los tres contenedores en `healthy`:

```text
  Contenedor govlab-postgres saludable          OK
  Contenedor govlab-redis saludable             OK
  Contenedor govlab-proxy saludable             OK
```

Y el endpoint de disponibilidad del proxy respondiendo sin errores:

```json
{"status":"healthy","db":"connected"}
```

Nada apuntaba a que Redis, presente y sano, no estuviera prestando ningún servicio.

## Causa raíz

LiteLLM **nunca abrió una conexión con Redis**. Definir `REDIS_URL` en el entorno del contenedor no
basta: sin `redis_url` dentro de `router_settings` en `config.yaml`, el router no lo usa.

La consecuencia no es cosmética. Los contadores de límite de frecuencia (RPM/TPM) vivían en la
memoria del proceso, así que **se perdían en cada reinicio** y no se habrían compartido entre
réplicas — exactamente los dos problemas que Redis está ahí para resolver.

El síntoma despistaba porque `/health/readiness` informa del estado de la base de datos pero no
menciona la caché cuando esta no está configurada. La ausencia de un campo se lee como "no aplica",
no como "no funciona".

## Cómo se detectó

Preguntando a Redis quién estaba conectado, en lugar de preguntar al proxy si se encontraba bien:

```bash
docker exec govlab-redis redis-cli client list
```

La única conexión provenía de `127.0.0.1`, que era el propio `redis-cli` de la comprobación. Ninguna
desde la red de Docker. El contador `total_commands_processed` lo confirmó: los 43 comandos
registrados correspondían al healthcheck del contenedor, no a tráfico del proxy.

**La técnica generalizable**: para saber si A usa B, preguntar a **B por sus clientes**, no a A por
su estado. Un servicio siempre informa bien de sí mismo; lo que no sabe es lo que nunca le pidieron.

## Resolución

Commit `090274a` — tres líneas en `config.yaml`:

```yaml
router_settings:
  redis_url: os.environ/REDIS_URL
```

Tras recrear el contenedor, `client list` pasó a mostrar conexiones reales desde `172.25.0.4`.

## Guardarraíl

`redis_conectado_al_proxy()` en [`verify.sh`](../../govlab-litellm/scripts/verify.sh), añadido en
`0ab8d7e`. Cuenta las conexiones que llegan desde la red de Docker
(`addr=172.`), descartando las de loopback que genera la propia comprobación.

Verificado fallando antes del arreglo: con la configuración anterior el test daba
`el proxy no tiene ninguna conexión abierta con Redis`.

## Lección transferible

Un health check demuestra que un proceso está vivo, no que esté cumpliendo su función. Cuando un
componente existe para conectar con otro, la comprobación válida es la que observa **la conexión**,
no la que pregunta a cada extremo cómo se encuentra.

Y un aviso más incómodo: un panel entero en verde es precisamente la condición en la que nadie mira
más a fondo. En sistemas cuyo propósito es el control — límites de gasto, cuotas, auditoría — un
falso verde no es un fallo técnico menor, es la pérdida silenciosa del control que se creía tener.
