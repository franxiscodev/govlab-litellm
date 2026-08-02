#!/usr/bin/env bash
# GovLab LiteLLM — verificación de salud del stack (Módulo 1).
#
# Comprueba los cinco criterios de aceptación de la infraestructura base.
# Ninguna comprobación consume créditos de API.
#
#   ./scripts/verify.sh

cd "$(dirname "$0")/.." || exit 1

if [ ! -f .env ]; then
  echo "ERROR: falta el fichero .env. Créalo con:  cp .env.example .env"
  exit 1
fi

# shellcheck disable=SC1091
set -a; . ./.env; set +a

PROXY_URL="http://localhost:4000"
FALLOS=0

check() {
  local nombre="$1"; shift
  printf '  %-46s' "$nombre"
  if output=$("$@" 2>&1); then
    echo "OK"
  else
    echo "FALLO"
    echo "$output" | sed 's/^/      /'
    FALLOS=$((FALLOS + 1))
  fi
}

salud_contenedor() {
  local estado
  estado=$(docker inspect --format '{{.State.Health.Status}}' "$1" 2>/dev/null)
  [ "$estado" = "healthy" ] || { echo "estado: ${estado:-no existe}"; return 1; }
}

endpoint_200() {
  local codigo
  codigo=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$1")
  [ "$codigo" = "200" ] || { echo "HTTP $codigo"; return 1; }
}

tablas_litellm() {
  local n
  n=$(docker exec govlab-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
        "SELECT count(*) FROM information_schema.tables WHERE table_name LIKE 'LiteLLM_%';" 2>&1)
  [ "$n" -gt 0 ] 2>/dev/null || { echo "tablas LiteLLM_* encontradas: ${n:-0}"; return 1; }
}

# La tabla de transacciones sobre la que se construye toda la auditoría de M4/M5.
tabla_spendlogs() {
  local r
  r=$(docker exec govlab-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc \
        "SELECT to_regclass('\"LiteLLM_SpendLogs\"');" 2>&1 | tr -d ' ')
  [ -n "$r" ] || { echo "LiteLLM_SpendLogs no existe"; return 1; }
}

redis_ping() {
  local r
  r=$(docker exec govlab-redis redis-cli ping 2>&1)
  [ "$r" = "PONG" ] || { echo "respuesta: $r"; return 1; }
}

# Que Redis esté vivo no implica que el proxy lo esté usando: sin redis_url en
# router_settings, LiteLLM arranca sano y nunca abre la conexión, dejando los
# límites RPM/TPM solo en memoria.
#
# El proxy conecta desde la red de Docker; este propio redis-cli entra por
# loopback. Se excluye loopback en vez de exigir un rango concreto: la subred
# la asigna Docker y varía entre máquinas y runners de CI.
redis_conectado_al_proxy() {
  local n
  n=$(docker exec govlab-redis redis-cli client list 2>&1 \
        | grep -oE 'addr=[^ ]+' | grep -vcE 'addr=(127\.0\.0\.1|::1|\[::1\])')
  [ "${n:-0}" -gt 0 ] 2>/dev/null || { echo "el proxy no tiene ninguna conexión abierta con Redis"; return 1; }
}

# os.environ/VAR es sintaxis de LiteLLM y solo funciona dentro de config.yaml.
# En la sección environment: de Docker asigna ese texto literal como valor, y
# LiteLLM acaba enviándolo como credencial: el 401 resultante no señala la causa.
# El ^[^#]* descarta los comentarios, que sí pueden mencionarla legítimamente.
sin_os_environ_en_compose() {
  local hits
  hits=$(grep -nE '^[^#]*:[[:space:]]*os\.environ/' docker-compose.yml)
  [ -z "$hits" ] || { echo "os.environ/ usado como valor en docker-compose.yml:"; echo "$hits"; return 1; }
}

echo
echo "Verificación del stack GovLab LiteLLM"
echo "-------------------------------------"
check "Contenedor govlab-postgres saludable"   salud_contenedor govlab-postgres
check "Contenedor govlab-redis saludable"      salud_contenedor govlab-redis
check "Contenedor govlab-proxy saludable"      salud_contenedor govlab-proxy
check "Endpoint /health/liveliness"            endpoint_200 "$PROXY_URL/health/liveliness"
check "Endpoint /health/readiness"             endpoint_200 "$PROXY_URL/health/readiness"
check "Tablas LiteLLM_* creadas en PostgreSQL" tablas_litellm
check "Tabla de auditoría LiteLLM_SpendLogs"   tabla_spendlogs
check "Redis responde PONG"                    redis_ping
check "El proxy mantiene conexión con Redis"   redis_conectado_al_proxy
check "Sin os.environ/ en docker-compose.yml"  sin_os_environ_en_compose
echo

if [ "$FALLOS" -eq 0 ]; then
  echo "Todas las comprobaciones han pasado."
  echo
  echo "Detalle de /health/readiness:"
  curl -s "$PROXY_URL/health/readiness" | sed 's/^/  /'
  echo
else
  echo "$FALLOS comprobación(es) fallida(s)."
  echo "Revisa los logs con:  docker compose logs --tail 50 litellm"
  exit 1
fi
