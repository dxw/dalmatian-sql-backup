#!/bin/bash

# exit on failures
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h                - help"
  echo "  -b <bucket_name>  - S3 Bucket name"
  echo "  This script makes an SQL dump of all databases within a given PostgreSQL"
  echo "  server, and uploads them to the specified S3 bucket"
  echo "  The PostgresSQL target and credentials must be specified as environment variables:"
  echo "  'DB_HOST', 'DB_USER' and 'DB_PASSWORD'"
  exit 1
}

while getopts "b:h" opt; do
  case $opt in
    b)
      BUCKET_NAME=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

if [[
  -z "$BUCKET_NAME"
  || -z "$DB_HOST"
  || -z "$DB_USER"
  || -z "$DB_PASSWORD"
]]
then
  usage
fi

echo "==> Starting backup of PostgreSQL Server $DB_HOST ..."
DATE_STRING="$(date +%Y%m%d%H%M)"
DUMP_DIR="/tmp/sqlbackups/$DB_HOST"
mkdir -p "$DUMP_DIR"

echo "==> Getting database names ..."
export PGPASSWORD="$DB_PASSWORD"
DATABASES="$(psql \
  -U "$DB_USER" \
  -h "$DB_HOST" \
  -t \
  -c 'SELECT datname FROM pg_database WHERE NOT datistemplate' \
  | grep -Ev 'rdsadmin'
)"

while IFS='' read -r DB_NAME
do
  DUMP_TARGET="$DUMP_DIR/$DATE_STRING-$DB_NAME.sql"
  echo "==> Dumping '$DB_NAME' database to $DUMP_TARGET ..."
  pg_dump \
    --clean \
    --if-exists "postgres://$DB_USERNAME:$DB_PASSWORD@$DB_HOST:5432/$DB_NAME > $DUMP_TARGET"
done < <(echo "$DATABASES")
echo "==> Completed database dumps"

echo "==> Uploading to S3 bucket $BUCKET_NAME ..."
cd /tmp/sqlbackups
aws s3 sync . "s3://$BUCKET_NAME" \
  --storage-class STANDARD_IA
echo "==> Uploads complete"

echo "==> Cleaning SQL files ..."
rm /tmp/sqlbackups/*.sql

echo "==> SQL Backup Success!"
