#!/usr/bin/env bash

set -a
set +H  # disable history expansion (! in passwords/keys)

DOT_ENV="docker/.env"

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
echo "REDIS_URL=$REDIS_URL"
echo "ALLOWED_HOSTS=$ALLOWED_HOSTS"
echo "NGINX_PORT=$NGINX_PORT"
echo "---------------------------------"
echo ""

read -p "🚀 Continue with docker compose? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit 0

echo "Closing all containers..."
docker stop $(docker ps -q)

cd docker

echo "🔗 Ensuring shared_net exists..."
sudo docker network inspect shared_net >/dev/null 2>&1 || \
  sudo docker network create shared_net

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

echo "✅ Done!"
