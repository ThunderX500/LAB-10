#!/usr/bin/env bash
set -euo pipefail

# Check the API, runtime config, and an Angular deep link.
api="${API_BASE:-http://localhost:8080}"
client="${CLIENT_BASE:-http://localhost:4100}"
expected_api="${EXPECTED_API_URL:-http://localhost:8080/books-api/}"

curl --fail --silent --show-error --retry 60 --retry-delay 2 --retry-all-errors "$api/actuator/health/readiness" | python3 -c 'import json,sys; assert json.load(sys.stdin)["status"] == "UP"'
curl --fail --silent --show-error "$api/books-api/authors" | python3 -c 'import json,sys; rows=json.load(sys.stdin)["_embedded"]["authors"]; assert len(rows)==3, rows; assert {a["lastName"] for a in rows}=={"Orwell","Austen","Murakami"}; print("PASS: three seeded authors")'
curl --fail --silent --show-error "$api/books-api/books" | python3 -c 'import json,sys; rows=json.load(sys.stdin)["_embedded"]["books"]; assert len(rows)==5, rows; print("PASS: five seeded books")'
curl --fail --silent --show-error --retry 30 --retry-delay 2 --retry-all-errors "$client/assets/env.json" | python3 -c 'import json,sys; assert json.load(sys.stdin)["apiUrl"]==sys.argv[1]; print("PASS: runtime API URL")' "$expected_api"
curl --fail --silent --show-error "$client/authors" | grep -q '<app-root'
# Ensure the browser is allowed to call the separate API origin.
headers="$(curl --fail --silent --show-error -D - -o /dev/null -H "Origin: $client" "$api/books-api/authors")"
printf '%s\n' "$headers" | grep -qi '^access-control-allow-origin:'
echo "PASS: Angular route and CORS"
