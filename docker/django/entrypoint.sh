#!/bin/sh
set -e

echo "Waiting for postgres connection..."

until PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d postgres \
  -c '\q'; do
  sleep 1
done

echo "PostgreSQL started"

# Create user if not exists
PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d postgres <<EOF

DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '$APP_DB_USER'
   ) THEN
      CREATE ROLE $APP_DB_USER LOGIN PASSWORD '$APP_DB_PASSWORD';
   END IF;
END
\$do\$;

EOF

# Create database if not exists (MUST be outside DO)
DB_EXISTS=$(PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d postgres \
  -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" != "1" ]; then
  echo "Creating database $DB_NAME..."
  PGPASSWORD=$DB_PASSWORD psql \
    -h "$DB_HOST" \
    -U "$DB_USER" \
    -d postgres \
    -c "CREATE DATABASE $DB_NAME OWNER $APP_DB_USER;"
else
  echo "Database $DB_NAME already exists"
fi

# Grant privileges (connect to target DB)
PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" <<EOF

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $APP_DB_USER;
GRANT ALL ON SCHEMA public TO $APP_DB_USER;
ALTER SCHEMA public OWNER TO $APP_DB_USER;

EOF

echo "Reassigning table ownership to $APP_DB_USER..."
PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" <<EOF

DO \$\$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tableowner <> '$APP_DB_USER'
  LOOP
    EXECUTE format('ALTER TABLE %I.%I OWNER TO $APP_DB_USER', 'public', r.tablename);
  END LOOP;
  FOR r IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'
  LOOP
    EXECUTE format('ALTER SEQUENCE %I.%I OWNER TO $APP_DB_USER', 'public', r.sequence_name);
  END LOOP;
  FOR r IN SELECT viewname FROM pg_views WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER VIEW %I.%I OWNER TO $APP_DB_USER', 'public', r.viewname);
  END LOOP;
END
\$\$;

EOF

echo "Database setup complete"

MIGRATIONS_TABLE=$(PGPASSWORD=$DB_PASSWORD psql \
  -h "$DB_HOST" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -tAc "SELECT count(*) FROM information_schema.tables WHERE table_name='django_migrations' AND table_schema='public'")

if [ "$MIGRATIONS_TABLE" -gt 0 ]; then
    echo "Running migrations..."
    python /app/manage.py migrate --noinput \
      || {
        echo "Migration failed. Faking remaining and retrying..."
        python /app/manage.py migrate --fake --noinput
      }
elif [ "$FORCE_FAKE_MIGRATIONS" = "true" ]; then
    echo "Force-fake mode: faking initial migrations for dump-restored DB..."
    python /app/manage.py migrate --fake-initial --noinput
    python /app/manage.py migrate --noinput \
      || python /app/manage.py migrate --fake --noinput
else
    echo "Fresh database. Running migrations..."
    python /app/manage.py migrate --noinput 2>&1 \
      || {
        echo "Migration failed. Dropping public schema and retrying..."
        PGPASSWORD=$DB_PASSWORD psql \
          -h "$DB_HOST" \
          -U "$DB_USER" \
          -d "$DB_NAME" \
          -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO $APP_DB_USER; ALTER SCHEMA public OWNER TO $APP_DB_USER;"
        python /app/manage.py migrate --noinput
      }
fi
python /app/manage.py collectstatic --noinput

HAS_DATA=$(python /app/manage.py shell -c "from django.contrib.auth import get_user_model; print(int(get_user_model().objects.exists()))" 2>&1) || HAS_DATA=""
# Descomente abaixo para forçar recarga de fixtures mesmo com banco cheio:
#HAS_DATA=0

if [ "$HAS_DATA" != "1" ]; then
  if ls /app/fixtures/*.json 2>/dev/null; then
    python /app/manage.py loaddata /app/fixtures/*.json
  fi
else
  echo "  Banco já possui dados — fixtures ignorados"
fi


echo "🔐 Applying group permissions..."
python /app/manage.py setup_permissions 2>&1 || true

echo "Creating default superuser if needed..."
python /app/manage.py shell <<EOF
from django.contrib.auth import get_user_model
from django.contrib.auth.models import Permission
import os

User = get_user_model()

username = os.environ.get("DJANGO_SUPERUSER_USERNAME")
email = os.environ.get("DJANGO_SUPERUSER_EMAIL")
password = os.environ.get("DJANGO_SUPERUSER_PASSWORD")

if not username:
    print("Username not provided")
    exit()

user, created = User.objects.get_or_create(username=username, defaults={"email": email})

if created:
    user.set_password(password)
    print("Superuser created")
else:
    print("User already exists, updating permissions...")

# Ensure full admin permissions
user.is_staff = True
user.is_superuser = True

all_permissions = Permission.objects.all()
user.user_permissions.set(all_permissions)

if password:
    user.set_password(password)

if email:
    user.email = email

user.save()

print("User is now a superuser with full permissions")
EOF

echo "🚀 Starting Gunicorn..."
exec "$@"
