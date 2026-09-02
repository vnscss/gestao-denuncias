#!/usr/bin/env bash

set -a
set +H  # disable history expansion (! in passwords/keys)

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPTS_DIR/../docker"

DOT_ENV="$DOCKER_DIR/.env"

if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root" >&2
  exit 1
fi


if [ ! -f "$DOT_ENV" ]; then
  echo "❌ Env file not found: $DOT_ENV"
  exit 1
fi


echo "📥 Loading $DOT_ENV..."
while IFS='=' read -r key value; do
  key="${key#"${key%%[![:space:]]*}"}"
  [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
  export "$key=$value"
done < "$DOT_ENV"
set +a

echo ""
echo "📋 Environment preview:"
echo "---------------------------------"
echo "DEBUG=$DEBUG"
echo "DB_NAME=$DB_NAME"
echo "DB_USER=$DB_USER"
echo "DB_HOST=$DB_HOST"
echo "DB_PORT=$DB_PORT"
echo "APP_DB_USER=$APP_DB_USER"
echo "REDIS_URL=$REDIS_URL"
echo "ALLOWED_HOSTS=$ALLOWED_HOSTS"
echo "NGINX_PORT=$NGINX_PORT"
echo "POSTGRES_DATA_DIR=$POSTGRES_DATA_DIR"
echo "REDIS_DATA_DIR=$REDIS_DATA_DIR"
echo "STATIC_FILES_DIR=$STATIC_FILES_DIR"
echo "MEDIA_FILES_DIR=$MEDIA_FILES_DIR"
echo "---------------------------------"
echo ""

echo "🔍 Validating host data directories..."
for d in POSTGRES_DATA_DIR REDIS_DATA_DIR STATIC_FILES_DIR MEDIA_FILES_DIR; do
  if [ -z "${!d}" ]; then
    echo "❌ Environment variable $d is not set. Configure it in $DOT_ENV" >&2
    exit 1
  fi
done

echo "📁 Creating host data directories if missing..."
mkdir -p \
  "$POSTGRES_DATA_DIR" \
  "$REDIS_DATA_DIR" \
  "$STATIC_FILES_DIR" \
  "$MEDIA_FILES_DIR"
echo "✅ Directories ready:"
echo "  POSTGRES_DATA_DIR=$POSTGRES_DATA_DIR"
echo "  REDIS_DATA_DIR=$REDIS_DATA_DIR"
echo "  STATIC_FILES_DIR=$STATIC_FILES_DIR"
echo "  MEDIA_FILES_DIR=$MEDIA_FILES_DIR"

read -p "🚀 Continue with docker compose? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit 0

NETWORK_CREATED=0

cleanup() {
  echo ""
  echo "🛑 Shutting down stack..."
  cd "$DOCKER_DIR" 2>/dev/null || true
  sudo -E docker compose down
  sudo -E docker compose -f postgres/docker-compose.yml down
  sudo -E docker compose -f redis/docker-compose.yml down
  if [ "$NETWORK_CREATED" = "1" ]; then
    echo "🔗 Removing shared_net..."
    sudo docker network rm shared_net >/dev/null 2>&1 || true
  fi
  echo "✅ Stack shut down. Dados preservados nos bind mounts."
  exit 0
}
trap cleanup INT TERM EXIT

echo "Closing all containers..."
docker stop $(docker ps -q)

cd "$DOCKER_DIR"

echo "🔗 Ensuring shared_net exists..."
if ! sudo docker network inspect shared_net >/dev/null 2>&1; then
  sudo docker network create shared_net
  NETWORK_CREATED=1
fi

echo "🚀 Starting PostgreSQL cluster..."
sudo -E docker compose -f postgres/docker-compose.yml up -d

echo "⏳ Waiting for PostgreSQL to be ready..."
until sudo docker exec \
  "$(sudo docker ps -q -f name=postgres)" \
  pg_isready -U "$DB_USER" 2>/dev/null; do
  sleep 2
done
echo "✅ PostgreSQL is ready!"

echo "🚀 Starting Redis cluster..."
sudo -E docker compose -f redis/docker-compose.yml up -d

echo "⏳ Waiting for Redis to be ready..."
until sudo docker exec \
  "$(sudo docker ps -q -f name=cache)" \
  redis-cli ping 2>/dev/null | grep -q PONG; do
  sleep 2
done
echo "✅ Redis is ready!"

echo "🔨 Building containers..."
sudo -E docker compose build

echo "🚀 Starting containers..."
sudo -E docker compose up -d

echo "🚀 Stack is up. Following logs (Ctrl+C to shutdown)..."
echo "---------------------------------"
sudo -E docker compose logs -f --tail=20 web nginx
echo "🛑 Log stream ended, shutting down..."
