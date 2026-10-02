#!/usr/bin/env bash
# Applies migrations to a scratch database and runs tests/schema_test.sql.
# Usage: PGHOST=... PGUSER=... PGPASSWORD=... ./run_tests.sh   (needs CREATEDB rights)
set -euo pipefail
cd "$(dirname "$0")"
DB=digital_hoarding_test
psql -v ON_ERROR_STOP=1 -q -d postgres -c "DROP DATABASE IF EXISTS $DB" -c "CREATE DATABASE $DB"
for f in migrations/V*.sql; do echo "applying $f"; psql -v ON_ERROR_STOP=1 -q -d $DB -f "$f"; done
psql -v ON_ERROR_STOP=1 -d $DB -f tests/schema_test.sql
psql -q -d postgres -c "DROP DATABASE $DB"
echo "ALL SCHEMA TESTS PASSED"
